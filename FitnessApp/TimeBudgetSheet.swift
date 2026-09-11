//
//  TimeBudgetSheet.swift
//  ChamaFit
//
//  «Tengo hasta las 19:10»: elige la hora, mira qué se recorta y a qué hora
//  acabarías, y aplícalo solo a la sesión de hoy.
//

import SwiftUI

struct TimeBudgetSheet: View {
    let day: WorkoutDay

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var deadline = TimeBudgetSheet.defaultDeadline()

    private var p: Palette { themeManager.p }
    private var plan: TimePlan { viewModel.timePlan(for: day, until: deadline) }

    static func defaultDeadline(now: Date = Date()) -> Date {
        let cal = Calendar.current
        let in60 = now.addingTimeInterval(3600)
        let m = cal.component(.minute, from: in60)
        return cal.date(bySetting: .second, value: 0, of: in60.addingTimeInterval(TimeInterval(((5 - m % 5) % 5) * 60))) ?? in60
    }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Hora límite", p: p)
                    Text("¿Hasta qué hora puedes?").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    DatePicker("Salgo a las", selection: $deadline, in: Date()..., displayedComponents: .hourAndMinute)
                        .font(.fig(16, .semibold)).foregroundColor(p.ink)
                        .tint(p.acc)
                        .accessibilityIdentifier("deadline.picker")
                    HStack(spacing: 10) {
                        ForEach([30, 45, 60, 90], id: \.self) { m in
                            TagChip(text: String(localized: "\(m) min"), selected: false, p: p) { deadline = Date().addingTimeInterval(TimeInterval(m * 60)) }
                                .accessibilityIdentifier("deadline.\(m)")
                        }
                    }
                    summary
                    if !plan.cuts.isEmpty { cuts }
                    Text("Los tiempos salen de lo que tardas de verdad entre series. El ejercicio principal nunca se recorta.")
                        .font(.fig(12, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        } footer: {
            SheetFooter(p: p) {
                if viewModel.sessionDeadline != nil || (viewModel.dailyWorkoutRecords[day] ?? []).contains(where: { $0.targetSets != nil }) {
                    SoftButton(title: "Quitar recorte", height: 50, p: p) {
                        viewModel.clearSessionTargets(day)
                        dismiss()
                    }
                    .frame(width: 150)
                    .accessibilityIdentifier("deadline.clear")
                }
                PrimaryButton(title: plan.cuts.isEmpty ? "Poner la hora" : "Recortar y seguir", icon: "scissors", height: 50, p: p) {
                    viewModel.applyTimePlan(plan, day: day, deadline: deadline)
                    HapticManager.shared.success()
                    dismiss()
                }
                .accessibilityIdentifier("deadline.apply")
            }
        }
    }

    private var summary: some View {
        let need = Int((plan.neededSeconds / 60).rounded(.up))
        let have = Int(plan.availableSeconds / 60)
        let before = Int((viewModel.remainingSeconds(day) / 60).rounded(.up))
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Acabas a las").font(.fig(14, .medium)).foregroundColor(p.mute)
                Text((Self.time(plan.finishAt)).loc).font(.bri(30)).foregroundStyle(plan.fits ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.danger))
                    .accessibilityIdentifier("deadline.finish")
            }
            Text((plan.cuts.isEmpty
                 ? String(localized: "Te da tiempo: te quedan unos \(before) min y tienes \(have).")
                 : plan.fits ? String(localized: "Sin recortar necesitarías \(before) min; recortando, \(need) de \(have).")
                             : String(localized: "Ni recortando da: harían falta \(need) min y tienes \(have). Lo principal primero.")).loc)
                .font(.fig(13, .medium)).foregroundColor(p.ink).fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
    }

    private var cuts: some View {
        VStack(alignment: .leading, spacing: 8) {
            UpperLabel(text: "Qué se recorta hoy", p: p)
            ForEach(plan.cuts) { c in
                HStack {
                    Image(systemName: c.to == 0 ? "minus.circle.fill" : "scissors")
                        .foregroundColor(c.to == 0 ? p.danger : p.acc)
                    Text((c.name).loc).font(.fig(14, .semibold)).foregroundColor(p.ink)
                    Spacer()
                    Text((c.to == 0 ? "Fuera hoy" : String(localized: "\(c.from) → \(c.to) series")).loc).font(.fig(13, .semibold)).foregroundColor(p.mute)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("deadline.cuts")
    }

    static func time(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "H:mm"
        return f.string(from: d)
    }
}

/// «Está ocupada»: hacer otro ahora y volver luego, o cambiarla por una alternativa con tu material.
struct BusySheet: View {
    let exercise: Exercise
    let recordId: UUID
    let day: WorkoutDay
    /// Hacer otro ejercicio ahora (el ocupado vuelve después).
    let onLater: () -> Void
    /// Tras cambiarlo por una alternativa.
    let onSwapped: () -> Void

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    private var p: Palette { themeManager.p }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Está ocupada", p: p)
                    Text((exercise.name).loc).font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink).lineLimit(1)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    OptionCard(icon: "arrow.uturn.forward", title: "Hago otro y vuelvo luego",
                               detail: "Pasa al siguiente ejercicio; este vuelve cuando no quede otro.", selected: false, p: p) {
                        dismiss(); onLater()
                    }
                    .accessibilityIdentifier("busy.later")
                    let alts = viewModel.alternatives(for: exercise.name)
                    if !alts.isEmpty {
                        UpperLabel(text: String(localized: "O cámbiala hoy por · \(viewModel.activeEquipment.name)"), p: p).padding(.top, 8)
                        ForEach(alts) { c in
                            OptionCard(icon: c.icon, title: c.name, detail: c.muscleGroup, selected: false, p: p) {
                                viewModel.substitute(recordId: recordId, in: day, with: viewModel.exerciseFromCatalog(c), forever: false)
                                HapticManager.shared.success()
                                dismiss(); onSwapped()
                            }
                            .accessibilityIdentifier("busy.alt.\(c.name)")
                        }
                    } else {
                        Text("Este ejercicio no tiene alternativas en la biblioteca. Puedes hacer otro y volver luego.")
                            .font(.fig(13, .medium)).foregroundColor(p.mute)
                    }
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        }
        .presentationDetents([.medium, .large])
    }
}
