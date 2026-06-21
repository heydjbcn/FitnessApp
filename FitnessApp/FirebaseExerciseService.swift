//
//  FirebaseExerciseService.swift - VERSIÓN STUB SIN DEPENDENCIAS FIREBASE
//  FitnessApp
//

import Foundation
import Combine

// STUB VERSION - Para permitir compilación sin Firebase
@MainActor
class FirebaseExerciseService: ObservableObject {
    static let shared = FirebaseExerciseService()
    
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {
        print("🔥 FirebaseExerciseService inicializado (STUB VERSION)")
    }
    
    // MARK: - Stub Methods
    
    func fetchExercises() async -> [Exercise] {
        print("🔥 STUB: fetchExercises llamado")
        
        isLoading = true
        
        // Simular delay de red
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
        
        // Retornar ejercicios de ejemplo para testing
        let stubExercises = createStubExercises()
        
        await MainActor.run {
            self.exercises = stubExercises
            self.isLoading = false
        }
        
        return stubExercises
    }
    
    func testFirebaseConnection() async -> (success: Bool, message: String) {
        print("🧪 STUB: testFirebaseConnection llamado")
        
        // Simular conexión exitosa
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
        
        return (true, "STUB: Conexión simulada exitosa")
    }
    
    func saveExercise(_ exercise: Exercise) async {
        print("💾 STUB: saveExercise llamado para: \(exercise.name)")
        
        // Simular guardado exitoso
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        print("✅ STUB: Ejercicio 'guardado' exitosamente: \(exercise.name)")
    }
    
    // MARK: - Stub Data
    
    private func createStubExercises() -> [Exercise] {
        return [
            Exercise(
                name: "Push-ups (STUB)",
                targetMuscle: "Chest",
                repetitions: 12,
                totalSets: 3,
                weight: 0,
                sfSymbolIcon: "figure.strengthtraining.traditional",
                info: "Ejercicio stub para testing sin Firebase",
                isFromFirebase: false
            ),
            Exercise(
                name: "Squats (STUB)",
                targetMuscle: "Legs", 
                repetitions: 15,
                totalSets: 3,
                weight: 0,
                sfSymbolIcon: "figure.squat",
                info: "Ejercicio stub para testing sin Firebase",
                isFromFirebase: false
            ),
            Exercise(
                name: "Pull-ups (STUB)",
                targetMuscle: "Back",
                repetitions: 8,
                totalSets: 3,
                weight: 0,
                sfSymbolIcon: "figure.climbing",
                info: "Ejercicio stub para testing sin Firebase",
                isFromFirebase: false
            )
        ]
    }
    
    // MARK: - Additional Stub Methods
    
    func addSampleExercises() async {
        print("🚀 STUB: addSampleExercises llamado")
        // No hacer nada en la versión stub
    }
    
    func clearExercises() async {
        print("🗑️ STUB: clearExercises llamado")
        await MainActor.run {
            self.exercises = []
        }
    }
}
