//
//  EquipmentProfile.swift
//  ChamaFit
//
//  Con qué material entrenas: «Gimnasio», «Casa», «Hotel»… Uno está activo
//  y decide qué alternativas, plantillas y rutinas con IA se proponen.
//

import Foundation
import Combine

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case barbell, dumbbell, machine, cable, bench, smith, pullupBar, kettlebell, band, bodyweight, cardio
    var id: String { rawValue }

    var label: String {
        switch self {
        case .barbell: return "Barra y discos"
        case .dumbbell: return "Mancuernas"
        case .machine: return "Máquinas"
        case .cable: return "Poleas"
        case .bench: return "Banco"
        case .smith: return "Multipower"
        case .pullupBar: return "Barra de dominadas"
        case .kettlebell: return "Kettlebell"
        case .band: return "Bandas elásticas"
        case .bodyweight: return "Peso corporal"
        case .cardio: return "Máquinas de cardio"
        }
    }

    var icon: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .machine: return "gearshape.2.fill"
        case .cable: return "cable.connector"
        case .bench: return "bed.double.fill"
        case .smith: return "square.split.1x2.fill"
        case .pullupBar: return "figure.climbing"
        case .kettlebell: return "scalemass.fill"
        case .band: return "lasso"
        case .bodyweight: return "figure.core.training"
        case .cardio: return "figure.run"
        }
    }
}

struct EquipmentProfile: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var items: Set<Equipment>
    /// Peso de la barra (kg) para la calculadora y el calentamiento.
    var barWeight: Double = 20

    init(id: UUID = UUID(), name: String, items: Set<Equipment>, barWeight: Double = 20) {
        self.id = id; self.name = name; self.items = items; self.barWeight = barWeight
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Material"
        let raw = try c.decodeIfPresent([String].self, forKey: .items) ?? []
        items = Set(raw.compactMap(Equipment.init(rawValue:)))
        barWeight = try c.decodeIfPresent(Double.self, forKey: .barWeight) ?? 20
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(items.map(\.rawValue).sorted(), forKey: .items)
        try c.encode(barWeight, forKey: .barWeight)
    }

    private enum CodingKeys: String, CodingKey { case id, name, items, barWeight }

    /// Ids fijos para los de serie: así el perfil de entreno los encuentra siempre.
    static let gymId = UUID(uuidString: "00000000-0000-0000-0000-00000000C0A1")!
    static let homeId = UUID(uuidString: "00000000-0000-0000-0000-00000000C0A2")!
    static let bodyweightId = UUID(uuidString: "00000000-0000-0000-0000-00000000C0A3")!

    static let presets: [EquipmentProfile] = [
        EquipmentProfile(id: gymId, name: "Gimnasio", items: Set(Equipment.allCases)),
        EquipmentProfile(id: homeId, name: "Casa", items: [.dumbbell, .bench, .band, .bodyweight, .pullupBar]),
        EquipmentProfile(id: bodyweightId, name: "Sin material", items: [.bodyweight]),
    ]

    /// Lo que entiende el generador de rutinas.
    var generatorLabel: String {
        if items.contains(.barbell) || items.contains(.machine) { return "Gimnasio completo" }
        if items.contains(.dumbbell) || items.contains(.kettlebell) { return "Mancuernas" }
        return "Peso corporal"
    }

    /// La barra en kg; con libras, la de 20 kg de serie pasa a ser la de 45 lb.
    var barWeightKg: Double { barWeight == 20 && Units.weight == .lb ? Units.toKg(45) : barWeight }

    var summary: String { items.sorted { $0.label < $1.label }.map(\.label).joined(separator: ", ") }
}

extension WorkoutViewModel {

    /// Los de serie más los que haya creado el usuario.
    var equipmentProfiles: [EquipmentProfile] {
        get {
            let custom = (userDefaults.data(forKey: "EquipmentProfiles"))
                .flatMap { try? JSONDecoder().decode([EquipmentProfile].self, from: $0) } ?? []
            let ids = Set(custom.map(\.id))
            return EquipmentProfile.presets.filter { !ids.contains($0.id) } + custom
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) { userDefaults.set(data, forKey: "EquipmentProfiles") }
            objectWillChange.send()
        }
    }

    var activeEquipment: EquipmentProfile {
        let id = trainingProfile.equipmentProfileId ?? EquipmentProfile.gymId
        return equipmentProfiles.first { $0.id == id } ?? EquipmentProfile.presets[0]
    }

    func setActiveEquipment(_ id: UUID) {
        var p = trainingProfile
        p.equipmentProfileId = id
        trainingProfile = p
    }

    func saveEquipmentProfile(_ profile: EquipmentProfile) {
        var all = equipmentProfiles
        if let i = all.firstIndex(where: { $0.id == profile.id }) { all[i] = profile } else { all.append(profile) }
        equipmentProfiles = all
    }

    var equipmentLabelForGenerator: String { activeEquipment.generatorLabel }
}
