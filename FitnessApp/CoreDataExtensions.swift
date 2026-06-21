//
//  CoreDataExtensions.swift - VERSIÓN SIN AMBIGÜEDAD DE APPLYING
//  FitnessApp
//

import CoreData
import Foundation

// MARK: - ExerciseEntity Extensions
extension ExerciseEntity {
    
    /// Convertir ExerciseEntity a Exercise (sin usar applying para evitar ambigüedad)
    func toExerciseModel() -> Exercise {
        // Crear Exercise con constructor completo para evitar applying
        var exercise = Exercise(
            name: self.name ?? "",
            targetMuscle: self.targetMuscle ?? "",
            repetitions: Int(self.defaultReps),
            totalSets: Int(self.defaultSets),
            weight: self.defaultWeight,
            restDuration: Int(self.restDuration),
            sfSymbolIcon: self.sfSymbolIcon,
            iconColor: self.iconColor ?? "blue",
            info: self.exerciseDescription ?? "",
            segundos: Int(self.segundos),
            rir: Int(self.rir),
            isFromFirebase: false
        )
        
        // Configurar propiedades adicionales directamente
        exercise.id = self.id ?? UUID()
        exercise.description = self.exerciseDescription ?? ""
        exercise.instructions = self.instructions ?? ""
        exercise.isBodyWeight = self.isBodyWeight
        exercise.category = ExerciseCategory(rawValue: self.category ?? "") ?? .strength
        exercise.personalRecordWeight = self.maxWeight > 0 ? self.maxWeight : nil
        exercise.personalRecordReps = self.maxReps > 0 ? Int(self.maxReps) : nil
        exercise.lastPerformed = self.recordDate
        exercise.imageData = nil
        
        return exercise
    }
    
    /// Actualizar desde Exercise
    func updateFromExercise(_ exercise: Exercise) {
        self.id = exercise.id
        self.name = exercise.name
        self.targetMuscle = exercise.targetMuscle
        self.category = exercise.category.rawValue
        self.defaultSets = Int32(exercise.totalSets)
        self.defaultReps = Int32(exercise.repetitions)
        self.defaultWeight = exercise.weight
        self.restDuration = Int32(exercise.restDuration)
        self.sfSymbolIcon = exercise.sfSymbolIcon
        self.iconColor = exercise.iconColor
        self.exerciseDescription = exercise.info
        self.instructions = exercise.instructions
        self.isBodyWeight = exercise.isBodyWeight
        self.segundos = Int32(exercise.segundos)
        self.rir = Int32(exercise.rir)
        self.maxWeight = exercise.personalRecordWeight ?? 0.0
        self.maxReps = Int32(exercise.personalRecordReps ?? 0)
        self.recordDate = exercise.lastPerformed
        self.updatedAt = Date()
        
        if self.createdAt == nil {
            self.createdAt = Date()
        }
    }
}

// MARK: - Exercise Extension for Core Data
extension Exercise {
    
    /// Obtener o crear ExerciseEntity en Core Data
    func getOrCreateExerciseEntity(in context: NSManagedObjectContext) -> ExerciseEntity {
        let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", self.id as CVarArg)
        
        if let existing = try? context.fetch(request).first {
            existing.updateFromExercise(self)
            return existing
        } else {
            let entity = ExerciseEntity(context: context)
            entity.updateFromExercise(self)
            return entity
        }
    }
}

// MARK: - WorkoutSession Extensions
extension WorkoutSession {
    
    /// Crear nueva sesión de entrenamiento
    static func createWorkoutSession(in context: NSManagedObjectContext, workoutDay: WorkoutDay) -> WorkoutSession {
        let session = WorkoutSession(context: context)
        session.id = UUID()
        session.date = Date()
        session.workoutDay = workoutDay.rawValue
        session.createdAt = Date()
        session.isCompleted = false
        return session
    }
    
    /// Completar sesión de entrenamiento
    func completeWorkout() {
        self.isCompleted = true
        self.completedAt = Date()
        if let createdAt = self.createdAt {
            self.duration = Int32(Date().timeIntervalSince(createdAt))
        }
    }
}

// MARK: - CompletedExercise Extensions
extension CompletedExercise {
    
    /// Crear ejercicio completado
    static func createCompletedExercise(in context: NSManagedObjectContext, from workoutExercise: WorkoutExercise, session: WorkoutSession) -> CompletedExercise {
        let completed = CompletedExercise(context: context)
        completed.id = UUID()
        completed.weight = workoutExercise.weight
        completed.reps = Int32(workoutExercise.repetitions)
        completed.setNumber = Int32(workoutExercise.completedSets)
        completed.completedAt = Date()
        completed.isCompleted = workoutExercise.isCompleted
        completed.workoutSession = session
        
        // Crear ExerciseEntity si no existe
        let exerciseEntity = workoutExercise.toExercise().getOrCreateExerciseEntity(in: context)
        completed.exercise = exerciseEntity
        
        return completed
    }
}

// MARK: - UserProfile Extensions
extension UserProfile {
    
    /// Obtener o crear perfil de usuario
    static func getOrCreateUserProfile(in context: NSManagedObjectContext) -> UserProfile {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.fetchLimit = 1
        
        if let existing = try? context.fetch(request).first {
            return existing
        } else {
            let profile = UserProfile(context: context)
            profile.id = UUID()
            profile.createdAt = Date()
            return profile
        }
    }
}
