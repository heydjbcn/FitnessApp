//
//  Exercise.swift - VERSIÓN CORREGIDA CON CONSTRUCTOR FALTANTE
//  FitnessApp
//

import Foundation
import CoreData

enum ExerciseCategory: String, CaseIterable, Codable {
    case strength = "strength"
    case cardio = "cardio"
    case flexibility = "flexibility"
    case endurance = "endurance"
    
    var displayName: String {
        switch self {
        case .strength: return "Fuerza"
        case .cardio: return "Cardio"
        case .flexibility: return "Flexibilidad"
        case .endurance: return "Resistencia"
        }
    }
}

struct Exercise: Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var repetitions: Int
    var weight: Double
    var totalSets: Int
    var info: String
    var imageData: Data?
    var restDuration: Int
    var sfSymbolIcon: String?
    var iconColor: String
    var segundos: Int
    var rir: Int
    
    // ✅ PROPIEDADES MUTABLES para Firebase
    var targetMuscle: String = ""
    var description: String = ""
    var instructions: String = ""
    var isBodyWeight: Bool = false
    var category: ExerciseCategory = .strength
    var personalRecordWeight: Double?
    var personalRecordReps: Int?
    var lastPerformed: Date?
    var isFromFirebase: Bool = false
    
    init(
        id: UUID = UUID(),
        name: String,
        repetitions: Int = 8,
        weight: Double = 0.0,
        totalSets: Int = 3,
        info: String = "",
        imageData: Data? = nil,
        restDuration: Int = 120,
        sfSymbolIcon: String? = nil,
        iconColor: String = "blue",
        segundos: Int = 0,
        rir: Int = 0
    ) {
        self.id = id
        self.name = name
        self.repetitions = repetitions
        self.weight = weight
        self.totalSets = totalSets
        self.info = info
        self.imageData = imageData
        self.restDuration = restDuration
        self.sfSymbolIcon = sfSymbolIcon
        self.iconColor = iconColor
        self.segundos = segundos
        self.rir = rir
    }
    
    // MARK: - Firebase Constructor
    init(from firebaseData: [String: Any]) {
        self.id = UUID()
        self.name = firebaseData["name"] as? String ?? "Ejercicio sin nombre"
        self.repetitions = firebaseData["defaultReps"] as? Int ?? 8
        self.weight = firebaseData["defaultWeight"] as? Double ?? 0.0
        self.totalSets = firebaseData["defaultSets"] as? Int ?? 3
        self.info = firebaseData["description"] as? String ?? ""
        self.imageData = nil
        self.restDuration = firebaseData["restDuration"] as? Int ?? 120
        self.sfSymbolIcon = firebaseData["sfSymbolIcon"] as? String
        self.iconColor = firebaseData["iconColor"] as? String ?? "blue"
        self.segundos = firebaseData["segundos"] as? Int ?? 0
        self.rir = firebaseData["rir"] as? Int ?? 0
        
        // Propiedades adicionales de Firebase
        self.targetMuscle = firebaseData["targetMuscle"] as? String ?? ""
        self.description = firebaseData["description"] as? String ?? ""
        self.instructions = firebaseData["instructions"] as? String ?? ""
        self.isBodyWeight = firebaseData["isBodyWeight"] as? Bool ?? false
        
        if let categoryString = firebaseData["category"] as? String,
           let categoryEnum = ExerciseCategory(rawValue: categoryString) {
            self.category = categoryEnum
        } else {
            self.category = .strength
        }
    }
    
    // ✅ CONSTRUCTOR FALTANTE PARA CoreDataExtensions
    init(
        name: String,
        targetMuscle: String,
        repetitions: Int = 8,
        totalSets: Int = 3,
        weight: Double = 0.0,
        restDuration: Int = 120,
        sfSymbolIcon: String? = nil,
        iconColor: String = "blue",
        info: String = "",
        segundos: Int = 0,
        rir: Int = 0,
        isFromFirebase: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.repetitions = repetitions
        self.weight = weight
        self.totalSets = totalSets
        self.info = info
        self.imageData = nil
        self.restDuration = restDuration
        self.sfSymbolIcon = sfSymbolIcon
        self.iconColor = iconColor
        self.segundos = segundos
        self.rir = rir
        self.targetMuscle = targetMuscle
        self.description = info
        self.instructions = ""
        self.isBodyWeight = weight == 0.0
        self.category = .strength
        self.personalRecordWeight = nil
        self.personalRecordReps = nil
        self.lastPerformed = nil
        self.isFromFirebase = isFromFirebase
    }
}

// MARK: - Exercise Extensions

extension Exercise {
    var displayInfo: String {
        if info.isEmpty {
            return description.isEmpty ? "Sin información disponible" : description
        }
        return info
    }
    
    var displayInstructions: String {
        return instructions.isEmpty ? "No hay instrucciones específicas" : instructions
    }
    
    var formattedRestTime: String {
        let minutes = restDuration / 60
        let seconds = restDuration % 60
        
        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    var hasPersonalRecord: Bool {
        return personalRecordWeight != nil && personalRecordWeight! > 0
    }
    
    mutating func updatePersonalRecord(weight: Double, reps: Int) {
        if let currentPR = personalRecordWeight {
            if weight > currentPR {
                personalRecordWeight = weight
                personalRecordReps = reps
                lastPerformed = Date()
            }
        } else {
            personalRecordWeight = weight
            personalRecordReps = reps
            lastPerformed = Date()
        }
    }
}

// MARK: - Additional Extensions for functional modifications

extension Exercise {
    /// Aplicar modificaciones usando un closure
    func applying(_ modifier: (inout Exercise) -> Void) -> Exercise {
        var exercise = self
        modifier(&exercise)
        return exercise
    }
}
