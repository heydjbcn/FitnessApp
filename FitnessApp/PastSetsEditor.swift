//
//  PastSetsEditor.swift
//  ChamaFit
//
//  Corregir las series de un ejercicio en una fecha pasada: tipo, peso,
//  reps y RPE de cada una, borrar una o añadir la que se olvidó marcar.
//

import SwiftUI

struct PastSetsEditor: View {
    let ref: HistoryRef
    let exercise: Exercise

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    private var p: Palette { themeManager.p }
    private var record: WorkoutExercise? { viewModel.historyRecord(ref) }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: String(localized: "Series del \(WeeklyCalendarView.longDate(ref.date).lowercased())"), p: p)
                    Text((exercise.name).loc).font(.bri(20)).em(-0.02, size: 20).foregroundColor(p.ink).lineLimit(1)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    let logs = record?.setLogs ?? []
                    if logs.isEmpty {
                        Text("No quedan series de este ejercicio ese día.")
                            .font(.fig(13, .medium)).foregroundColor(p.mute).padding(.vertical, 8)
                    }
                    ForEach(Array(logs.enumerated()), id: \.element.id) { i, log in
                        HStack(spacing: 6) {
                            SetLogRow(index: i + 1, log: log, p: p) { viewModel.updatePastSet($0, ref) }
                            Button { viewModel.deletePastSet(log.id, ref) } label: {
                                Image(systemName: "trash").font(.system(size: 13, weight: .semibold)).foregroundColor(p.danger)
                                    .frame(width: 34, height: 34)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(String(localized: "Borrar la serie \(i + 1)"))
                            .accessibilityIdentifier("past.delete.\(i + 1)")
                        }
                    }
                    SoftButton(title: "Añadir serie", icon: "plus", height: 44, p: p) {
                        let last = logs.last
                        viewModel.addPastSet(ref, weight: last?.weight ?? exercise.weight,
                                             reps: last?.reps ?? max(exercise.repetitions, exercise.segundos))
                    }
                    .accessibilityIdentifier("past.add")
                    Text("Los récords, las gráficas y la exportación se actualizan solos.")
                        .font(.fig(11, .medium)).foregroundColor(p.mute).padding(.top, 4)
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        }
    }
}
