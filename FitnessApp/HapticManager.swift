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
    
    // Generadores pre-inicializados para mejor rendimiento (lazy para evitar errores)
    private lazy var lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private lazy var mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private lazy var heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private lazy var rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private lazy var notificationGenerator = UINotificationFeedbackGenerator()
    private lazy var selectionGenerator = UISelectionFeedbackGenerator()
    
    // Control de debounce para evitar múltiples llamadas rápidas
    private var lastHapticTime: Date = Date.distantPast
    private let hapticDebounceInterval: TimeInterval = 0.1 // 100ms mínimo entre hápticos
    
    private init() {
        // Verificar disponibilidad de hápticos
        #if targetEnvironment(simulator)
        self.isHapticsAvailable = false
        print("🚫 Hápticos deshabilitados en simulador")
        #else
        self.isHapticsAvailable = true
        print("✅ Hápticos disponibles en dispositivo físico")
        #endif
    }
    
    // MARK: - Helper Methods
    
    private func canPerformHaptic() -> Bool {
        guard isHapticsAvailable else { return false }
        
        let now = Date()
        guard now.timeIntervalSince(lastHapticTime) >= hapticDebounceInterval else {
            return false
        }
        
        lastHapticTime = now
        return true
    }
    
    private func prepareAndExecute(generator: UIFeedbackGenerator, action: @escaping () -> Void) {
        guard canPerformHaptic() else { return }
        
        DispatchQueue.main.async {
            generator.prepare()
            action()
        }
    }
    
    // MARK: - Workout Actions
    
    /// Haptic feedback para completar una serie
    func setCompleted() {
        prepareAndExecute(generator: mediumImpactGenerator) {
            self.mediumImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para iniciar el temporizador
    func timerStarted() {
        prepareAndExecute(generator: lightImpactGenerator) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para detener el temporizador
    func timerStopped() {
        prepareAndExecute(generator: lightImpactGenerator) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para cuando el temporizador termina
    func timerCompleted() {
        guard canPerformHaptic() else { return }
        
        DispatchQueue.main.async {
            // Vibración intensa para llamar la atención
            self.rigidImpactGenerator.prepare()
            self.rigidImpactGenerator.impactOccurred()
            
            // Secuencia de vibraciones progresivamente más intensas (con control)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                guard self.isHapticsAvailable else { return }
                self.heavyImpactGenerator.prepare()
                self.heavyImpactGenerator.impactOccurred()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard self.isHapticsAvailable else { return }
                self.rigidImpactGenerator.prepare()
                self.rigidImpactGenerator.impactOccurred()
            }
            
            // Vibración final del sistema después de 500ms
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard self.isHapticsAvailable else { return }
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }
    
    /// Haptic feedback para pausar el temporizador
    func timerPaused() {
        prepareAndExecute(generator: mediumImpactGenerator) {
            self.mediumImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para reanudar el temporizador
    func timerResumed() {
        prepareAndExecute(generator: lightImpactGenerator) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    // MARK: - Exercise Management
    
    /// Haptic feedback para añadir un ejercicio
    func exerciseAdded() {
        prepareAndExecute(generator: notificationGenerator) {
            self.notificationGenerator.notificationOccurred(.success)
        }
    }
    
    /// Haptic feedback para eliminar un ejercicio
    func exerciseDeleted() {
        prepareAndExecute(generator: notificationGenerator) {
            self.notificationGenerator.notificationOccurred(.warning)
        }
    }
    
    /// Haptic feedback para editar un ejercicio
    func exerciseEdited() {
        prepareAndExecute(generator: mediumImpactGenerator) {
            self.mediumImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para duplicar un ejercicio
    func exerciseDuplicated() {
        prepareAndExecute(generator: lightImpactGenerator) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    // MARK: - Navigation & UI
    
    /// Haptic feedback para acciones generales (botones, navegación)
    func buttonTapped() {
        prepareAndExecute(generator: lightImpactGenerator) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para cambios de tab
    func tabChanged() {
        prepareAndExecute(generator: selectionGenerator) {
            self.selectionGenerator.selectionChanged()
        }
    }
    
    /// Haptic feedback para cambios de segmento
    func segmentChanged() {
        prepareAndExecute(generator: selectionGenerator) {
            self.selectionGenerator.selectionChanged()
        }
    }
    
    /// Haptic feedback para deslizar/swipe
    func swipeAction() {
        prepareAndExecute(generator: lightImpactGenerator) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para pull-to-refresh
    func refreshTriggered() {
        prepareAndExecute(generator: lightImpactGenerator) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    // MARK: - Focus Mode
    
    /// Haptic feedback para activar modo enfoque
    func focusModeActivated() {
        prepareAndExecute(generator: mediumImpactGenerator) {
            self.mediumImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para desactivar modo enfoque
    func focusModeDeactivated() {
        prepareAndExecute(generator: lightImpactGenerator) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    // MARK: - Progress & Achievement
    
    /// Haptic feedback para completar un workout
    func workoutCompleted() {
        guard canPerformHaptic() else { return }
        
        DispatchQueue.main.async {
            self.notificationGenerator.prepare()
            self.notificationGenerator.notificationOccurred(.success)
            
            // Vibración adicional para celebrar (con control)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard self.isHapticsAvailable else { return }
                self.heavyImpactGenerator.prepare()
                self.heavyImpactGenerator.impactOccurred()
            }
        }
    }
    
    /// Haptic feedback para alcanzar un objetivo
    func goalAchieved() {
        guard canPerformHaptic() else { return }
        
        DispatchQueue.main.async {
            self.notificationGenerator.prepare()
            self.notificationGenerator.notificationOccurred(.success)
            
            // Secuencia de vibraciones celebratorias (con control)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                guard self.isHapticsAvailable else { return }
                self.mediumImpactGenerator.prepare()
                self.mediumImpactGenerator.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard self.isHapticsAvailable else { return }
                self.heavyImpactGenerator.prepare()
                self.heavyImpactGenerator.impactOccurred()
            }
        }
    }
    
    /// Haptic feedback para streak/racha
    func streakMaintained() {
        prepareAndExecute(generator: lightImpactGenerator) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    // MARK: - Settings & Preferences
    
    /// Haptic feedback para cambiar tema
    func themeChanged() {
        prepareAndExecute(generator: mediumImpactGenerator) {
            self.mediumImpactGenerator.impactOccurred()
        }
    }
    
    /// Haptic feedback para toggle de configuración
    func settingToggled() {
        prepareAndExecute(generator: lightImpactGenerator) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    // MARK: - Notifications
    
    /// Haptic feedback para acciones de éxito
    func success() {
        prepareAndExecute(generator: notificationGenerator) {
            self.notificationGenerator.notificationOccurred(.success)
        }
    }
    
    /// Haptic feedback para errores
    func error() {
        prepareAndExecute(generator: notificationGenerator) {
            self.notificationGenerator.notificationOccurred(.error)
        }
    }
    
    /// Haptic feedback para advertencias
    func warning() {
        prepareAndExecute(generator: notificationGenerator) {
            self.notificationGenerator.notificationOccurred(.warning)
        }
    }
    
    /// Haptic feedback para selecciones
    func selectionFeedback() {
        prepareAndExecute(generator: selectionGenerator) {
            self.selectionGenerator.selectionChanged()
        }
    }
    
    // MARK: - Custom Sequences
    
    /// Haptic feedback personalizado para notificaciones importantes
    func importantNotification() {
        guard canPerformHaptic() else { return }
        
        DispatchQueue.main.async {
            self.heavyImpactGenerator.prepare()
            self.heavyImpactGenerator.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                guard self.isHapticsAvailable else { return }
                self.mediumImpactGenerator.prepare()
                self.mediumImpactGenerator.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                guard self.isHapticsAvailable else { return }
                self.mediumImpactGenerator.prepare()
                self.mediumImpactGenerator.impactOccurred()
            }
        }
    }
    
    /// Haptic feedback para confirmar acciones destructivas
    func destructiveAction() {
        prepareAndExecute(generator: rigidImpactGenerator) {
            self.rigidImpactGenerator.impactOccurred()
        }
    }
    
    // MARK: - Utility Methods
    
    /// Preparar generadores para reducir latencia
    func prepareGenerators() {
        guard isHapticsAvailable else { return }
        
        DispatchQueue.main.async {
            self.lightImpactGenerator.prepare()
            self.mediumImpactGenerator.prepare()
            self.heavyImpactGenerator.prepare()
            self.rigidImpactGenerator.prepare()
            self.notificationGenerator.prepare()
            self.selectionGenerator.prepare()
        }
    }
}
