//
//  TextToPlanSheet.swift
//  ChamaFit
//
//  Pegar una rutina (de WhatsApp, de un entrenador, de una web) y
//  convertirla en una rutina de ChamaFit: vista previa y crear.
//

import SwiftUI
import UIKit

struct TextToPlanSheet: View {
    var engine: CoachEngine = .apple

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var coach = AICoachManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var result: GeneratedRoutine? = nil
    @State private var name = ""
    @State private var loading = false
    @State private var errorMsg: String? = nil

    private var p: Palette { themeManager.p }
    private var useApple: Bool {
        if AppDefaults.has("--fake-ai") { return false }
        return (engine == .apple && OnDeviceCoach.isAvailable) || (!coach.hasKey && OnDeviceCoach.isAvailable)
    }
    private var canRun: Bool { AppDefaults.has("--fake-ai") || useApple || coach.hasKey }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: useApple ? "Apple Intelligence" : "Claude", p: p)
                    Text("Texto → rutina").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if let r = result { preview(r) } else { input }
                    if let e = errorMsg { Text((e).loc).font(.fig(13, .medium)).foregroundColor(p.danger) }
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        } footer: {
            SheetFooter(p: p) {
                if let r = result {
                    SoftButton(title: "Otra vez", height: 50, p: p) { result = nil }.frame(width: 120)
                    PrimaryButton(title: "Crear rutina", icon: "checkmark", height: 50, p: p) {
                        viewModel.applyParsedRoutine(r, named: name)
                        HapticManager.shared.success()
                        dismiss()
                    }
                    .accessibilityIdentifier("paste.apply")
                } else {
                    PrimaryButton(title: loading ? "Leyendo…" : "Convertir", icon: "wand.and.stars", height: 50,
                                  enabled: !loading && canRun && text.trimmingCharacters(in: .whitespacesAndNewlines).count > 10, p: p) { convert() }
                        .accessibilityIdentifier("paste.go")
                }
            }
        }
    }

    private var input: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pega la rutina tal cual: «Lunes: press banca 4x8, remo 4x10…». La IA la ordena, reconoce los ejercicios de la biblioteca y crea los que falten.")
                .font(.fig(13, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
            if !canRun {
                Text("Necesitas Apple Intelligence o una API key de Claude en el Coach.").font(.fig(12, .medium)).foregroundColor(p.danger)
            }
            TextEditor(text: $text)
                .font(.fig(14, .medium)).foregroundColor(p.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 220)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
                .accessibilityIdentifier("paste.text")
            SoftButton(title: "Pegar del portapapeles", icon: "doc.on.clipboard", height: 40, fontSize: 13, p: p) {
                if let s = UIPasteboard.general.string { text = s }
            }
            if loading { ProgressView().tint(p.acc) }
        }
    }

    private func preview(_ r: GeneratedRoutine) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            UpperLabel(text: "Nombre de la rutina", p: p)
            PulsoField(placeholder: r.name, text: $name, p: p)
            Text((r.notes).loc).font(.fig(13, .medium)).foregroundColor(p.mute)
            ForEach(Array(r.days.enumerated()), id: \.offset) { _, d in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text((d.day).loc).font(.fig(15, .bold)).foregroundColor(p.ink)
                        Text((d.label).loc).font(.fig(13, .semibold)).foregroundColor(p.acc)
                    }
                    ForEach(Array(d.exercises.enumerated()), id: \.offset) { _, e in
                        HStack {
                            Text((e.name).loc).font(.fig(13, .medium)).foregroundColor(p.ink)
                            if ExerciseCatalog.entry(named: e.name) == nil && viewModel.findExercise(e.name) == nil {
                                Text("nuevo").font(.fig(10, .bold)).foregroundColor(p.onacc)
                                    .padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(p.acc))
                            }
                            Spacer()
                            Text("\(e.sets) × \(e.reps) · \(WorkoutViewModel.restText(e.restSeconds))").font(.fig(12, .semibold)).foregroundColor(p.mute)
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
            }
            Text("Se crea como rutina nueva; la de ahora queda guardada en Calendario › Rutinas.")
                .font(.fig(11, .medium)).foregroundColor(p.mute)
        }
        .accessibilityIdentifier("paste.preview")
    }

    private func convert() {
        loading = true
        errorMsg = nil
        let t = text
        let apple = useApple
        Task {
            do {
                let g: GeneratedRoutine
                if AppDefaults.has("--fake-ai") {
                    g = GeneratedRoutine(name: "Rutina pegada", notes: "Dos días de torso y pierna.", days: [
                        .init(day: "Lunes", label: "Torso", exercises: [.init(name: "Press de banca", sets: 4, reps: 8, restSeconds: 120),
                                                                         .init(name: "Remo Kroc", sets: 3, reps: 12, restSeconds: 90)]),
                        .init(day: "Jueves", label: "Pierna", exercises: [.init(name: "Sentadilla", sets: 5, reps: 5, restSeconds: 180)])])
                } else if apple {
                    g = try await OnDeviceCoach.parseRoutine(t)
                } else {
                    g = try await coach.parseRoutineText(t)
                }
                name = g.name
                result = g
            } catch {
                errorMsg = error.localizedDescription
            }
            loading = false
        }
    }
}
