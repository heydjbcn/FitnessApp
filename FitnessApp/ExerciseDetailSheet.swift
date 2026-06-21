//
//  ExerciseDetailSheet.swift
//  FitnessApp
//
//  Detalle del ejercicio: foto + información + series de HOY (peso/reps reales
//  editables por serie) + "última vez" + ajuste de la plantilla.
//

import SwiftUI

struct ExerciseDetailSheet: View {
    let exerciseId: UUID
    var workoutExerciseId: UUID? = nil
    var day: WorkoutDay? = nil

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var weightText: String = ""
    @State private var repsText: String = ""

    private var exercise: Exercise? { viewModel.getExercise(by: exerciseId) }
    private var isDark: Bool { themeManager.isDarkMode }

    private var todayRecord: WorkoutExercise? {
        guard let wid = workoutExerciseId, let d = day else { return nil }
        return viewModel.dailyWorkoutRecords[d]?.first(where: { $0.id == wid })
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if let ex = exercise {
                    VStack(alignment: .leading, spacing: 20) {
                        photo(ex)

                        Text(ex.name)
                            .font(AppFonts.title2)
                            .foregroundColor(AppColors.textPrimary(isDark: isDark))

                        // Última vez
                        if let last = viewModel.lastPerformance(for: exerciseId) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                                Text("Última vez: \(fmt(last.weight)) kg × \(last.reps) reps")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.textSecondary(isDark: isDark))
                            }
                        }

                        if !ex.info.isEmpty {
                            Text(ex.info)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textSecondary(isDark: isDark))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Series de hoy (si se abrió desde un día concreto)
                        if let rec = todayRecord {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SERIES DE HOY")
                                    .font(AppFonts.label).tracking(1.0)
                                    .foregroundColor(AppColors.textSecondary(isDark: isDark))

                                if rec.setLogs.isEmpty {
                                    Text("Aún no has registrado series hoy. Marca una serie en el calendario para empezar.")
                                        .font(AppFonts.caption)
                                        .foregroundColor(AppColors.textSecondary(isDark: isDark))
                                } else {
                                    ForEach(Array(rec.setLogs.enumerated()), id: \.element.id) { idx, log in
                                        SetLogRow(index: idx + 1, log: log, isDark: isDark, themeManager: themeManager) { updated in
                                            if let wid = workoutExerciseId, let d = day {
                                                viewModel.updateSetLog(updated, for: wid, in: d)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .cardStyle(isDarkMode: isDark)
                        }

                        // Datos del ejercicio
                        VStack(spacing: 10) {
                            if ex.repetitions > 0 { detailRow("repeat", "Repeticiones", "\(ex.repetitions)") }
                            if ex.segundos > 0 { detailRow("timer", "Duración", "\(ex.segundos)s") }
                            if ex.weight > 0 { detailRow("scalemass", "Peso", "\(fmt(ex.weight)) kg") }
                            detailRow("list.number", "Series", "\(ex.totalSets)")
                            if ex.rir > 0 { detailRow("gauge.medium", "RIR", "\(ex.rir)") }
                            detailRow("timer", "Descanso", "\(ex.restDuration / 60):\(String(format: "%02d", ex.restDuration % 60))")
                        }
                        .padding(16)
                        .cardStyle(isDarkMode: isDark)

                        // Ajustar valores por defecto (plantilla)
                        VStack(alignment: .leading, spacing: 14) {
                            Text("VALORES POR DEFECTO")
                                .font(AppFonts.label).tracking(1.0)
                                .foregroundColor(AppColors.textSecondary(isDark: isDark))
                            HStack(spacing: 12) {
                                editField(title: "Peso (kg)", text: $weightText, keyboard: .decimalPad)
                                editField(title: "Reps", text: $repsText, keyboard: .numberPad)
                            }
                            Button(action: { saveTemplate(ex) }) { Text("Guardar cambios") }
                                .buttonStyle(PrimaryButtonStyle(themeManager: themeManager))
                        }
                        .padding(16)
                        .cardStyle(isDarkMode: isDark)
                    }
                    .padding()
                } else {
                    Text("Ejercicio no disponible")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textSecondary(isDark: isDark))
                        .padding()
                }
            }
            .background(AppColors.background(isDark: isDark).ignoresSafeArea())
            .navigationTitle("Detalle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
            }
            .onAppear {
                if let ex = exercise {
                    weightText = ex.weight > 0 ? fmt(ex.weight) : ""
                    repsText = ex.repetitions > 0 ? "\(ex.repetitions)" : ""
                }
            }
        }
    }

    @ViewBuilder
    private func photo(_ ex: Exercise) -> some View {
        Group {
            if let data = ex.imageData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(height: 220).frame(maxWidth: .infinity).clipped()
            } else {
                ZStack {
                    AppColors.cardBackground(isDark: isDark)
                    Image(systemName: ex.sfSymbolIcon ?? "dumbbell.fill")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
                .frame(height: 180).frame(maxWidth: .infinity)
            }
        }
        .cornerRadius(18)
    }

    @ViewBuilder
    private func detailRow(_ icon: String, _ title: String, _ value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.primary(themeManager: themeManager))
                .frame(width: 24)
            Text(title).font(AppFonts.body).foregroundColor(AppColors.textSecondary(isDark: isDark))
            Spacer()
            Text(value).font(AppFonts.bodyMedium).foregroundColor(AppColors.textPrimary(isDark: isDark))
        }
    }

    @ViewBuilder
    private func editField(title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(AppFonts.caption).foregroundColor(AppColors.textSecondary(isDark: isDark))
            TextField("0", text: text)
                .keyboardType(keyboard)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary(isDark: isDark))
                .padding(.horizontal, 12).frame(height: 44)
                .background(AppColors.surface(isDark: isDark)).cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
    }

    private func fmt(_ v: Double) -> String { String(format: "%g", v) }

    private func saveTemplate(_ ex: Exercise) {
        var updated = ex
        if let w = Double(weightText.replacingOccurrences(of: ",", with: ".")) { updated.weight = w }
        if let r = Int(repsText) { updated.repetitions = r }
        viewModel.updateBaseExercise(updated)
        HapticManager.shared.success()
        dismiss()
    }
}

/// Fila editable de una serie registrada (peso/reps reales).
private struct SetLogRow: View {
    let index: Int
    let log: SetLog
    let isDark: Bool
    let themeManager: ThemeManager
    let onUpdate: (SetLog) -> Void

    @State private var weight: String = ""
    @State private var reps: String = ""

    var body: some View {
        HStack(spacing: 10) {
            Text("\(index)")
                .font(AppFonts.label)
                .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                .frame(width: 26, height: 26)
                .background(Circle().fill(AppColors.primary(themeManager: themeManager)))

            field(text: $weight, suffix: "kg", keyboard: .decimalPad)
            Text("×").foregroundColor(AppColors.textSecondary(isDark: isDark))
            field(text: $reps, suffix: "reps", keyboard: .numberPad)

            Spacer()
        }
        .onAppear {
            weight = String(format: "%g", log.weight)
            reps = "\(log.reps)"
        }
    }

    @ViewBuilder
    private func field(text: Binding<String>, suffix: String, keyboard: UIKeyboardType) -> some View {
        HStack(spacing: 4) {
            TextField("0", text: text)
                .keyboardType(keyboard)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary(isDark: isDark))
                .frame(width: 48)
                .multilineTextAlignment(.trailing)
                .onChange(of: text.wrappedValue) { _, _ in commit() }
            Text(suffix).font(AppFonts.caption).foregroundColor(AppColors.textSecondary(isDark: isDark))
        }
        .padding(.horizontal, 10).frame(height: 40)
        .background(AppColors.surface(isDark: isDark)).cornerRadius(10)
    }

    private func commit() {
        var updated = log
        if let w = Double(weight.replacingOccurrences(of: ",", with: ".")) { updated.weight = w }
        if let r = Int(reps) { updated.reps = r }
        onUpdate(updated)
    }
}
