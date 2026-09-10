//
//  ImportRoutineSheet.swift
//  ChamaFit
//
//  Al abrir un .chamafit (AirDrop, WhatsApp, Archivos): qué trae la rutina
//  y «Añadir como rutina». La tuya queda guardada en Calendario › Rutinas.
//

import SwiftUI

struct ImportRoutineSheet: View {
    let routine: SharedRoutine
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    private var p: Palette { themeManager.p }
    private var orderedDays: [WorkoutDay] { WorkoutDay.allCases.sorted { $0.weekOrder < $1.weekOrder } }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: routine.author.map { "Rutina de \($0)" } ?? "Rutina compartida", p: p)
                    Text(routine.name).font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                    Text(routine.summary).font(.fig(13, .medium)).foregroundColor(p.mute)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(orderedDays) { day in
                        if let items = routine.days[day.rawValue], !items.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(day.displayName).font(.fig(15, .bold)).foregroundColor(p.ink)
                                    if let l = routine.labels[day.rawValue] { Text(l).font(.fig(13, .semibold)).foregroundColor(p.acc) }
                                }
                                ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                                    HStack {
                                        Text(it.name).font(.fig(13, .medium)).foregroundColor(p.ink)
                                        Spacer()
                                        Text(it.segundos > 0 ? "\(it.totalSets) × \(it.segundos) s" : "\(it.totalSets) × \(it.repetitions)")
                                            .font(.fig(12, .semibold)).foregroundColor(p.mute)
                                    }
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
                        }
                    }
                    Text("Se añade como rutina nueva y pasa a ser la activa. La tuya queda guardada en Calendario › Rutinas.")
                        .font(.fig(11, .medium)).foregroundColor(p.mute)
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        } footer: {
            SheetFooter(p: p) {
                PrimaryButton(title: "Añadir como rutina", icon: "square.and.arrow.down", height: 50, p: p) {
                    viewModel.importSharedRoutine(routine)
                    HapticManager.shared.success()
                    dismiss()
                }
                .accessibilityIdentifier("import.apply")
            }
        }
    }
}
