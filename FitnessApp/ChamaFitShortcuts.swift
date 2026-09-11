//
//  ChamaFitShortcuts.swift
//  ChamaFit
//
//  Frases de Siri y atajos que aparecen solos en la app Atajos, en Spotlight
//  y en Ajustes › Botón de Acción › Atajo.
//

import AppIntents

struct ChamaFitShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: MarkSetIntent(), phrases: [
            "Marca una serie en \(.applicationName)",
            "Serie hecha en \(.applicationName)",
            "Marca serie en \(.applicationName)",
        ], shortTitle: "Marcar serie", systemImageName: "checkmark.circle.fill")

        AppShortcut(intent: LogSetIntent(), phrases: [
            "Apunta una serie en \(.applicationName)",
            "Apunta en \(.applicationName)",
        ], shortTitle: "Apuntar serie", systemImageName: "mic.fill")

        AppShortcut(intent: StartRestIntent(), phrases: [
            "Empieza el descanso en \(.applicationName)",
            "Descanso en \(.applicationName)",
        ], shortTitle: "Empezar descanso", systemImageName: "timer")

        AppShortcut(intent: TodayWorkoutIntent(), phrases: [
            "Qué me toca hoy en \(.applicationName)",
            "Qué entreno toca en \(.applicationName)",
        ], shortTitle: "¿Qué me toca hoy?", systemImageName: "calendar")

        AppShortcut(intent: StartWorkoutIntent(), phrases: [
            "Empieza el entreno en \(.applicationName)",
            "Modo entreno en \(.applicationName)",
        ], shortTitle: "Empezar entreno", systemImageName: "figure.strengthtraining.traditional")

        AppShortcut(intent: UndoSetIntent(), phrases: [
            "Deshaz la serie en \(.applicationName)",
        ], shortTitle: "Deshacer serie", systemImageName: "arrow.uturn.backward")

        AppShortcut(intent: LogBodyWeightIntent(), phrases: [
            "Apunta mi peso en \(.applicationName)",
        ], shortTitle: "Apuntar peso", systemImageName: "scalemass.fill")
    }
}
