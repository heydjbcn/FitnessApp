//
//  PlateMath.swift
//  ChamaFit
//
//  Cuentas de discos y de calentamiento, sin interfaz: las usan la
//  calculadora, el detalle del ejercicio y el modo entreno.
//

import Foundation

enum PlateMath {
    /// Discos habituales de un gimnasio, del más pesado al más ligero.
    static let plates: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    /// Discos de cada lado para llegar a `target` con una barra de `bar` kg.
    static func perSide(target: Double, bar: Double, plates: [Double] = plates) -> [(plate: Double, count: Int)] {
        var remaining = (target - bar) / 2
        guard remaining > 0 else { return [] }
        var result: [(plate: Double, count: Int)] = []
        for plate in plates where plate > 0 {
            let c = Int((remaining + 0.0001) / plate)
            if c > 0 { result.append((plate, c)); remaining -= Double(c) * plate }
        }
        return result
    }

    /// Lo que falta (o sobra) para el total exacto con esos discos.
    static func residual(target: Double, bar: Double, plates: [Double] = plates) -> Double {
        target - (perSide(target: target, bar: bar, plates: plates).reduce(0) { $0 + $1.plate * Double($1.count) } * 2 + bar)
    }

    /// "20 + 5 + 2,5" por lado; "solo la barra" si no lleva discos. Todo en
    /// la misma unidad que `plates`.
    static func sideText(target: Double, bar: Double, plates: [Double] = plates) -> String {
        let side = perSide(target: target, bar: bar, plates: plates)
        guard !side.isEmpty else { return "solo la barra" }
        return side.flatMap { Array(repeating: Units.plain($0.plate), count: $0.count) }
            .joined(separator: " + ")
    }

    /// Discos por lado para un peso guardado en kg, en la unidad elegida.
    static func sideTextKg(target kg: Double, barKg: Double) -> String {
        sideText(target: Units.fromKg(kg), bar: (Units.fromKg(barKg) * 100).rounded() / 100, plates: Units.plates)
    }

    /// Redondea a lo que se puede montar: múltiplos de 2,5 (1,25 por lado).
    static func roundToLoadable(_ weight: Double, step: Double = 2.5) -> Double {
        (weight / step).rounded() * step
    }

    struct WarmupSet: Equatable {
        let weight: Double
        let reps: Int
    }

    /// Series de calentamiento para una serie de trabajo de `work` kg:
    /// barra × 10, 50 % × 5, 70 % × 3 y, en cargas altas, 85 % × 1. Nada por
    /// debajo de la barra ni repetido; con cargas ligeras, solo la barra.
    static func warmup(for work: Double, bar: Double = 20, step: Double = 2.5, heavy: Double = 60) -> [WarmupSet] {
        guard work > bar else { return [] }
        var sets = [WarmupSet(weight: bar, reps: 10)]
        var steps: [(Double, Int)] = [(0.5, 5), (0.7, 3)]
        if work >= heavy { steps.append((0.85, 1)) }
        for (pct, reps) in steps {
            let w = roundToLoadable(work * pct, step: step)
            guard w > (sets.last?.weight ?? 0), w < work else { continue }
            sets.append(WarmupSet(weight: w, reps: reps))
        }
        return sets
    }

    /// El calentamiento para un peso en kg, calculado en la unidad elegida
    /// (en libras, múltiplos de 5 lb) y devuelto en kg.
    static func warmupKg(for workKg: Double, barKg: Double) -> [WarmupSet] {
        guard Units.weight == .lb else { return warmup(for: workKg, bar: barKg) }
        let bar = (Units.fromKg(barKg)).rounded()
        return warmup(for: Units.fromKg(workKg), bar: bar, step: 5, heavy: 135)
            .map { WarmupSet(weight: Units.toKg($0.weight), reps: $0.reps) }
    }
}
