//
//  Units.swift
//  ChamaFit
//
//  Kilos o libras. Por dentro todo se guarda en kg (historial, copias,
//  Salud); las libras solo existen al enseñar y al escribir un peso. Así
//  cambiar de unidad no toca ni un dato y no hay deriva por redondeos.
//

import Foundation

nonisolated enum WeightUnit: String, CaseIterable, Identifiable, Sendable {
    case kg, lb
    var id: String { rawValue }
    var symbol: String { rawValue }
    var label: String { self == .kg ? "Kilos (kg)" : "Libras (lb)" }
}

enum Units {
    static let lbPerKg = 2.20462262185
    static let key = "weightUnit"

    /// Para pruebas: fija la unidad solo dentro de una tarea, sin tocar la guardada.
    @TaskLocal static var override: WeightUnit? = nil

    /// La elegida en Ajustes u onboarding; si no hay, kilos (quien ya usaba la
    /// app tiene todo en kg y no debe cambiarle nada al actualizar).
    static var weight: WeightUnit {
        get {
            if let override { return override }
            if let raw = AppDefaults.store.string(forKey: key), let u = WeightUnit(rawValue: raw) { return u }
            return .kg
        }
        set { AppDefaults.store.set(newValue.rawValue, forKey: key) }
    }

    /// Lo que se propone en el onboarding según la región (EE. UU. → libras).
    static var regionSuggestion: WeightUnit { Locale.current.measurementSystem == .us ? .lb : .kg }

    static var symbol: String { weight.symbol }

    /// kg → unidad de la pantalla.
    static func fromKg(_ kg: Double) -> Double { weight == .kg ? kg : kg * lbPerKg }
    /// Unidad de la pantalla → kg.
    static func toKg(_ value: Double) -> Double { weight == .kg ? value : value / lbPerKg }

    /// Paso de los botones +/−: 2,5 kg o 5 lb.
    static var step: Double { weight == .kg ? 2.5 : 5 }
    /// Paso fino: 1 kg o 2,5 lb.
    static var fineStep: Double { weight == .kg ? 1 : 2.5 }

    /// Sube o baja `steps` pasos sobre la rejilla de la unidad (si estaba
    /// fuera de ella, el primer paso la encaja): 132,3 lb + → 135 lb.
    static func stepped(_ kg: Double, by steps: Int, step: Double = step) -> Double {
        let v = fromKg(kg)
        let onGrid = abs((v / step).rounded() * step - v) < 0.01
        let base: Double
        if onGrid { base = (v / step).rounded() } else { base = steps > 0 ? (v / step).rounded(.down) : (v / step).rounded(.up) }
        return max(0, toKg((base + Double(steps)) * step))
    }

    /// Número en la unidad de la pantalla: 42,5 · 93,7 (las libras, a una décima).
    static func number(_ kg: Double) -> String { plain(weight == .kg ? kg : (fromKg(kg) * 10).rounded() / 10) }

    /// "42,5 kg" / "93,7 lb".
    static func format(_ kg: Double) -> String { "\(number(kg)) \(symbol)" }

    /// Número ya en la unidad de la pantalla (calculadora de discos): "45 lb".
    static func formatDisplay(_ value: Double) -> String { "\(plain(value)) \(symbol)" }

    /// Tonelaje: "850 kg", "12,3 t"; en libras "1.870 lb", "27,1k lb".
    static func tonnage(_ kg: Double) -> String {
        if weight == .kg {
            return kg >= 1000 ? AppLanguage.decimal(String(format: "%.1f t", kg / 1000))
                              : "\(Int(kg.rounded())) kg"
        }
        let lb = fromKg(kg)
        return lb >= 10000 ? AppLanguage.decimal(String(format: "%.1fk lb", lb / 1000))
                           : "\(Int(lb.rounded())) lb"
    }

    /// Lo que se escribe en un campo (en la unidad de la pantalla) → kg.
    static func parse(_ text: String) -> Double? {
        let t = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let v = Double(t), v >= 0 else { return nil }
        return toKg(v)
    }

    /// Discos de la calculadora y del calentamiento, en la unidad de la pantalla.
    static var plates: [Double] { weight == .kg ? PlateMath.plates : [45, 35, 25, 10, 5, 2.5] }
    /// Barras a elegir, en la unidad de la pantalla.
    static var bars: [Double] { weight == .kg ? [20, 15, 10] : [45, 35, 15] }
    /// La barra de siempre (20 kg / 45 lb), en kg.
    static var standardBarKg: Double { weight == .kg ? 20 : toKg(45) }

    /// 40 → "40", 42.5 → "42,5", 53.75 → "53,75".
    static func plain(_ value: Double) -> String {
        var text = String(format: "%.2f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return AppLanguage.decimal(text)
    }
}
