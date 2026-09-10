//
//  HapticManager.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 18/7/25.
//

import SwiftUI
import AudioToolbox

class HapticManager {
    static let shared = HapticManager()

    /// Interruptor de Configuración ("Vibración"). Por defecto, encendida.
    private var enabled: Bool { AppDefaults.store.object(forKey: "hapticsEnabled") as? Bool ?? true }
    
    // Generadores pre-inicializados para mejor rendimiento
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Preparar los generadores para reducir latencia
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        rigidImpactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Workout Actions
    
    /// Haptic feedback para completar una serie
    func setCompleted() {
        guard enabled else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para iniciar el temporizador
    func timerStarted() {
        guard enabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para detener el temporizador
    func timerStopped() {
        guard enabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para cuando el temporizador termina
    func timerCompleted() {
        guard enabled else { return }
        // Vibración intensa para llamar la atención
        rigidImpactGenerator.impactOccurred()
        
        // Secuencia de vibraciones progresivamente más intensas
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.heavyImpactGenerator.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.rigidImpactGenerator.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.heavyImpactGenerator.impactOccurred()
        }
        
        // Vibración final más larga usando AudioToolbox para más intensidad
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    /// Haptic feedback para pausar el temporizador
    func timerPaused() {
        guard enabled else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para reanudar el temporizador
    func timerResumed() {
        guard enabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Exercise Management
    
    /// Haptic feedback para añadir un ejercicio
    func exerciseAdded() {
        guard enabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Haptic feedback para eliminar un ejercicio
    func exerciseDeleted() {
        guard enabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Haptic feedback para editar un ejercicio
    func exerciseEdited() {
        guard enabled else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para duplicar un ejercicio
    func exerciseDuplicated() {
        guard enabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Navigation & UI
    
    /// Haptic feedback para acciones generales (botones, navegación)
    func buttonTapped() {
        guard enabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para cambios de tab
    func tabChanged() {
        guard enabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// Haptic feedback para cambios de segmento
    func segmentChanged() {
        guard enabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// Haptic feedback para deslizar/swipe
    func swipeAction() {
        guard enabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para pull-to-refresh
    func refreshTriggered() {
        guard enabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Focus Mode
    
    /// Haptic feedback para activar modo enfoque
    func focusModeActivated() {
        guard enabled else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para desactivar modo enfoque
    func focusModeDeactivated() {
        guard enabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Progress & Achievement
    
    /// Haptic feedback para completar un workout
    func workoutCompleted() {
        guard enabled else { return }
        notificationGenerator.notificationOccurred(.success)
        
        // Vibración adicional para celebrar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.heavyImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para alcanzar un objetivo
    func goalAchieved() {
        guard enabled else { return }
        notificationGenerator.notificationOccurred(.success)
        
        // Secuencia de vibraciones celebratorias
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mediumImpactGenerator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.heavyImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para streak/racha
    func streakMaintained() {
        guard enabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Settings & Preferences
    
    /// Haptic feedback para cambiar tema
    func themeChanged() {
        guard enabled else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para toggle de configuración
    func settingToggled() {
        guard enabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Notifications
    
    /// Haptic feedback para acciones de éxito
    func success() {
        guard enabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Haptic feedback para errores
    func error() {
        guard enabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Haptic feedback para advertencias
    func warning() {
        guard enabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Haptic feedback para selecciones
    func selectionFeedback() {
        guard enabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    // MARK: - Custom Sequences
    
    /// Haptic feedback personalizado para notificaciones importantes
    func importantNotification() {
        guard enabled else { return }
        heavyImpactGenerator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mediumImpactGenerator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.mediumImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para confirmar acciones destructivas
    func destructiveAction() {
        guard enabled else { return }
        rigidImpactGenerator.impactOccurred()
    }
    
    // MARK: - Utility Methods
    
    /// Preparar generadores para reducir latencia
    func prepareGenerators() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        rigidImpactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
}
