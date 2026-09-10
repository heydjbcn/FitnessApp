//
//  SpotifyManager.swift
//  ChamaFit
//
//  Mando a distancia de la app de Spotify (SDK oficial, App Remote): qué
//  suena, pausa, salto y portada. Necesita la app de Spotify instalada y,
//  para arrancar una canción concreta, cuenta Premium.
//
//  El Client ID se lee de Info.plist (SpotifyClientID); el Redirect URI es
//  chamafit-spotify://callback (esquema declarado en el mismo plist).
//

import Foundation
import SwiftUI
import Combine
import SpotifyiOS

@MainActor
final class SpotifyManager: NSObject, ObservableObject {
    static let shared = SpotifyManager()

    static let clientID: String = (Bundle.main.object(forInfoDictionaryKey: "SpotifyClientID") as? String) ?? ""
    static let redirectURL = URL(string: "chamafit-spotify://callback")!
    static var isConfigured: Bool { !clientID.isEmpty && !clientID.hasPrefix("PON_AQUI") }

    @Published private(set) var isConnected = false
    @Published private(set) var isConnecting = false
    @Published private(set) var isPlaying = false
    @Published private(set) var trackTitle = ""
    @Published private(set) var trackArtist = ""
    @Published private(set) var trackURI = ""
    @Published private(set) var artwork: UIImage? = nil
    @Published private(set) var lastError: String? = nil
    /// Cómo se enseña el reproductor en la app: píldora, pestaña al borde o nada.
    @Published var presentation: Presentation = .compact
    @Published var expanded = false

    enum Presentation: String { case compact, minimized, hidden }

    private lazy var configuration: SPTConfiguration = {
        let c = SPTConfiguration(clientID: Self.clientID, redirectURL: Self.redirectURL)
        // Sin playURI: conectamos con lo que ya esté sonando (o en pausa) en Spotify.
        c.playURI = ""
        return c
    }()

    private lazy var sessionManager: SPTSessionManager = {
        let m = SPTSessionManager(configuration: configuration, delegate: self)
        return m
    }()

    private lazy var appRemote: SPTAppRemote = {
        let r = SPTAppRemote(configuration: configuration, logLevel: .none)
        r.delegate = self
        return r
    }()

    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "SpotifyAccessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "SpotifyAccessToken") }
    }

    private override init() {
        super.init()
        if let raw = UserDefaults.standard.string(forKey: "SpotifyPresentation"), let p = Presentation(rawValue: raw) {
            presentation = p
        }
    }

    /// Hay una sesión guardada: el usuario conectó alguna vez.
    var hasSession: Bool { accessToken != nil }

    // MARK: - Conectar

    /// Abre Spotify para autorizar (la primera vez) y conecta el mando.
    func connect() {
        guard Self.isConfigured else {
            lastError = "Falta el Client ID de Spotify en la app."
            return
        }
        lastError = nil
        isConnecting = true
        if let token = accessToken {
            appRemote.connectionParameters.accessToken = token
            appRemote.connect()
        } else {
            sessionManager.initiateSession(with: [.appRemoteControl], options: .clientOnly, campaign: nil)
        }
    }

    /// Al volver la app al frente, reconecta si había sesión.
    func reconnectIfNeeded() {
        guard Self.isConfigured, hasSession, !isConnected, !isConnecting else { return }
        connect()
    }

    func disconnect(forget: Bool = false) {
        if appRemote.isConnected { appRemote.disconnect() }
        isConnected = false
        isConnecting = false
        if forget {
            accessToken = nil
            trackTitle = ""; trackArtist = ""; artwork = nil; isPlaying = false
        }
    }

    /// La vuelta de Spotify tras autorizar (chamafit-spotify://callback?…).
    func handle(url: URL) {
        let params = appRemote.authorizationParameters(from: url)
        if let token = params?[SPTAppRemoteAccessTokenKey] {
            accessToken = token
            appRemote.connectionParameters.accessToken = token
            appRemote.connect()
        } else if let desc = params?[SPTAppRemoteErrorDescriptionKey] {
            isConnecting = false
            lastError = desc
        }
        _ = sessionManager.application(UIApplication.shared, open: url, options: [:])
    }

    // MARK: - Controles

    func togglePlayPause() {
        guard let api = appRemote.playerAPI else { return }
        if isPlaying { api.pause(nil) } else { api.resume(nil) }
        HapticManager.shared.buttonTapped()
    }

    func next() { appRemote.playerAPI?.skip(toNext: nil); HapticManager.shared.selectionFeedback() }
    func previous() { appRemote.playerAPI?.skip(toPrevious: nil); HapticManager.shared.selectionFeedback() }

    func setPresentation(_ p: Presentation) {
        presentation = p
        UserDefaults.standard.set(p.rawValue, forKey: "SpotifyPresentation")
    }

    // MARK: - Estado del reproductor

    private func apply(_ state: SPTAppRemotePlayerState) {
        isPlaying = !state.isPaused
        trackTitle = state.track.name
        trackArtist = state.track.artist.name
        if state.track.uri != trackURI {
            trackURI = state.track.uri
            appRemote.imageAPI?.fetchImage(forItem: state.track, with: CGSize(width: 360, height: 360)) { [weak self] image, _ in
                Task { @MainActor in self?.artwork = image as? UIImage }
            }
        }
    }
}

// MARK: - Delegados del SDK

extension SpotifyManager: SPTSessionManagerDelegate {
    nonisolated func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        Task { @MainActor in
            self.accessToken = session.accessToken
            self.appRemote.connectionParameters.accessToken = session.accessToken
            self.appRemote.connect()
        }
    }

    nonisolated func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        Task { @MainActor in
            self.isConnecting = false
            self.lastError = error.localizedDescription
        }
    }

    nonisolated func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        Task { @MainActor in
            self.accessToken = session.accessToken
            self.appRemote.connectionParameters.accessToken = session.accessToken
        }
    }
}

extension SpotifyManager: SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    nonisolated func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        Task { @MainActor in
            self.isConnected = true
            self.isConnecting = false
            self.lastError = nil
            appRemote.playerAPI?.delegate = self
            appRemote.playerAPI?.subscribe(toPlayerState: nil)
            appRemote.playerAPI?.getPlayerState { [weak self] state, _ in
                if let s = state as? SPTAppRemotePlayerState { Task { @MainActor in self?.apply(s) } }
            }
        }
    }

    nonisolated func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        Task { @MainActor in
            self.isConnected = false
            self.isConnecting = false
            // Spotify cerrado o token caducado: aviso y la próxima conexión reautoriza.
            self.lastError = "No se pudo conectar con Spotify. Ábrelo, dale a reproducir y vuelve a intentarlo."
            self.accessToken = nil
        }
    }

    nonisolated func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        Task { @MainActor in
            self.isConnected = false
            self.isPlaying = false
        }
    }

    nonisolated func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        Task { @MainActor in self.apply(playerState) }
    }
}
