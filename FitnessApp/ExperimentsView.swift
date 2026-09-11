//
//  ExperimentsView.swift
//  ChamaFit
//
//  Crear un experimento, ver qué condición toca hoy y el resultado.
//

import SwiftUI

struct ExperimentsView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var creating = false
    @State private var draft = ExperimentsView.newDraft(.rest)
    @State private var confirmDelete: Experiment? = nil

    private var p: Palette { themeManager.p }

    static func newDraft(_ t: ExperimentTemplate, exercise: UUID? = nil) -> Experiment {
        switch t {
        case .rest:
            return Experiment(template: t, title: t.label, conditionA: "Descanso de 3 min", conditionB: "Tu descanso de siempre",
                              metric: .e1rm, exerciseId: exercise, alternation: .bySession, restA: 180, weeks: 6, start: Date())
        case .timeOfDay:
            return Experiment(template: t, title: t.label, conditionA: "Por la mañana", conditionB: "Por la tarde",
                              metric: .volume, exerciseId: nil, alternation: .byTime, weeks: 6, start: Date())
        case .supplement:
            return Experiment(template: t, title: "Creatina 4 semanas", conditionA: "Con creatina", conditionB: "Sin creatina",
                              metric: .e1rm, exerciseId: exercise, alternation: .blocks, weeks: 4, start: Date())
        case .custom:
            return Experiment(template: t, title: "Mi experimento", conditionA: "Condición A", conditionB: "Condición B",
                              metric: .volume, exerciseId: nil, alternation: .bySession, weeks: 6, start: Date())
        }
    }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Pruébalo en ti", p: p)
                    Text(creating ? "Nuevo experimento" : "Experimentos").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { if creating { creating = false } else { dismiss() } }
            }
            .padding(.horizontal, 22).padding(.top, 22)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if creating { form } else { list }
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        } footer: {
            SheetFooter(p: p) {
                if creating {
                    PrimaryButton(title: "Empezar experimento", icon: "flask.fill", height: 50,
                                  enabled: !(needsExercise && draft.exerciseId == nil), p: p) {
                        var e = draft
                        e.start = Date()
                        viewModel.startExperiment(e)
                        HapticManager.shared.success()
                        creating = false
                    }
                    .accessibilityIdentifier("experiment.start")
                } else {
                    PrimaryButton(title: "Nuevo experimento", icon: "plus", height: 50, p: p) {
                        draft = Self.newDraft(.rest, exercise: viewModel.mainRecord(viewModel.todaySession)?.exerciseId)
                        creating = true
                    }
                    .accessibilityIdentifier("experiment.new")
                }
            }
        }
        .confirmationDialog("¿Borrar el experimento?", isPresented: Binding(get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Borrar", role: .destructive) { if let e = confirmDelete { viewModel.deleteExperiment(e.id) } }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private var needsExercise: Bool { draft.metric == .e1rm || draft.template == .rest }

    // MARK: - Lista y resultado

    @ViewBuilder private var list: some View {
        let all = viewModel.experiments.reversed()
        if all.isEmpty {
            Text("Un experimento compara dos formas de entrenar en ti: por ejemplo, descansar 3 minutos o lo de siempre. ChamaFit alterna las condiciones y te dice si hay diferencia de verdad o es ruido.")
                .font(.fig(14, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
        }
        ForEach(Array(all)) { e in card(e) }
    }

    private func card(_ e: Experiment) -> some View {
        let r = viewModel.result(e)
        let exName = e.exerciseId.flatMap(viewModel.getExercise(by:))?.name
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: e.template.icon).foregroundColor(p.acc)
                Text((e.title).loc).font(.fig(16, .bold)).foregroundColor(p.ink)
                Spacer()
                Text(e.ended == nil ? "En marcha" : "Terminado").font(.fig(11, .bold)).foregroundColor(p.mute)
            }
            Text("\(e.metric.label)\(exName.map { " de \($0)" } ?? "") · \(e.alternation.label)")
                .font(.fig(12, .medium)).foregroundColor(p.mute)
            if e.ended == nil {
                let today = viewModel.condition(e, on: Date())
                Text((String(localized: "Hoy toca \(today): \(today == "A" ? e.conditionA : e.conditionB)")).loc)
                    .font(.fig(13, .semibold)).foregroundColor(p.acc)
                    .accessibilityIdentifier("experiment.today")
            }
            bars(e, r)
            Text((viewModel.verdict(e)).loc).font(.fig(13, .medium)).foregroundColor(p.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("experiment.verdict")
            HStack(spacing: 8) {
                if e.ended == nil {
                    SoftButton(title: "Terminar", height: 36, fontSize: 13, p: p) { viewModel.endExperiment(e.id) }
                        .accessibilityIdentifier("experiment.end")
                }
                SoftButton(title: "Borrar", height: 36, fontSize: 13, color: p.danger, p: p) { confirmDelete = e }
            }
        }
        .padding(14)
        .pulsoCard(p, radius: 20)
    }

    private func bars(_ e: Experiment, _ r: ExperimentResult) -> some View {
        let top = max(r.meanA, r.meanB, 1)
        return VStack(spacing: 6) {
            ForEach([("A", e.conditionA, r.meanA, r.a.count), ("B", e.conditionB, r.meanB, r.b.count)], id: \.0) { key, name, mean, n in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("\(key) · \(name)").font(.fig(12, .semibold)).foregroundColor(p.ink).lineLimit(1)
                        Spacer()
                        Text((n == 0 ? "sin datos" : String(localized: "\(format(mean, e.metric)) · \(n) ses.")).loc).font(.fig(12, .semibold)).foregroundColor(p.mute)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(p.soft)
                            Capsule().fill(key == "A" ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.mute.opacity(0.5)))
                                .frame(width: geo.size.width * CGFloat(mean / top))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }

    private func format(_ v: Double, _ m: ExperimentMetric) -> String {
        switch m {
        case .e1rm: return WorkoutViewModel.kg((v * 10).rounded() / 10)
        case .volume: return Units.tonnage(v)
        case .rpe: return AppLanguage.decimal(String(format: "RPE %.1f", v))
        }
    }

    // MARK: - Crear

    @ViewBuilder private var form: some View {
        ForEach(ExperimentTemplate.allCases) { t in
            OptionCard(icon: t.icon, title: t.label, detail: t.detail, selected: draft.template == t, p: p) {
                draft = Self.newDraft(t, exercise: draft.exerciseId ?? viewModel.mainRecord(viewModel.todaySession)?.exerciseId)
            }
            .accessibilityIdentifier("experiment.template.\(t.rawValue)")
        }
        UpperLabel(text: "Ejercicio que se mide", p: p).padding(.top, 8)
        Menu {
            if !needsExercise { Button("Toda la sesión") { draft.exerciseId = nil } }
            ForEach(viewModel.availableExercises.sorted { $0.name < $1.name }) { ex in
                Button(ex.name) { draft.exerciseId = ex.id }
            }
        } label: {
            HStack {
                Text((draft.exerciseId.flatMap(viewModel.getExercise(by:))?.name ?? (needsExercise ? "Elige un ejercicio" : "Toda la sesión")).loc)
                    .font(.fig(15, .semibold)).foregroundColor(p.ink)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").foregroundColor(p.mute)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
        }
        .accessibilityIdentifier("experiment.exercise")
        if draft.template == .custom {
            UpperLabel(text: "Condiciones", p: p).padding(.top, 8)
            PulsoField(placeholder: "Condición A", text: $draft.conditionA, p: p)
            PulsoField(placeholder: "Condición B", text: $draft.conditionB, p: p)
            UpperLabel(text: "Se alternan", p: p).padding(.top, 8)
            FlowLayout(spacing: 6) {
                ForEach(ExperimentAlternation.allCases) { a in
                    TagChip(text: a.label, selected: draft.alternation == a, p: p) { draft.alternation = a }
                }
            }
            UpperLabel(text: "Se mide", p: p).padding(.top, 8)
            FlowLayout(spacing: 6) {
                ForEach(ExperimentMetric.allCases) { m in
                    TagChip(text: m.label, selected: draft.metric == m, p: p) { draft.metric = m }
                }
            }
        }
        if draft.template == .rest {
            HStack {
                Text("Descanso de la condición A").font(.fig(14, .semibold)).foregroundColor(p.ink)
                Spacer()
                Stepper(WorkoutViewModel.restText(draft.restA ?? 180), value: Binding(get: { draft.restA ?? 180 }, set: { draft.restA = $0 }),
                        in: 60...420, step: 30)
                    .font(.fig(14, .semibold)).fixedSize()
            }
            .padding(.top, 8)
        }
        Text("Consejo: mantén todo lo demás igual (sueño, horario, técnica) para que la comparación sea justa.")
            .font(.fig(12, .medium)).foregroundColor(p.mute).padding(.top, 8)
    }
}

/// En Inicio, si hay un experimento en marcha.
struct ExperimentBanner: View {
    let p: Palette
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showing = false

    var body: some View {
        if let e = viewModel.activeExperiment {
            let c = viewModel.condition(e, on: Date())
            Button { showing = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "flask.fill").font(.system(size: 15, weight: .semibold)).foregroundColor(p.onacc)
                        .frame(width: 38, height: 38)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.grad))
                    VStack(alignment: .leading, spacing: 2) {
                        Text((e.title).loc).font(.fig(14, .bold)).foregroundColor(p.ink).lineLimit(1)
                        Text((String(localized: "Hoy toca \(c): \(c == "A" ? e.conditionA : e.conditionB)")).loc).font(.fig(12, .medium)).foregroundColor(p.mute)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(p.mute)
                }
                .padding(12)
                .pulsoCard(p, radius: 20)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.experiment")
            .sheet(isPresented: $showing) {
                ExperimentsView().environmentObject(viewModel).environmentObject(themeManager)
            }
        }
    }
}
