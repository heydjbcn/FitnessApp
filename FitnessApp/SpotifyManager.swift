import SwiftUI
import Combine
// import SpotifyiOS // Comentado temporalmente - para compilar sin SDK

@MainActor
class SpotifyManager: NSObject, ObservableObject {
    
    static let shared = SpotifyManager()

    private let spotifyClientID = "d78b6e9720b24722b938c494e0dda2fe"
    private let spotifyRedirectURL = URL(string: "fitnessapp-spotify://callback")!
    
    @Published var isConnected = false
    @Published var currentTrackName: String = "No Conectado"
    @Published var currentArtistName: String = "Toca en Ajustes para conectar"
    @Published var isPlaying = false

    // MOCK: Variables temporales sin dependencias de Spotify
    private var reconnectionTimer: Timer?
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 3

    override private init() {
        super.init()
        print("🎵 SpotifyManager: Inicializado en modo MOCK (sin SDK)")
    }

    func connect() {
        print("🎵 SpotifyManager: Simulando conexión...")
        // MOCK: Simular conexión exitosa
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isConnected = true
            self.currentTrackName = "Canción de Prueba"
            self.currentArtistName = "Artista de Prueba"
            self.isPlaying = false
            print("✅ SpotifyManager: Conexión simulada exitosa")
        }
    }

    func disconnect() {
        print("🎵 SpotifyManager: Desconectando...")
        // Cancelar timer de reconexión
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
        
        isConnected = false
        currentTrackName = "No Conectado"
        currentArtistName = "Toca en Ajustes para conectar"
        isPlaying = false
        print("✅ SpotifyManager: Desconectado")
    }

    func playPause() {
        print("🎵 SpotifyManager: Toggle play/pause")
        isPlaying.toggle()
    }

    func nextTrack() {
        print("🎵 SpotifyManager: Siguiente canción")
    }

    func previousTrack() {
        print("🎵 SpotifyManager: Canción anterior")
    }
    
    // MOCK: Función de manejo de URL
    func handleCallback(_ url: URL) -> Bool {
        print("🎵 SpotifyManager: Manejando callback: \(url)")
        return true
    }
    
    // Funciones adicionales para compatibilidad
    func togglePlayPause() {
        playPause()
    }
    
    func skipNext() {
        nextTrack()
    }
    
    func skipPrevious() {
        previousTrack()
    }
    
    func handleURL(_ url: URL) {
        _ = handleCallback(url)
    }
}
