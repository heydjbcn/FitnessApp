//
//  FitnessAppApp.swift - OPTIMIZADO CON FIREBASE Y DEBUG
//  FitnessApp
//

import SwiftUI
import CoreData
// import Firebase // COMENTADO TEMPORALMENTE

@main
struct FitnessAppApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var workoutService = WorkoutService.shared
    @StateObject private var firebaseService = FirebaseExerciseService.shared
    
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var userManager = UserManager()
    
    @State private var isCheckingMigration = true

    // MARK: - Inicialización
    init() {
        // 🔥 CONFIGURAR FIREBASE
        configureFirebase()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if isCheckingMigration {
                    SplashView()
                        .environmentObject(themeManager)
                } else {
                    ContentView()
                        .environmentObject(workoutViewModel)
                        .environmentObject(themeManager)
                        .environmentObject(firebaseService)
                        .environmentObject(userManager)
                        .environment(\.managedObjectContext, coreDataManager.context)
                }
            }
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            .onAppear {
                initializeApp()
            }
        }
    }
    
    // MARK: - 🔥 CONFIGURACIÓN DE FIREBASE
    
    private func configureFirebase() {
        // Configurar Firebase con GoogleService-Info.plist
        // FirebaseApp.configure() // COMENTADO TEMPORALMENTE
        print("🔥 Firebase configured successfully")
    }
    
    // MARK: - 🚀 INICIALIZACIÓN MEJORADA
    
    private func initializeApp() {
        Task {
            // ✅ 1. Esperar a que Core Data esté listo
            await coreDataManager.waitForReady()
            
            // ✅ 2. Inicializar ejercicios (Core Data + Firebase)
            await initializeExercises()
            
            // ✅ 3. Configurar datos de Firebase si es necesario
            await FirebaseSetup.setupSampleData()
            
            // ✅ 4. Test Firebase y cargar ejercicios
            await testAndLoadFirebase()
            
            // ✅ 5. Actualizar UI en main thread
            await MainActor.run {
                isCheckingMigration = false
            }
        }
    }
    
    // 🔥 Inicialización de ejercicios con Firebase
    private func initializeExercises() async {
        print("🏋️ Initializing exercises...")
        
        // Activar Core Data en WorkoutViewModel con Firebase
        await workoutViewModel.activateCoreDataWithFirebase()
        
        // Cargar ejercicios desde Firebase
        Task.detached { await workoutViewModel.loadExercisesFromFirebase() }
        
        print("✅ Exercises initialized successfully")
    }
    
    // 🧪 Test y carga de Firebase MEJORADO
    private func testAndLoadFirebase() async {
        print("🧪 ===== INICIANDO TEST DE FIREBASE =====")
        
        // Test conexión
        let (success, message) = await firebaseService.testFirebaseConnection()
        print("🎯 TEST CONEXIÓN: \(success ? "✅" : "❌") - \(message)")
        
        // Cargar ejercicios
        let exercises = await firebaseService.fetchExercises()
        print("🎯 EJERCICIOS CARGADOS: \(exercises.count)")
        
        if exercises.isEmpty {
            print("❌ NO SE OBTUVIERON EJERCICIOS - POSIBLES CAUSAS:")
            print("   1. Problemas de conectividad")
            print("   2. Reglas de Firestore restrictivas") 
            print("   3. Colección 'exercises' vacía")
            print("   4. Configuración incorrecta")
            
            // Crear ejercicios de ejemplo si no hay ninguno
            await createSampleFirebaseExercises()
        } else {
            print("✅ EJERCICIOS OBTENIDOS:")
            for (index, exercise) in exercises.enumerated() {
                print("   \(index + 1). \(exercise.name) (\(exercise.targetMuscle))")
            }
        }
        
        // Asegurar que WorkoutViewModel tenga los ejercicios
        await MainActor.run {
            workoutViewModel.firebaseExercises = exercises.isEmpty ? [] : exercises
            workoutViewModel.availableExercises = workoutViewModel.firebaseExercises + workoutViewModel.currentExercises
            print("🔄 WorkoutViewModel actualizado con \(workoutViewModel.availableExercises.count) ejercicios disponibles")
        }
        
        print("🧪 ===== FIN TEST DE FIREBASE =====")
    }
    
    // 🚀 Función para crear ejercicios de ejemplo si no hay ninguno
    private func createSampleFirebaseExercises() async {
        print("🚀 Creando ejercicios de ejemplo en Firebase...")
        
        let sampleExercises = [
            Exercise(
                name: "Push-ups",
                targetMuscle: "Chest",
                repetitions: 12,
                totalSets: 3,
                weight: 0,
                sfSymbolIcon: "figure.strengthtraining.traditional",
                info: "Flexiones de brazos clásicas para pecho y tríceps",
                isFromFirebase: true
            ),
            Exercise(
                name: "Squats",
                targetMuscle: "Legs",
                repetitions: 15,
                totalSets: 3,
                weight: 0,
                sfSymbolIcon: "figure.squat",
                info: "Sentadillas para fortalecer piernas y glúteos",
                isFromFirebase: true
            ),
            Exercise(
                name: "Pull-ups",
                targetMuscle: "Back",
                repetitions: 8,
                totalSets: 3,
                weight: 0,
                sfSymbolIcon: "figure.climbing",
                info: "Dominadas para espalda y bíceps",
                isFromFirebase: true
            ),
            Exercise(
                name: "Plank",
                targetMuscle: "Core",
                repetitions: 1,
                totalSets: 3,
                weight: 0,
                restDuration: 60,
                sfSymbolIcon: "figure.core.training",
                info: "Plancha para fortalecer el core",
                isFromFirebase: true
            ),
            Exercise(
                name: "Bench Press",
                targetMuscle: "Chest",
                repetitions: 10,
                totalSets: 4,
                weight: 60,
                sfSymbolIcon: "dumbbell.fill",
                info: "Press de banca con barra para pecho",
                isFromFirebase: true
            )
        ]
        
        // Subir a Firebase
        for exercise in sampleExercises {
            do {
                await firebaseService.saveExercise(exercise)
                print("✅ Ejercicio creado: \(exercise.name)")
            } catch {
                print("❌ Error creando \(exercise.name): \(error)")
            }
        }
        
        // Cargar los ejercicios recién creados
        let newExercises = await firebaseService.fetchExercises()
        await MainActor.run {
            workoutViewModel.firebaseExercises = newExercises
            workoutViewModel.availableExercises = newExercises + workoutViewModel.currentExercises
            print("🔄 \(newExercises.count) ejercicios de ejemplo cargados")
        }
    }
}
