//
//  VoiceInput.swift
//  ChamaFit
//
//  Escucha una frase corta en el modo entreno y la devuelve en texto. Usa el
//  reconocimiento del propio iPhone cuando el idioma lo permite (sin
//  internet); si no (a veces el catalán), avisa de que irá por la red.
//  La música sigue sonando (se mezcla) y se para sola tras un silencio.
//

import Foundation
import AVFoundation
import Speech
import Combine

@MainActor
final class VoiceInput: ObservableObject {
    @Published private(set) var listening = false
    @Published private(set) var transcript = ""
    @Published var problem: String? = nil

    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var hardStop: Timer?
    private var onFinal: ((String) -> Void)?

    /// Idioma del reconocedor: el de la app (es, en o ca).
    static var language: String {
        let code = Locale.preferredLanguages.first.map { String($0.prefix(2)) } ?? "es"
        return ["es", "en", "ca"].contains(code) ? code : "es"
    }

    private static var localeId: String {
        switch language { case "en": return "en-US"; case "ca": return "ca-ES"; default: return "es-ES" }
    }

    /// Aviso previo: el catalán a veces no está en el iPhone y va por internet.
    static var onDeviceNote: String? {
        guard let r = SFSpeechRecognizer(locale: Locale(identifier: localeId)) else { return "Este idioma no tiene reconocimiento de voz." }
        return r.supportsOnDeviceRecognition ? nil : "Tu iPhone no reconoce este idioma sin conexión: la voz irá a Apple para entenderla."
    }

    func toggle(onFinal: @escaping (String) -> Void) {
        // Pruebas de UI: sin micrófono, la frase llega por argumento (--voice=80 kilos por 8).
        if AppDefaults.isTesting, let phrase = AppDefaults.value("--voice") {
            transcript = phrase
            onFinal(phrase)
            return
        }
        if listening { stop(deliver: true) } else { Task { await start(onFinal: onFinal) } }
    }

    func start(onFinal: @escaping (String) -> Void) async {
        guard !listening else { return }
        problem = nil
        transcript = ""
        self.onFinal = onFinal
        guard await Self.authorize() else {
            problem = "Sin permiso de micrófono o de reconocimiento de voz. Actívalo en Ajustes › ChamaFit."
            return
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: Self.localeId)), recognizer.isAvailable else {
            problem = "El reconocimiento de voz no está disponible ahora."
            return
        }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement,
                                    options: [.mixWithOthers, .defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            problem = "No se pudo usar el micrófono."
            return
        }
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }
        req.taskHint = .confirmation
        request = req

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format, block: Self.tapBlock(req))
        engine.prepare()
        do { try engine.start() } catch {
            problem = "No se pudo empezar a escuchar."
            cleanup()
            return
        }
        listening = true
        HapticManager.shared.buttonTapped()
        task = recognizer.recognitionTask(with: req, resultHandler: Self.resultHandler { [weak self] text, final, failed in
            guard let self else { return }
            if let text {
                self.transcript = text
                self.armSilence()
                if final { self.stop(deliver: true) }
            } else if failed, self.listening {
                self.stop(deliver: true)
            }
        })
        // Tope de 8 s por frase.
        hardStop = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.stop(deliver: true) }
        }
    }

    /// Tras 1,4 s sin cambios en lo reconocido, se da la frase por terminada.
    private func armSilence() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.4, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.stop(deliver: true) }
        }
    }

    func stop(deliver: Bool) {
        guard listening else { return }
        listening = false
        let text = transcript
        cleanup()
        if deliver, !text.trimmingCharacters(in: .whitespaces).isEmpty { onFinal?(text) }
        onFinal = nil
    }

    private func cleanup() {
        silenceTimer?.invalidate(); silenceTimer = nil
        hardStop?.invalidate(); hardStop = nil
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        // Devuelve el audio a reproducción (voz del coach y música).
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
    }

    // Los bloques de audio y del reconocedor llegan desde otros hilos: se crean
    // fuera del actor principal y solo tocan la interfaz saltando a él.
    nonisolated private static func tapBlock(_ req: SFSpeechAudioBufferRecognitionRequest) -> AVAudioNodeTapBlock {
        { buffer, _ in req.append(buffer) }
    }

    nonisolated private static func resultHandler(_ onMain: @escaping @MainActor (String?, Bool, Bool) -> Void)
        -> @Sendable (SFSpeechRecognitionResult?, Error?) -> Void {
        { result, error in
            let text = result?.bestTranscription.formattedString
            let final = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor in onMain(text, final, failed) }
        }
    }

    nonisolated private static func authorize() async -> Bool {
        let speech: Bool = await withCheckedContinuation { c in
            SFSpeechRecognizer.requestAuthorization { @Sendable status in c.resume(returning: status == .authorized) }
        }
        guard speech else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }
}
