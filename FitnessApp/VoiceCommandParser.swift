//
//  VoiceCommandParser.swift
//  ChamaFit
//
//  Convierte lo que dices en el modo entreno en una orden: «80 kilos por 8»,
//  «ochenta y dos y medio por seis RPE nueve», «hecho», «siguiente»,
//  «deshacer», «descanso», «está ocupada». En español, inglés y catalán, con
//  cifras en número o en palabras.
//

import Foundation

nonisolated enum VoiceCommand: Equatable, Sendable {
    /// Una serie: peso (en la unidad dicha o la de la app), repeticiones y RPE; lo que no se diga, nil.
    case set(weight: Double?, unit: WeightUnit?, reps: Int?, rpe: Int?)
    case done, next, undo, rest, busy
    case unknown
}

nonisolated enum VoiceCommandParser {

    /// `language`: "es", "en" o "ca" (el del reconocedor). Sirve para palabras
    /// que son número en un idioma y otra cosa en otro («set» = 7 en catalán).
    static func parse(_ raw: String, language: String? = nil) -> VoiceCommand {
        let text = normalize(raw)
        guard !text.isEmpty else { return .unknown }
        let words = text.split(separator: " ").map(String.init)

        // Órdenes sin cifras.
        let has = { (keys: [String]) in keys.contains { k in k.contains(" ") ? text.contains(k) : words.contains(k) } }
        let numbers = extractNumbers(words, language: language)
        if numbers.isEmpty {
            if has(["ocupada", "ocupado", "busy", "taken", "ocupat"]) { return .busy }
            if has(["deshacer", "deshaz", "undo", "desfes", "desfer", "borra", "quita"]) { return .undo }
            if has(["siguiente", "next", "seguent", "salta", "saltar", "skip"]) { return .next }
            if has(["descanso", "descansar", "rest", "descans", "descansa"]) { return .rest }
            if has(["hecho", "hecha", "listo", "lista", "done", "fet", "feta", "fin", "ya", "vale", "ok", "apunta"]) { return .done }
            return .unknown
        }

        // Unidad dicha.
        var unit: WeightUnit? = nil
        if has(["kilos", "kilo", "kg", "kgs", "kilogramos", "quilos", "quilo", "kilograms", "quilograms"]) { unit = .kg }
        if has(["libras", "libra", "lb", "lbs", "pounds", "pound", "lliures", "lliura"]) { unit = .lb }

        var weight: Double? = nil
        var reps: Int? = nil
        var rpe: Int? = nil

        for n in numbers {
            let before = n.start > 0 ? words[n.start - 1] : ""
            let after = n.end < words.count ? words[n.end] : ""
            let after2 = n.end + 1 < words.count ? words[n.end + 1] : ""
            if ["rpe", "erre", "esfuerzo"].contains(before) || (before == "pe" && n.start >= 2 && words[n.start - 2] == "erre") {
                rpe = Int(n.value.rounded()); continue
            }
            if isUnitWord(after) || (after == "y" && isUnitWord(after2)) { weight = n.value; continue }
            if isRepsWord(after) { reps = Int(n.value.rounded()); continue }
            if ["por", "x", "times", "per", "de", "for"].contains(before) && weight != nil && reps == nil { reps = Int(n.value.rounded()); continue }
            if ["con", "with", "amb"].contains(before) && weight == nil { weight = n.value; continue }
            // Sin pistas: el primero es el peso si hay dos cifras, el segundo las repeticiones.
            if weight == nil && numbers.count >= 2 && reps == nil { weight = n.value; continue }
            if reps == nil { reps = Int(n.value.rounded()); continue }
            if rpe == nil { rpe = Int(n.value.rounded()) }
        }
        if let r = rpe, !(1...10).contains(r) { rpe = nil }
        if let r = reps, r <= 0 || r > 200 { reps = nil }
        if weight == nil && reps == nil && rpe == nil { return .unknown }
        return .set(weight: weight, unit: unit, reps: reps, rpe: rpe)
    }

    private static func isUnitWord(_ w: String) -> Bool {
        ["kilos", "kilo", "kg", "kgs", "kilogramos", "quilos", "quilo", "kilograms", "libras", "libra", "lb", "lbs",
         "pounds", "pound", "lliures", "lliura"].contains(w)
    }

    private static func isRepsWord(_ w: String) -> Bool {
        ["repeticiones", "repeticion", "reps", "rep", "repetitions", "repetition", "repeticions", "repeticio", "veces", "vegades"].contains(w)
    }

    // MARK: - Texto

    static func normalize(_ s: String) -> String {
        var t = s.lowercased().folding(options: [.diacriticInsensitive], locale: AppLanguage.locale)
        // "82,5" / "82.5" se quedan juntos; guiones del catalán ("vint-i-dos") a espacios.
        t = t.replacingOccurrences(of: "-", with: " ")
        t = t.replacingOccurrences(of: "×", with: " x ")
        t = t.replacingOccurrences(of: "(\\d)x(\\d)", with: "$1 x $2", options: .regularExpression)
        t = t.replacingOccurrences(of: "(\\d)(kg|lb|kgs|lbs)\\b", with: "$1 $2", options: .regularExpression)
        t = t.replacingOccurrences(of: "[^a-z0-9,\\. ]", with: " ", options: .regularExpression)
        // "r p e" / "erre pe e" → "rpe"
        t = t.replacingOccurrences(of: "\\br p e\\b|\\berre pe e\\b", with: "rpe", options: .regularExpression)
        t = t.replacingOccurrences(of: "(\\d)[,\\.](\\d)", with: "$1D$2", options: .regularExpression)
        t = t.replacingOccurrences(of: "[,\\.]", with: " ", options: .regularExpression)
        t = t.replacingOccurrences(of: "D", with: ".")
        return t.split(separator: " ").joined(separator: " ")
    }

    // MARK: - Cifras

    struct Found: Equatable { let value: Double; let start: Int; let end: Int }

    private static let units: [String: Int] = [
        // es
        "cero": 0, "uno": 1, "una": 1, "dos": 2, "tres": 3, "cuatro": 4, "cinco": 5, "seis": 6, "siete": 7, "ocho": 8,
        "nueve": 9, "diez": 10, "doce": 12, "trece": 13, "catorce": 14, "quince": 15, "dieciseis": 16,
        "diecisiete": 17, "dieciocho": 18, "diecinueve": 19, "veinte": 20, "veintiuno": 21, "veintiun": 21, "veintidos": 22,
        "veintitres": 23, "veinticuatro": 24, "veinticinco": 25, "veintiseis": 26, "veintisiete": 27, "veintiocho": 28,
        "veintinueve": 29,
        // en
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15, "sixteen": 16,
        "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20,
        // ca
        "quatre": 4, "cinc": 5, "sis": 6, "vuit": 8, "nou": 9, "deu": 10, "onze": 11, "dotze": 12,
        "tretze": 13, "catorze": 14, "quinze": 15, "setze": 16, "disset": 17, "divuit": 18, "dinou": 19, "vint": 20,
        "dues": 2,
    ]

    /// Solo son número en ese idioma (en otro significan otra cosa).
    private static let onlyIn: [String: (String, Int)] = ["set": ("ca", 7), "u": ("ca", 1), "once": ("es", 11), "un": ("es", 1)]

    private static func unit(_ w: String, _ language: String?) -> Int? {
        if let v = units[w] { return v }
        if let (lang, v) = onlyIn[w] {
            // Sin idioma: "once" y "un" valen (español por defecto); "set" y "u", no.
            if let language { return language == lang ? v : nil }
            return lang == "es" ? v : nil
        }
        return nil
    }

    private static let tens: [String: Int] = [
        "treinta": 30, "cuarenta": 40, "cincuenta": 50, "sesenta": 60, "setenta": 70, "ochenta": 80, "noventa": 90,
        "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
        "trenta": 30, "quaranta": 40, "cinquanta": 50, "seixanta": 60, "setanta": 70, "vuitanta": 80, "noranta": 90,
    ]

    private static let hundreds: [String: Int] = [
        "cien": 100, "ciento": 100, "doscientos": 200, "doscientas": 200, "trescientos": 300, "cuatrocientos": 400,
        "quinientos": 500, "hundred": 100, "cent": 100, "cents": 100,
    ]

    /// Palabras que se pueden saltar dentro de un número: "ochenta y dos", "vint i dos", "one hundred and five".
    private static let joiners: Set<String> = ["y", "i", "and"]

    /// Busca números (en cifra o en palabras) y dónde están.
    static func extractNumbers(_ words: [String], language: String? = nil) -> [Found] {
        var out: [Found] = []
        var i = 0
        while i < words.count {
            let w = words[i]
            if let v = Double(w) {
                var value = v, end = i + 1
                // "80 y medio" / "80 i mig" / "80 and a half"
                if let half = halfAfter(words, end) { value += 0.5; end = half }
                out.append(Found(value: value, start: i, end: end)); i = end; continue
            }
            if unit(w, language) != nil || tens[w] != nil || hundreds[w] != nil {
                var total = 0, current = 0, j = i, any = false
                while j < words.count {
                    let x = words[j]
                    if let h = hundreds[x] { current = (current == 0 ? 1 : current) * h; if x == "hundred" { current = max(current, 100) }; any = true; j += 1; continue }
                    if let t = tens[x] { current += t; any = true; j += 1; continue }
                    if let u = unit(x, language) {
                        current += u; any = true; j += 1; continue
                    }
                    if joiners.contains(x), j + 1 < words.count, unit(words[j + 1], language) != nil || tens[words[j + 1]] != nil {
                        j += 1; continue
                    }
                    break
                }
                total += current
                guard any else { i += 1; continue }
                var value = Double(total), end = j
                if let half = halfAfter(words, end) { value += 0.5; end = half }
                // "coma cinco" / "point five"
                if end + 1 < words.count, ["coma", "point", "punt"].contains(words[end]), let d = unit(words[end + 1], language), d < 10 {
                    value += Double(d) / 10; end += 2
                }
                out.append(Found(value: value, start: i, end: end)); i = end; continue
            }
            i += 1
        }
        return out
    }

    /// Si tras la posición viene "y medio", "i mig", "and a half", devuelve dónde acaba.
    private static func halfAfter(_ words: [String], _ k: Int) -> Int? {
        guard k < words.count else { return nil }
        if ["y", "i"].contains(words[k]), k + 1 < words.count, ["medio", "media", "mig", "mitja"].contains(words[k + 1]) { return k + 2 }
        if words[k] == "and", k + 2 < words.count, words[k + 1] == "a", words[k + 2] == "half" { return k + 3 }
        return nil
    }
}
