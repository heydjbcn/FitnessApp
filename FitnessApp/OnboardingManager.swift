//
//  OnboardingManager.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 18/7/25.
//

import SwiftUI
import Combine

class OnboardingManager: ObservableObject {
    @Published var isFirstExercise = false
    @Published var showingOnboarding = false
    @Published var onboardingStep = 0
    
    // Callbacks para navegación
    var onNavigateToExercises: (() -> Void)?
    var onNavigateToCalendar: (() -> Void)?
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        // Verificar si es el primer ejercicio
        checkIfFirstExercise()
    }
    
    func checkIfFirstExercise() {
        let hasAddedExercise = userDefaults.bool(forKey: "HasAddedFirstExercise")
        isFirstExercise = !hasAddedExercise
    }
    
    func startOnboarding() {
        guard isFirstExercise else { return }
        showingOnboarding = true
        onboardingStep = 0
        HapticManager.shared.buttonTapped()
    }
    
    func nextStep() {
        onboardingStep += 1
        HapticManager.shared.buttonTapped()
        
        // Navegación automática según el paso
        if onboardingStep == 4 { // Mostrar calendario
            onNavigateToCalendar?()
        }
    }
    
    func previousStep() {
        onboardingStep -= 1
        HapticManager.shared.buttonTapped()
    }
    
    func completeOnboarding() {
        showingOnboarding = false
        onboardingStep = 0
        isFirstExercise = false
        userDefaults.set(true, forKey: "HasAddedFirstExercise")
        HapticManager.shared.buttonTapped()
    }
    
    func skipOnboarding() {
        completeOnboarding()
    }
    
    func resetOnboarding() {
        userDefaults.set(false, forKey: "HasAddedFirstExercise")
        isFirstExercise = true
        showingOnboarding = false
        onboardingStep = 0
    }
}

// MARK: - Onboarding Step Data
struct OnboardingStep {
    let title: String
    let description: String
    let systemImage: String
    let highlightArea: OnboardingHighlightArea?
}

enum OnboardingHighlightArea {
    case addExerciseForm
    case exerciseList
    case calendar
    case setButtons
}

// MARK: - Onboarding Data
extension OnboardingManager {
    static let onboardingSteps: [OnboardingStep] = [
        OnboardingStep(
            title: "¡Bienvenido!",
            description: "Te guiaremos en la creación de tu primer ejercicio paso a paso.",
            systemImage: "hand.wave.fill",
            highlightArea: nil
        ),
        OnboardingStep(
            title: "Crear Ejercicio",
            description: "Completa el formulario con los datos de tu ejercicio: nombre, repeticiones, peso y series.",
            systemImage: "plus.circle.fill",
            highlightArea: .addExerciseForm
        ),
        OnboardingStep(
            title: "Seleccionar Días",
            description: "Elige qué días de la semana quieres realizar este ejercicio.",
            systemImage: "calendar",
            highlightArea: .addExerciseForm
        ),
        OnboardingStep(
            title: "Ejercicio Creado",
            description: "¡Perfecto! Tu ejercicio aparecerá en la lista de ejercicios disponibles.",
            systemImage: "checkmark.circle.fill",
            highlightArea: .exerciseList
        ),
        OnboardingStep(
            title: "En el Calendario",
            description: "Ve a la pestaña Calendario para ver tu ejercicio programado en los días seleccionados.",
            systemImage: "calendar.badge.plus",
            highlightArea: .calendar
        ),
        OnboardingStep(
            title: "Marcar Series",
            description: "Cuando hagas el ejercicio, toca los círculos para marcar cada serie completada.",
            systemImage: "checkmark.circle",
            highlightArea: .setButtons
        ),
        OnboardingStep(
            title: "¡Listo!",
            description: "Ya sabes cómo crear y usar ejercicios. ¡Hora de entrenar!",
            systemImage: "star.fill",
            highlightArea: nil
        )
    ]
}
