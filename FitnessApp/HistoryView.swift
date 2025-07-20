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
            VStack(spacing: 20) {
                // Card para el selector de fecha
                CustomCalendarView(selectedDate: $selectedDate)
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.09), radius: 12, x: 0, y: 6)
                    .padding()
                    .cardStyle(isDarkMode: themeManager.isDarkMode)

                // Card para el peso corporal
                VStack(spacing: 0) {
                    weightInputView
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .cardStyle(isDarkMode: themeManager.isDarkMode)

                // Lista de historial
                historyListView
            }
            .padding(.horizontal)
            .padding(.top, 16)
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
            if let selectedDate = selectedDate,
               let historyForDate = viewModel.exercisesForDate(selectedDate), 
               !historyForDate.values.allSatisfy({ $0.isEmpty }) {
                let selectedDayName = dayFormatter.string(from: selectedDate)
                ForEach(historyForDate.keys.sorted { $0.rawValue < $1.rawValue }, id: \.self) { routineDay in
                    if let workoutRecords = historyForDate[routineDay], !workoutRecords.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            if routineDay.rawValue.lowercased() != selectedDayName.lowercased() {
                                Text("Realizaste la rutina del \(routineDay.rawValue)")
                                    .font(.headline).foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode)).padding(.horizontal)
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
    }
    
    private func historyRow(for exercise: Exercise, workoutRecord: WorkoutExercise) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.primary)
                    .frame(width: 44, height: 44)
                Image(systemName: "dumbbell.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(.white)
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
        VStack(alignment: .leading, spacing: 12) {
            // Header con icono y título
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(AppColors.primary)
                Text("Peso corporal (kg):")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                Spacer()
            }
            
            // Input y botón
            if isEditingWeight {
                // Input y botón guardar en la misma línea
                HStack(spacing: 12) {
                    TextField("75.5", text: $bodyWeight)
                        .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                        .frame(width: 80, height: 40)
                        .focused($isWeightFocused)
                        .addFocusGlow(isFocused: isWeightFocused)
                    
                    Button("Guardar") { 
                        if let w = Double(bodyWeight), let selectedDate = selectedDate {
                            viewModel.updateBodyWeight(for: selectedDate, weight: w) 
                        }
                        isWeightFocused = false
                        isEditingWeight = false 
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                }
            } else {
                // Peso y botón editar en la misma línea
                HStack {
                    Text(bodyWeight.isEmpty ? "No registrado" : "\(bodyWeight) kg")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Spacer()
                    
                    Button("Editar") { 
                        isEditingWeight = true
                        isWeightFocused = true 
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12) 
    }
    private var noDataView: some View { VStack { Spacer(); Text("Sin datos para esta fecha.").foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode)); Spacer() }.frame(height: 200) }
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
