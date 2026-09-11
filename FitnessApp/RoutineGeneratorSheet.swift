//
//  RoutineGeneratorSheet.swift
//  ChamaFit
//
//  «Crear rutina con IA»: objetivo, días, minutos, material y nivel → una
//  rutina con ejercicios del catálogo → vista previa → se crea como rutina
//  nueva (la actual queda guardada en Calendario › Rutinas).
//

import SwiftUI

struct RoutineGeneratorSheet: View {
    var engine: CoachEngine = .apple

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var coach = AICoachManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var req = RoutineRequest()
    @State private var prefilled = false
    @State private var result: GeneratedRoutine? = nil
    @State private var name = ""
    @State private var loading = false
    @State private var errorMsg: String? = nil

    private var p: Palette { themeManager.p }
    private let goals = ["Fuerza", "Hipertrofia", "Resistencia", "Perder grasa"]
    private let equipment = ["Gimnasio completo", "Mancuernas", "Peso corporal"]
    private let levels = ["Principiante", "Intermedio", "Avanzado"]
    private let minutes = [30, 45, 60, 75]

    /// Motor que se usa: el del coach si está disponible, si no el otro.
    private var useApple: Bool {
        if AppDefaults.has("--fake-ai") { return false }
        if engine == .apple && OnDeviceCoach.isAvailable { return true }
        return !coach.hasKey && OnDeviceCoach.isAvailable
    }
    private var canGenerate: Bool { AppDefaults.has("--fake-ai") || useApple || coach.hasKey }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: useApple ? "Apple Intelligence" : "Claude", p: p)
                    Text("Crear rutina con IA").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if let r = result { preview(r) } else { form }
                    if let e = errorMsg {
                        Text((e).loc).font(.fig(13, .medium)).foregroundColor(p.danger).padding(.top, 12)
                    }
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        } footer: {
            SheetFooter(p: p) {
                if let r = result {
                    SoftButton(title: "Otra", height: 50, p: p) { result = nil }
                        .frame(width: 100)
                    PrimaryButton(title: "Crear rutina", icon: "checkmark", height: 50, p: p) {
                        viewModel.applyGeneratedRoutine(r, named: name)
                        HapticManager.shared.success()
                        dismiss()
                    }
                    .accessibilityIdentifier("generator.apply")
                } else {
                    PrimaryButton(title: loading ? "Creando…" : "Generar rutina", icon: "wand.and.stars", height: 50,
                                  enabled: !loading && canGenerate, p: p) { generate() }
                        .accessibilityIdentifier("generator.go")
                }
            }
        }
    }

    // MARK: - Formulario

    private var form: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: 0).onAppear {
                guard !prefilled else { return }
                prefilled = true
                req = viewModel.routineRequestFromProfile()
            }
            if !canGenerate {
                Text("Para crear rutinas con IA necesitas Apple Intelligence activado o una API key de Claude en el Coach.")
                    .font(.fig(13, .medium)).foregroundColor(p.mute).padding(.bottom, 12)
            }
            label("Objetivo")
            chips(goals, selected: req.goal) { req.goal = $0 }
            label("Días por semana")
            chips([2, 3, 4, 5, 6].map(String.init), selected: String(req.daysPerWeek)) { req.daysPerWeek = Int($0) ?? 3 }
            label("Minutos por sesión")
            chips(minutes.map(String.init), selected: String(req.minutes)) { req.minutes = Int($0) ?? 60 }
            label("Material")
            chips(equipment, selected: req.equipment) { req.equipment = $0 }
            label("Nivel")
            chips(levels, selected: req.level) { req.level = $0 }
            if loading {
                HStack(spacing: 10) {
                    ProgressView().tint(p.acc)
                    Text("Montando tu rutina… puede tardar unos segundos.").font(.fig(13, .medium)).foregroundColor(p.mute)
                }
                .padding(.top, 18)
            }
        }
    }

    private func label(_ t: String) -> some View {
        UpperLabel(text: t, p: p).padding(.top, 16).padding(.bottom, 8)
    }

    private func chips(_ options: [String], selected: String, _ pick: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options, id: \.self) { o in
                    let on = o == selected
                    Button { pick(o); HapticManager.shared.selectionFeedback() } label: {
                        Text((o).loc).font(.fig(13, on ? .bold : .semibold))
                            .foregroundColor(on ? p.onacc : p.mute)
                            .padding(.horizontal, 14).frame(height: 36)
                            .background(Capsule().fill(on ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
                            .overlay(Capsule().strokeBorder(on ? .clear : p.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("generator.\(o)")
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Vista previa

    private func preview(_ r: GeneratedRoutine) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            UpperLabel(text: "Nombre de la rutina", p: p)
            PulsoField(placeholder: r.name, text: $name, p: p)
            Text((r.notes).loc).font(.fig(13, .medium)).lineSpacing(3).foregroundColor(p.mute)
            ForEach(Array(r.days.enumerated()), id: \.offset) { _, d in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text((d.day).loc).font(.fig(15, .bold)).foregroundColor(p.ink)
                        Text((d.label).loc).font(.fig(13, .semibold)).foregroundColor(p.acc)
                    }
                    ForEach(Array(d.exercises.enumerated()), id: \.offset) { _, e in
                        HStack {
                            Text((e.name).loc).font(.fig(13, .medium)).foregroundColor(p.ink)
                            Spacer()
                            Text("\(e.sets) × \(e.reps) · \(WorkoutViewModel.restText(e.restSeconds))")
                                .font(.fig(12, .semibold)).foregroundColor(p.mute)
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
            }
            Text("Se crea como rutina nueva; la de ahora queda guardada en Calendario › Rutinas.")
                .font(.fig(11, .medium)).foregroundColor(p.mute)
        }
        .accessibilityIdentifier("generator.preview")
    }

    // MARK: - Generar

    private func generate() {
        loading = true
        errorMsg = nil
        let r = req
        let apple = useApple
        Task {
            do {
                let g: GeneratedRoutine
                if AppDefaults.has("--fake-ai") {
                    g = Self.sample(for: r)   // pruebas: sin red ni modelo
                } else if apple {
                    g = try await OnDeviceCoach.generateRoutine(r)
                } else {
                    g = try await coach.generateRoutine(r)
                }
                name = String(localized: "\(r.goal) · \(r.daysPerWeek) días")
                result = g
            } catch {
                errorMsg = error.localizedDescription
            }
            loading = false
        }
    }

    /// Rutina fija para las pruebas de UI (--fake-ai).
    static func sample(for r: RoutineRequest) -> GeneratedRoutine {
        GeneratedRoutine(name: String(localized: "\(r.goal) \(r.daysPerWeek) días"), notes: "Rutina de prueba.",
                         days: [.init(day: "Martes", label: "Torso", exercises: [.init(name: "Press de banca", sets: 4, reps: 8, restSeconds: 120),
                                                                                  .init(name: "Remo con barra", sets: 4, reps: 10, restSeconds: 90)]),
                                .init(day: "Jueves", label: "Pierna", exercises: [.init(name: "Sentadilla", sets: 5, reps: 5, restSeconds: 180),
                                                                                   .init(name: "Plancha", sets: 3, reps: 45, restSeconds: 60)])])
    }
}
