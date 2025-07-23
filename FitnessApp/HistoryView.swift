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
    @State private var selectedExercise: Exercise?
    @State private var showingExerciseHistory = false
    @State private var sessionNote = ""
    @State private var isEditingNote = false
    @State private var showingDeleteAlert = false
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isNoteFocused: Bool

    private var calendar: Calendar { var cal = Calendar(identifier: .gregorian); cal.locale = Locale(identifier: "es_ES"); cal.firstWeekday = 2; return cal }
    private var dayFormatter: DateFormatter { let f = DateFormatter(); f.locale = Locale(identifier: "es_ES"); f.dateFormat = "EEEE"; return f }

    var body: some View {
        ZStack {
            AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
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

                    // Card para las notas de sesión
                    VStack(spacing: 0) {
                        sessionNotesView
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .cardStyle(isDarkMode: themeManager.isDarkMode)

                    // Lista de historial (ahora como parte del contenido principal)
                    historyContent
                    
                    // Botón para borrar historial del día
                    if let selectedDate = selectedDate,
                       let historyForDate = viewModel.completedExercisesForDate(selectedDate),
                       !historyForDate.values.allSatisfy({ $0.isEmpty }) {
                        deleteHistoryButton
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 10)
            }
        }
        .navigationTitle("Historial").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CloseButton { dismiss() }
            }
        }
        .onAppear {
            loadWeight()
            loadSessionNote()
        }
        .onChange(of: selectedDate) { _, _ in 
            loadWeight() 
            loadSessionNote()
        }
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
        .sheet(isPresented: $showingExerciseHistory) {
            if let selectedExercise = selectedExercise {
                ExerciseHistoryDetailView(exercise: selectedExercise)
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
            }
        }
        .alert("Borrar historial", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Borrar", role: .destructive) {
                deleteHistoryForSelectedDate()
            }
        } message: {
            deleteAlertMessage
        }
    }
    
    // --- FUNCIÓN AUXILIAR PARA EL MENSAJE DE LA ALERTA ---
    // Esto asegura que solo se devuelve una Vista (Text)
    private var deleteAlertMessage: Text {
        if let selectedDate = selectedDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "es_ES")
            formatter.dateStyle = .long
            let dateString = formatter.string(from: selectedDate)
            return Text("¿Estás seguro de que quieres borrar todo el historial del \(dateString)? Esta acción no se puede deshacer.")
        } else {
            return Text("¿Estás seguro de que quieres borrar todo el historial? Esta acción no se puede deshacer.")
        }
    }
    
    private var historyContent: some View {
        VStack(spacing: 8) {
            if let selectedDate = selectedDate,
               let historyForDate = viewModel.completedExercisesForDate(selectedDate), 
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
        Button(action: {
            selectedExercise = exercise
            showingExerciseHistory = true
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.primary(themeManager: themeManager))
                        .frame(width: 44, height: 44)
                    
                    if let iconName = exercise.sfSymbolIcon {
                        Image(systemName: iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "dumbbell.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundColor(.white)
                    }
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
                
                // Indicador de que es clicable
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            .padding(12)
            .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var weightInputView: some View { 
        VStack(alignment: .leading, spacing: 12) {
            // Header con icono y título
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
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
                    .tint(AppColors.primary(themeManager: themeManager))
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
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12) 
    }
    
    private var sessionNotesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header con icono y título
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                Text("Notas de la sesión:")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                Spacer()
            }
            
            // Input y botón
            if isEditingNote {
                // TextEditor para notas más largas
                VStack(spacing: 12) {
                    TextEditor(text: $sessionNote)
                        .frame(minHeight: 80, maxHeight: 120)
                        .padding(8)
                        .background(AppColors.background(isDark: themeManager.isDarkMode))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isNoteFocused ? AppColors.primary(themeManager: themeManager) : AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.3), lineWidth: 1)
                        )
                        .focused($isNoteFocused)
                    
                    HStack(spacing: 12) {
                        Button("Cancelar") {
                            // Restaurar valor original
                            if let selectedDate = selectedDate {
                                sessionNote = viewModel.getSessionNote(for: selectedDate) ?? ""
                            }
                            isNoteFocused = false
                            isEditingNote = false
                        }
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        
                        Spacer()
                        
                        Button("Guardar") {
                            if let selectedDate = selectedDate {
                                viewModel.saveSessionNote(sessionNote, for: selectedDate)
                            }
                            isNoteFocused = false
                            isEditingNote = false
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primary(themeManager: themeManager))
                    }
                }
            } else {
                // Mostrar nota y botón editar
                VStack(alignment: .leading, spacing: 8) {
                    if sessionNote.isEmpty {
                        Text("Sin notas para esta sesión")
                            .font(.body)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            .italic()
                    } else {
                        Text(sessionNote)
                            .font(.body)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack {
                        Spacer()
                        Button(sessionNote.isEmpty ? "Añadir nota" : "Editar") {
                            isEditingNote = true
                            isNoteFocused = true
                        }
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                    }
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    private var noDataView: some View {
        VStack(spacing: 12) { 
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            Text("No hay ejercicios completados")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            Text("en esta fecha")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            Spacer() 
        }
        .frame(height: 200) 
    }
    
    private var deleteHistoryButton: some View {
        Button(action: {
            showingDeleteAlert = true
        }) {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .medium))
                Text("Borrar historial del día")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 4)
        .padding(.top, 20)
    }
    
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
    
    private func loadSessionNote() {
        guard let selectedDate = selectedDate else { return }
        sessionNote = viewModel.getSessionNote(for: selectedDate) ?? ""
        isEditingNote = false
    }
    
    private func hideKeyboard() {
        isWeightFocused = false
        isNoteFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func deleteHistoryForSelectedDate() {
        guard let selectedDate = selectedDate else { return }
        
        // Borrar el historial de ejercicios completados para esta fecha
        viewModel.deleteCompletedExercisesForDate(selectedDate)
        
        // Borrar también el peso corporal registrado para esta fecha
        viewModel.deleteBodyWeightForDate(selectedDate)
        
        // Borrar las notas de la sesión para esta fecha
        viewModel.deleteSessionNote(for: selectedDate)
        
        // Recargar los datos
        loadWeight()
        loadSessionNote()
        
        // Feedback háptico
        HapticManager.shared.buttonTapped()
    }
}
