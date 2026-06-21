//
//  ExerciseDetailSheet.swift
//  FitnessApp
//
//  Detalle del ejercicio: foto (imageData local) + información + ajuste rápido
//  de peso y repeticiones actuales (actualiza la plantilla del ejercicio).
//

import SwiftUI

struct ExerciseDetailSheet: View {
    let exerciseId: UUID
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var weightText: String = ""
    @State private var repsText: String = ""

    private var exercise: Exercise? { viewModel.getExercise(by: exerciseId) }
    private var isDark: Bool { themeManager.isDarkMode }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if let ex = exercise {
                    VStack(alignment: .leading, spacing: 20) {
                        // Foto del ejercicio o icono
                        Group {
                            if let data = ex.imageData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                            } else {
                                ZStack {
                                    AppColors.cardBackground(isDark: isDark)
                                    Image(systemName: ex.sfSymbolIcon ?? "dumbbell.fill")
                                        .font(.system(size: 64, weight: .semibold))
                                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                                }
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .cornerRadius(18)

                        // Nombre
                        Text(ex.name)
                            .font(AppFonts.title2)
                            .foregroundColor(AppColors.textPrimary(isDark: isDark))

                        // Descripción
                        if !ex.info.isEmpty {
                            Text(ex.info)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textSecondary(isDark: isDark))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Datos del ejercicio
                        VStack(spacing: 10) {
                            if ex.repetitions > 0 {
                                detailRow("repeat", "Repeticiones", "\(ex.repetitions)")
                            }
                            if ex.segundos > 0 {
                                detailRow("timer", "Duración", "\(ex.segundos)s")
                            }
                            if ex.weight > 0 {
                                detailRow("scalemass", "Peso", String(format: "%g kg", ex.weight))
                            }
                            detailRow("list.number", "Series", "\(ex.totalSets)")
                            if ex.rir > 0 {
                                detailRow("gauge.medium", "RIR", "\(ex.rir)")
                            }
                            detailRow("timer", "Descanso", "\(ex.restDuration / 60):\(String(format: "%02d", ex.restDuration % 60))")
                        }
                        .padding(16)
                        .cardStyle(isDarkMode: isDark)

                        // Ajustar peso y repeticiones actuales
                        VStack(alignment: .leading, spacing: 14) {
                            Text("AJUSTAR PESO Y REPS")
                                .font(AppFonts.label)
                                .tracking(1.0)
                                .foregroundColor(AppColors.textSecondary(isDark: isDark))

                            HStack(spacing: 12) {
                                editField(title: "Peso (kg)", text: $weightText, keyboard: .decimalPad)
                                editField(title: "Reps", text: $repsText, keyboard: .numberPad)
                            }

                            Button(action: { save(ex) }) {
                                Text("Guardar cambios")
                            }
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
                    weightText = ex.weight > 0 ? String(format: "%g", ex.weight) : ""
                    repsText = ex.repetitions > 0 ? "\(ex.repetitions)" : ""
                }
            }
        }
    }

    @ViewBuilder
    private func detailRow(_ icon: String, _ title: String, _ value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.primary(themeManager: themeManager))
                .frame(width: 24)
            Text(title)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary(isDark: isDark))
            Spacer()
            Text(value)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary(isDark: isDark))
        }
    }

    @ViewBuilder
    private func editField(title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary(isDark: isDark))
            TextField("0", text: text)
                .keyboardType(keyboard)
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textPrimary(isDark: isDark))
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(AppColors.surface(isDark: isDark))
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
    }

    private func save(_ ex: Exercise) {
        var updated = ex
        if let w = Double(weightText.replacingOccurrences(of: ",", with: ".")) {
            updated.weight = w
        }
        if let r = Int(repsText) {
            updated.repetitions = r
        }
        viewModel.updateBaseExercise(updated)
        HapticManager.shared.success()
        dismiss()
    }
}
