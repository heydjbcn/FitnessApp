//
//  VoiceCoach.swift
//  ChamaFit
//
//  Avisos por voz en los auriculares: los últimos segundos del descanso, el
//  "¡a por la siguiente!" con lo que toca y la cuenta de los ejercicios por
//  tiempo. La música baja mientras habla y vuelve después; no se corta.
//  Solo suena con la app delante (modo entreno o Inicio con la pantalla
//  encendida); con el móvil bloqueado avisa la notificación de siempre.
//

import AVFoundation

final class VoiceCoach: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = VoiceCoach()

    private let synth = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "es-ES")

    var enabled: Bool { AppDefaults.store.object(forKey: "voiceCues") as? Bool ?? true }

    private override init() {
        super.init()
        synth.delegate = self
    }

    func say(_ text: String, interrupt: Bool = false) {
        guard enabled, !AppDefaults.isTesting else { return }
        if interrupt, synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .voicePrompt,
                                 options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
        try? session.setActive(true)
        let u = AVSpeechUtterance(string: text)
        u.voice = voice
        u.rate = 0.52
        synth.speak(u)
    }

    /// Cada segundo del descanso: avisa a los 10 y cuenta 3, 2, 1.
    func restTick(_ remaining: Int) {
        switch remaining {
        case 10: say("Quedan diez segundos")
        case 3: say("tres", interrupt: true)
        case 2: say("dos", interrupt: true)
        case 1: say("uno", interrupt: true)
        default: break
        }
    }

    func restDone(next: String?) {
        say(next.map { "¡A por la siguiente! \($0)" } ?? "¡Descanso terminado!", interrupt: true)
    }

    // La música vuelve a su volumen al terminar de hablar.
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard !self.synth.isSpeaking else { return }
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
