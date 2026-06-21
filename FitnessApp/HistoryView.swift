//
//  HistoryView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date? = Date()
    @State private var bodyWeight = ""
    @State private var isEditingWeight = false
    @FocusState private var isWeightFocused: Bool

    private var calendar: Calendar { var cal = Calendar(identifier: .gregorian); cal.locale = Locale(identifier: "es_ES"); cal.firstWeekday = 2; return cal }
    private var dayFormatter: DateFormatter { let f = DateFormatter(); f.locale = Locale(identifier: "es_ES"); f.dateFormat = "EEEE"; return f }

    var body: some View {
        ZStack {
            AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
            VStack(spacing: 12) {
                // Card compacta para el selector de fecha (ya trae su propio fondo/sombra)
                CustomCalendarView(selectedDate: $selectedDate)
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)

                // Card compacta para el peso corporal
                weightInputView

                // Lista de historial: ocupa el resto del alto disponible
                historyListView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 10)
        }
        .navigationTitle("Historial").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CloseButton { dismiss() }
            }
        }
        .onAppear(perform: loadWeight)
        .onChange(of: selectedDate) { _, _ in loadWeight() }
    }
    
    private var historyListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
            if let selectedDate = selectedDate,
               let historyForDate = viewModel.exercisesForDate(selectedDate), 
               !historyForDate.values.allSatisfy({ $0.isEmpty }) {
                let selectedDayName = dayFormatter.string(from: selectedDate)
                ForEach(historyForDate.keys.sorted { $0.rawValue < $1.rawValue }, id: \.self) { routineDay in
                    if let workoutRecords = historyForDate[routineDay], !workoutRecords.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            if routineDay.rawValue.lowercased() != selectedDayName.lowercased() {
                                Text("Realizaste la rutina del \(routineDay.rawValue)")
                                    .font(AppFonts.subtitle).foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode)).padding(.horizontal)
                            }
                            ForEach(workoutRecords) { workoutRecord in
                                if let exercise = viewModel.getExercise(by: workoutRecord.exerciseId) {
                                    historyRow(for: exercise, workoutRecord: workoutRecord)
                                }
                            }
                        }.padding(.vertical, 8)
                    }
                }
            } else {
                noDataView
            }
            }
            .frame(maxWidth: .infinity, minHeight: 0)
        }
    }

    private func historyRow(for exercise: Exercise, workoutRecord: WorkoutExercise) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.primary(themeManager: themeManager))
                    .frame(width: 44, height: 44)
                Image(systemName: "dumbbell.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name.capitalized)
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                Text("\(workoutRecord.completedSets)/\(exercise.totalSets) series • \(exercise.repetitions) reps • \(String(format: "%.1f", exercise.weight)) kg")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            Spacer()
        }
        .padding(12)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.vertical, 4)
    }
    
    private var weightInputView: some View {
        // Tarjeta compacta en una sola fila: icono + label + valor/input + acción
        HStack(spacing: 10) {
            Image(systemName: "scalemass")
                .foregroundColor(AppColors.primary(themeManager: themeManager))
            Text("Peso corporal:")
                .font(AppFonts.label)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))

            Spacer()

            if isEditingWeight {
                TextField("75.5", text: $bodyWeight)
                    .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                    .frame(width: 80, height: 36)
                    .focused($isWeightFocused)
                    .addFocusGlow(isFocused: isWeightFocused)

                Button("Guardar") {
                    if let w = Double(bodyWeight), let selectedDate = selectedDate {
                        viewModel.updateBodyWeight(for: selectedDate, weight: w)
                    }
                    isWeightFocused = false
                    isEditingWeight = false
                }
                .font(AppFonts.subtitle)
                .buttonStyle(.borderedProminent)
                .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                .tint(AppColors.primary(themeManager: themeManager))
            } else {
                Text(bodyWeight.isEmpty ? "No registrado" : "\(bodyWeight) kg")
                    .font(AppFonts.metric)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))

                Button("Editar") {
                    isEditingWeight = true
                    isWeightFocused = true
                }
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.primary(themeManager: themeManager))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.09), radius: 12, x: 0, y: 6)
    }
    private var noDataView: some View { VStack { Spacer(); Text("Sin datos para esta fecha.").font(AppFonts.body).foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode)); Spacer() }.frame(height: 200) }
    private func loadWeight() { 
        guard let selectedDate = selectedDate else { return }
        if let w = viewModel.bodyWeightForDate(selectedDate) { 
            bodyWeight = String(format: "%.1f", w)
            isEditingWeight = false 
        } else { 
            bodyWeight = ""
            isEditingWeight = true 
        } 
    }
}
