//
//  Exercise+Firebase.swift - ARREGLADO
//  FitnessApp
//
//  Extensión para compatibilidad con Firebase
//

import Foundation
import CoreData

// MARK: - Exercise Firebase Extensions
extension Exercise {
    
    /// Indica si el ejercicio viene de Firebase
    var isFirebaseExercise: Bool {
        return isFromFirebase
    }
    
    /// Obtener nombre para mostrar
    var displayName: String {
        return name.isEmpty ? "Ejercicio sin nombre" : name
    }
    
    /// Obtener descripción para mostrar
    var displayDescription: String {
        return info.isEmpty ? "Sin descripción" : info
    }
}

// MARK: - ExerciseEntity Firebase Extensions  
extension ExerciseEntity {
    
    /// Indica si el ejercicio fue creado localmente
    var isLocalExercise: Bool {
        return true // Placeholder - assume local for now
    }
    
    /// Obtener fecha de última actualización formateada
    var lastUpdatedString: String {
        guard let updatedAt = updatedAt else { return "Nunca" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
}
