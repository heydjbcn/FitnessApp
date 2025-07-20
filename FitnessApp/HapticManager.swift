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
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para iniciar el temporizador
    func timerStarted() {
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para detener el temporizador
    func timerStopped() {
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para cuando el temporizador termina
    func timerCompleted() {
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
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para reanudar el temporizador
    func timerResumed() {
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Exercise Management
    
    /// Haptic feedback para añadir un ejercicio
    func exerciseAdded() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Haptic feedback para eliminar un ejercicio
    func exerciseDeleted() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Haptic feedback para editar un ejercicio
    func exerciseEdited() {
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para duplicar un ejercicio
    func exerciseDuplicated() {
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Navigation & UI
    
    /// Haptic feedback para acciones generales (botones, navegación)
    func buttonTapped() {
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para cambios de tab
    func tabChanged() {
        selectionGenerator.selectionChanged()
    }
    
    /// Haptic feedback para cambios de segmento
    func segmentChanged() {
        selectionGenerator.selectionChanged()
    }
    
    /// Haptic feedback para deslizar/swipe
    func swipeAction() {
        lightImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para pull-to-refresh
    func refreshTriggered() {
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Focus Mode
    
    /// Haptic feedback para activar modo enfoque
    func focusModeActivated() {
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para desactivar modo enfoque
    func focusModeDeactivated() {
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Progress & Achievement
    
    /// Haptic feedback para completar un workout
    func workoutCompleted() {
        notificationGenerator.notificationOccurred(.success)
        
        // Vibración adicional para celebrar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.heavyImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para alcanzar un objetivo
    func goalAchieved() {
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
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Settings & Preferences
    
    /// Haptic feedback para cambiar tema
    func themeChanged() {
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Haptic feedback para toggle de configuración
    func settingToggled() {
        lightImpactGenerator.impactOccurred()
    }
    
    // MARK: - Notifications
    
    /// Haptic feedback para acciones de éxito
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Haptic feedback para errores
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Haptic feedback para advertencias
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Haptic feedback para selecciones
    func selectionFeedback() {
        selectionGenerator.selectionChanged()
    }
    
    // MARK: - Custom Sequences
    
    /// Haptic feedback personalizado para notificaciones importantes
    func importantNotification() {
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
