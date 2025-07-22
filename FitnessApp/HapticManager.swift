//
//  HapticManager_Fixed.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 22/7/25.
//

import SwiftUI
import AudioToolbox

class HapticManager {
    static let shared = HapticManager()
    
    // Verificar si los hápticos están disponibles
    private let isHapticsAvailable: Bool
    
    // Generadores pre-inicializados para mejor rendimiento
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Verificar disponibilidad de hápticos
        #if targetEnvironment(simulator)
        self.isHapticsAvailable = false
        print("🚫 Hápticos deshabilitados en simulador")
        #else
        self.isHapticsAvailable = true
        print("✅ Hápticos disponibles en dispositivo físico")
        #endif
        
        // Solo preparar los generadores si están disponibles
        if isHapticsAvailable {
            lightImpactGenerator.prepare()
            mediumImpactGenerator.prepare()
            heavyImpactGenerator.prepare()
            rigidImpactGenerator.prepare()
            notificationGenerator.prepare()
            selectionGenerator.prepare()
        }
    }
    
    // MARK: - Workout Actions
    
    /// Haptic feedback para completar una serie
    func setCompleted() {
        guard isHapticsAvailable else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para iniciar el temporizador
    func timerStarted() {
        guard isHapticsAvailable else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para detener el temporizador
    func timerStopped() {
        guard isHapticsAvailable else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para cuando el temporizador termina
    func timerCompleted() {
        guard isHapticsAvailable else { return }
        
        // Vibración intensa para llamar la atención
        rigidImpactGenerator.impactOccurred()
        
        // Secuencia de vibraciones progresivamente más intensas
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard self.isHapticsAvailable else { return }
            self.heavyImpactGenerator.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard self.isHapticsAvailable else { return }
            self.rigidImpactGenerator.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard self.isHapticsAvailable else { return }
            self.heavyImpactGenerator.impactOccurred()
        }
        
        // Vibración final después de 500ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard self.isHapticsAvailable else { return }
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    /// Haptic feedback para pausar el temporizador
    func timerPaused() {
        guard isHapticsAvailable else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para reanudar el temporizador
    func timerResumed() {
        guard isHapticsAvailable else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Exercise Management
    
    /// Haptic feedback para añadir un ejercicio
    func exerciseAdded() {
        guard isHapticsAvailable else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Haptic feedback para eliminar un ejercicio
    func exerciseDeleted() {
        guard isHapticsAvailable else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Haptic feedback para editar un ejercicio
    func exerciseEdited() {
        guard isHapticsAvailable else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para duplicar un ejercicio
    func exerciseDuplicated() {
        guard isHapticsAvailable else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Navigation & UI
    
    /// Haptic feedback para acciones generales (botones, navegación)
    func buttonTapped() {
        guard isHapticsAvailable else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para cambios de tab
    func tabChanged() {
        guard isHapticsAvailable else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// Haptic feedback para cambios de segmento
    func segmentChanged() {
        guard isHapticsAvailable else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// Haptic feedback para deslizar/swipe
    func swipeAction() {
        guard isHapticsAvailable else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para pull-to-refresh
    func refreshTriggered() {
        guard isHapticsAvailable else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Focus Mode
    
    /// Haptic feedback para activar modo enfoque
    func focusModeActivated() {
        guard isHapticsAvailable else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para desactivar modo enfoque
    func focusModeDeactivated() {
        guard isHapticsAvailable else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Progress & Achievement
    
    /// Haptic feedback para completar un workout
    func workoutCompleted() {
        guard isHapticsAvailable else { return }
        notificationGenerator.notificationOccurred(.success)
        
        // Vibración adicional para celebrar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            guard self.isHapticsAvailable else { return }
            self.heavyImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para alcanzar un objetivo
    func goalAchieved() {
        guard isHapticsAvailable else { return }
        notificationGenerator.notificationOccurred(.success)
        
        // Secuencia de vibraciones celebratorias
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard self.isHapticsAvailable else { return }
            self.mediumImpactGenerator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard self.isHapticsAvailable else { return }
            self.heavyImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para streak/racha
    func streakMaintained() {
        guard isHapticsAvailable else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Settings & Preferences
    
    /// Haptic feedback para cambiar tema
    func themeChanged() {
        guard isHapticsAvailable else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para toggle de configuración
    func settingToggled() {
        guard isHapticsAvailable else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Notifications
    
    /// Haptic feedback para acciones de éxito
    func success() {
        guard isHapticsAvailable else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Haptic feedback para errores
    func error() {
        guard isHapticsAvailable else { return }
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Haptic feedback para advertencias
    func warning() {
        guard isHapticsAvailable else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Haptic feedback para selecciones
    func selectionFeedback() {
        guard isHapticsAvailable else { return }
        selectionGenerator.selectionChanged()
    }
    
    // MARK: - Custom Sequences
    
    /// Haptic feedback personalizado para notificaciones importantes
    func importantNotification() {
        guard isHapticsAvailable else { return }
        heavyImpactGenerator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard self.isHapticsAvailable else { return }
            self.mediumImpactGenerator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard self.isHapticsAvailable else { return }
            self.mediumImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para confirmar acciones destructivas
    func destructiveAction() {
        guard isHapticsAvailable else { return }
        rigidImpactGenerator.impactOccurred()
    }
    
    // MARK: - Utility Methods
    
    /// Preparar generadores para reducir latencia
    func prepareGenerators() {
        guard isHapticsAvailable else { return }
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        rigidImpactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
}
