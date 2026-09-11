//
//  AppLanguage.swift
//  ChamaFit
//
//  El idioma en que se ve la app (español, inglés o catalán, según el iPhone
//  y las traducciones que lleva) y formatos que dependen de él: nombres de
//  los días, fechas y separador decimal.
//

import Foundation

nonisolated enum AppLanguage {
    /// "es", "en" o "ca".
    static var code: String {
        let c = Bundle.main.preferredLocalizations.first.map { String($0.prefix(2)) } ?? "es"
        return ["es", "en", "ca"].contains(c) ? c : "es"
    }

    static var isSpanish: Bool { code == "es" }

    static var locale: Locale {
        switch code {
        case "en": return Locale(identifier: "en_GB")
        case "ca": return Locale(identifier: "ca_ES")
        default: return AppLanguage.locale
        }
    }

    /// Cómo pedir a la IA que conteste en el idioma de la app.
    static var replyIn: String {
        switch code {
        case "en": return "inglés (English)"
        case "ca": return "catalán (català)"
        default: return "español de España"
        }
    }

    /// Voz para leer en alto (el coach durante el descanso).
    static var voiceLanguage: String {
        switch code { case "en": return "en-GB"; case "ca": return "ca-ES"; default: return "es-ES" }
    }

    /// "42.5" → "42,5" en español y catalán; igual en inglés.
    static func decimal(_ s: String) -> String {
        code == "en" ? s : s.replacingOccurrences(of: ".", with: ",")
    }

    /// Un texto traducido en tiempo de ejecución (la clave es el texto en español).
    static func t(_ spanish: String) -> String {
        isSpanish ? spanish : NSLocalizedString(spanish, comment: "")
    }
}

extension String {
    /// Traducción de un texto que llega en una variable (títulos de componentes,
    /// técnica, errores habituales…). Si no hay traducción, se queda igual.
    nonisolated var loc: String { AppLanguage.t(self) }
}
