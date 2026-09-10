//
//  LiveActivityManager.swift
//  ChamaFit
//
//  Arranca, alarga y cierra la Live Activity del descanso. La vista vive en
//  la extensión ChamaFitWidgets; aquí solo se mueve el estado.
//

import ActivityKit
import Foundation

/// Cómo se pinta la actividad: el degradado del acento del usuario.
struct ActivityStyle: Equatable {
    var accent1 = "#8B5CF6"
    var accent2 = "#22D3EE"
    var onAccentDark = true
}

@MainActor
final class LiveActivityManager {
    private var activity: Activity<RestActivityAttributes>?

    var isAvailable: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func start(endDate: Date, label: String, sessionName: String, style: ActivityStyle) {
        guard isAvailable else { return }
        end()
        let attributes = RestActivityAttributes(sessionName: sessionName, accent1: style.accent1,
                                                accent2: style.accent2, onAccentDark: style.onAccentDark)
        let state = RestActivityAttributes.ContentState(startDate: Date(), endDate: endDate, label: label)
        activity = try? Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: endDate.addingTimeInterval(90)),
            pushType: nil
        )
    }

    /// El descanso se ha alargado: nueva hora de fin, misma fecha de inicio.
    func update(endDate: Date, label: String? = nil) {
        guard let activity else { return }
        var state = activity.content.state
        state.endDate = endDate
        if let label { state.label = label }
        let content = ActivityContent(state: state, staleDate: endDate.addingTimeInterval(90))
        Task { await activity.update(content) }
    }

    /// El descanso ha terminado solo: se enseña "¡Ya!" un momento y se retira.
    func finish() {
        guard let activity else { return }
        var state = activity.content.state
        state.finished = true
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(10))
        Task { await activity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(8))) }
        self.activity = nil
    }

    /// Parado a mano: fuera al instante.
    func end() {
        guard let activity else { return }
        let state = activity.content.state
        Task { await activity.end(ActivityContent(state: state, staleDate: Date()), dismissalPolicy: .immediate) }
        self.activity = nil
    }

    /// Al arrancar la app, cierra actividades huérfanas de una ejecución anterior.
    func endAllOrphans() {
        for a in Activity<RestActivityAttributes>.activities {
            Task { await a.end(ActivityContent(state: a.content.state, staleDate: Date()), dismissalPolicy: .immediate) }
        }
    }
}
