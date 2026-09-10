//
//  AppDefaults.swift
//  ChamaFit
//
//  Dónde guarda la app sus datos. En uso normal, `UserDefaults.standard`.
//  Cuando la arranca una batería de pruebas (argumento `--ui-tests` o el
//  proceso de XCTest), un dominio aparte que se vacía al empezar: los datos
//  reales del usuario no se tocan ni se leen.
//

import Foundation

enum AppDefaults {
    nonisolated static let testSuite = "Mauri.FitnessApp.tests"

    /// True dentro de una pasada de pruebas (UI o unitarias hospedadas en la app).
    nonisolated static let isTesting: Bool = {
        let p = ProcessInfo.processInfo
        return p.arguments.contains("--ui-tests")
            || p.environment["XCTestConfigurationFilePath"] != nil
            || p.environment["XCTestBundlePath"] != nil
    }()

    nonisolated(unsafe) static let store: UserDefaults = {
        guard isTesting, let suite = UserDefaults(suiteName: testSuite) else { return .standard }
        // Cada test de UI arranca de cero (salvo `--keep`, para probar que lo
        // guardado sobrevive a un relanzamiento); los unitarios crean su propio dominio.
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--ui-tests"), !args.contains("--keep") {
            suite.removePersistentDomain(forName: testSuite)
        }
        return suite
    }()

    /// Argumentos de arranque que siembran estado para las pruebas de UI.
    nonisolated static func has(_ argument: String) -> Bool {
        ProcessInfo.processInfo.arguments.contains(argument)
    }

    /// Se llama antes de crear los managers: deja en el dominio de pruebas lo
    /// que piden los argumentos (`--light`, `--named`, `--accent=blue`…).
    static func applyLaunchArguments() {
        guard isTesting else { return }
        if has("--light") { store.set(false, forKey: "isDarkMode") }
        if has("--named") { store.set("Tester", forKey: "user_name") }
        if let accent = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--accent=") }) {
            store.set(String(accent.dropFirst("--accent=".count)), forKey: "selectedAccentColor")
        }
    }
}
