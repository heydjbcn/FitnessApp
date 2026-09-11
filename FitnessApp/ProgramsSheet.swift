//
//  ProgramsSheet.swift
//  ChamaFit
//
//  Elegir un programa de varias semanas (plantillas sin IA) y la tarjeta
//  de Inicio que dice en qué semana vas.
//

import SwiftUI

struct ProgramsSheet: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var selected: ProgramTemplate? = nil
    @State private var confirmEnd = false

    private var p: Palette { themeManager.p }
    private var templates: [ProgramTemplate] {
        ProgramTemplates.recommended(for: viewModel.trainingProfile, equipment: viewModel.activeEquipment)
    }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                if selected != nil {
                    Button { withAnimation { selected = nil } } label: {
                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold)).foregroundColor(p.ink)
                            .frame(width: 36, height: 36).background(Circle().fill(p.soft))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Atrás")
                }
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Varias semanas, sin pensar", p: p)
                    Text(selected?.name ?? "Programas").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if let t = selected { detail(t) } else { list }
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        } footer: {
            if let t = selected {
                SheetFooter(p: p) {
                    PrimaryButton(title: "Empezar programa", icon: "play.fill", height: 50, p: p) {
                        viewModel.startProgram(t)
                        HapticManager.shared.success()
                        dismiss()
                    }
                    .accessibilityIdentifier("program.start")
                }
            }
        }
        .confirmationDialog("¿Terminar el programa?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("Terminar programa", role: .destructive) { viewModel.endProgram() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("La rutina se queda; sus ejercicios vuelven a las series y repeticiones de antes.")
        }
    }

    // MARK: - Lista

    @ViewBuilder private var list: some View {
        if let prog = viewModel.activeProgram, let w = viewModel.programWeek() {
            VStack(alignment: .leading, spacing: 8) {
                UpperLabel(text: "En curso", p: p)
                Text((prog.name).loc).font(.fig(16, .bold)).foregroundColor(p.ink)
                Text((w.finished ? "Terminado" : String(localized: "\(w.week.label) de \(prog.weeks.count)")).loc).font(.fig(13, .medium)).foregroundColor(p.mute)
                HStack(spacing: 8) {
                    SoftButton(title: "Volver a empezar", height: 38, fontSize: 13, p: p) { viewModel.restartProgram() }
                    SoftButton(title: "Terminar", height: 38, fontSize: 13, color: p.danger, p: p) { confirmEnd = true }
                        .accessibilityIdentifier("program.end")
                }
            }
            .padding(14)
            .pulsoCard(p, radius: 20)
        }
        Text("Ordenados según tu perfil y tu material (\(viewModel.activeEquipment.name)).")
            .font(.fig(13, .medium)).foregroundColor(p.mute)
        ForEach(templates) { t in
            Button { withAnimation { selected = t } } label: { card(t) }
                .buttonStyle(.plain)
                .accessibilityIdentifier("program.\(t.id)")
        }
    }

    private func card(_ t: ProgramTemplate) -> some View {
        let fits = t.fits(viewModel.activeEquipment)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text((t.name).loc).font(.fig(16, .bold)).foregroundColor(p.ink)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(p.mute)
            }
            Text((t.summary).loc).font(.fig(13, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
            Text("\(t.sessionsPerWeek) días · \(t.weeks.count) semanas · \(t.level.label) · \(t.mode.label)")
                .font(.fig(12, .semibold)).foregroundColor(p.acc)
            if !fits {
                let missing = t.needs.subtracting(viewModel.activeEquipment.items).map(\.label).sorted().joined(separator: ", ")
                Label("Necesita: \(missing)", systemImage: "exclamationmark.triangle.fill")
                    .font(.fig(12, .semibold)).foregroundColor(Pulso.warning(isDark: p.dark))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulsoCard(p, radius: 20)
    }

    // MARK: - Detalle

    private func detail(_ t: ProgramTemplate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text((t.summary).loc).font(.fig(14, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
            Label(t.mode.detail.loc, systemImage: t.mode.icon).font(.fig(13, .medium)).foregroundColor(p.ink)
            ForEach(Array(zip(t.slots, t.sessions).enumerated()), id: \.offset) { _, pair in
                let (slot, session) = pair
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text((session.label).loc).font(.fig(15, .bold)).foregroundColor(p.ink)
                        if t.mode == .fixedWeek {
                            Text((slot.displayName).loc).font(.fig(12, .semibold)).foregroundColor(p.acc)
                        }
                    }
                    ForEach(session.items, id: \.name) { item in
                        HStack {
                            Text((item.name).loc).font(.fig(13, item.main ? .semibold : .medium)).foregroundColor(p.ink)
                            Spacer()
                            Text((item.reps > 0 ? "\(item.sets) × \(item.reps)" : String(localized: "\(item.sets) × tiempo")).loc)
                                .font(.fig(12, .semibold)).foregroundColor(p.mute)
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
            }
            UpperLabel(text: "Semana a semana", p: p).padding(.top, 4)
            ForEach(Array(t.weeks.enumerated()), id: \.offset) { _, w in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: w.deload ? "leaf.fill" : "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(w.deload ? Pulso.ok(isDark: p.dark) : p.acc)
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 1) {
                        Text((w.label + (w.rpe.map { String(localized: " · RPE \($0)") } ?? "")).loc).font(.fig(13, .semibold)).foregroundColor(p.ink)
                        if !w.note.isEmpty { Text((w.note).loc).font(.fig(12, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true) }
                    }
                }
            }
            Text("Se crea como rutina nueva; la de ahora queda guardada en Calendario › Rutinas.")
                .font(.fig(11, .medium)).foregroundColor(p.mute).padding(.top, 4)
        }
        .accessibilityIdentifier("program.detail")
    }
}

/// En Inicio: en qué semana del programa vas.
struct ProgramBanner: View {
    let p: Palette
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showing = false

    var body: some View {
        if let prog = viewModel.activeProgram, let w = viewModel.programWeek() {
            Button { showing = true } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: w.finished ? "flag.checkered" : w.week.deload ? "leaf.fill" : "chart.line.uptrend.xyaxis")
                            .font(.system(size: 13, weight: .bold)).foregroundColor(p.acc)
                        UpperLabel(text: String(localized: "Programa · \(prog.name)"), p: p)
                        Spacer()
                        Text(w.finished ? "Terminado" : "\(w.index + 1)/\(prog.weeks.count)")
                            .font(.fig(12, .bold)).foregroundColor(p.ink)
                    }
                    Text((w.finished ? "¡Programa terminado! Repítelo con más peso o elige otro."
                                    : w.week.label + (w.week.rpe.map { String(localized: " · RPE \($0)") } ?? "") + (w.week.note.isEmpty ? "" : " — \(w.week.note)")).loc)
                        .font(.fig(13, .medium)).foregroundColor(p.mute)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 3) {
                        ForEach(0..<prog.weeks.count, id: \.self) { i in
                            Capsule().fill(w.finished || i <= w.index ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft))
                                .frame(height: 5)
                        }
                    }
                }
                .padding(14)
                .pulsoCard(p, radius: 20)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.program")
            .sheet(isPresented: $showing) {
                ProgramsSheet().environmentObject(viewModel).environmentObject(themeManager)
            }
        }
    }
}
