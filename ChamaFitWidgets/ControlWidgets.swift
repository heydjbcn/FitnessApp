//
//  ControlWidgets.swift
//  ChamaFitWidgets
//
//  Controles para el Centro de control, la pantalla bloqueada y el Botón de
//  Acción: «Marcar serie» (botón) y «Descanso» (conmutador).
//

import AppIntents
import SwiftUI
import WidgetKit

struct MarkSetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "Mauri.FitnessApp.markSet") {
            ControlWidgetButton(action: MarkSetIntent()) {
                Label("Marcar serie", systemImage: "checkmark.circle.fill")
            }
        }
        .displayName("Marcar serie")
        .description("Marca la siguiente serie del entreno de hoy.")
    }
}

struct RestControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "Mauri.FitnessApp.rest", provider: RestValueProvider()) { active in
            ControlWidgetToggle("Descanso", isOn: active, action: ToggleRestIntent()) { on in
                Label(on ? "En marcha" : "Parado", systemImage: on ? "timer" : "timer.circle")
            }
        }
        .displayName("Descanso")
        .description("Arranca o para el descanso entre series.")
    }
}

struct RestValueProvider: ControlValueProvider {
    var previewValue: Bool { false }
    func currentValue() async throws -> Bool { SharedRestState.isActive }
}
