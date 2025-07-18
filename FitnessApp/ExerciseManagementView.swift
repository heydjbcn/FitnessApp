//
//  ExerciseManagementView.swift
//  FitnessApp
//
//  Created by Assistant on 17/7/25.
//

import SwiftUI

struct ExerciseManagementView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con título y botón de cerrar
            HStack {
                Text(selectedTab == 0 ? "Añadir Ejercicio" : "Ejercicios")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                Spacer()
                CloseButton {
                    dismiss()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Selector de pestañas
            HStack(spacing: 20) {
                Button(action: { selectedTab = 0 }) {
                    Text("Añadir Ejercicio")
                        .foregroundColor(selectedTab == 0 ? AppColors.primary : AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        .font(.subheadline.weight(selectedTab == 0 ? .bold : .regular))
                }
                
                Button(action: { selectedTab = 1 }) {
                    Text("Ejercicios")
                        .foregroundColor(selectedTab == 1 ? AppColors.primary : AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        .font(.subheadline.weight(selectedTab == 1 ? .bold : .regular))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Pestañas
            TabView(selection: $selectedTab) {
                AddExerciseTab()
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                    .tabItem {
                        Text("Añadir Ejercicio")
                    }
                    .tag(0)
                
                ExercisesListTab()
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                    .tabItem {
                        Text("Ejercicios")
                    }
                    .tag(1)
            }
        }
        .background(AppColors.background(isDark: themeManager.isDarkMode))
    }
}

// MARK: - Pestaña de Añadir Ejercicio
struct AddExerciseTab: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    // Estados para el formulario
    @State private var exerciseName = ""
    @State private var repetitions = 10
    @State private var totalSets = 3
    @State private var weight: Double = 0
    @State private var selectedDays: Set<WorkoutDay> = [.monday]
    @State private var description = ""
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Contenedor principal con todo el formulario
                VStack(spacing: 20) {
                    // Título
                    HStack {
                        Text("Añadir Nuevo Ejercicio")
                            .font(.title2.weight(.bold))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        Spacer()
                    }
                    
                    // Nombre del ejercicio
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre del ejercicio")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        TextField("Ej: Press de banca", text: $exerciseName)
                            .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                    }
                    
                    // Repeticiones y Series
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeticiones")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            HStack {
                                Button("-") {
                                    if repetitions > 1 { repetitions -= 1 }
                                }
                                .frame(width: 44, height: 44)
                                .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                .cornerRadius(8)
                                
                                Text("\(repetitions) reps")
                                    .frame(maxWidth: .infinity)
                                    .font(.body.weight(.medium))
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                
                                Button("+") {
                                    if repetitions < 50 { repetitions += 1 }
                                }
                                .frame(width: 44, height: 44)
                                .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                .cornerRadius(8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Series")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            HStack {
                                Button("-") {
                                    if totalSets > 1 { totalSets -= 1 }
                                }
                                .frame(width: 44, height: 44)
                                .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                .cornerRadius(8)
                                
                                Text("\(totalSets) sets")
                                    .frame(maxWidth: .infinity)
                                    .font(.body.weight(.medium))
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                
                                Button("+") {
                                    if totalSets < 10 { totalSets += 1 }
                                }
                                .frame(width: 44, height: 44)
                                .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Peso
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Peso (kg)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        HStack {
                            TextField("0", value: $weight, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                            Text("kg")
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                .font(.body.weight(.medium))
                        }
                    }
                    
                    // 1. Descripción / Notas (PRIMER ELEMENTO DEL ORDEN REQUERIDO)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descripción / Notas")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        TextField("Notas adicionales...", text: $description, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                    }
                    
                    // 2. Añadir Foto (Opcional) (SEGUNDO ELEMENTO DEL ORDEN REQUERIDO)
                    Button {
                        // TODO: Implementar selección de foto
                    } label: {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.title3)
                            Text("Añadir Foto (Opcional)")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColors.primary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppColors.primary, lineWidth: 1.5)
                                )
                        )
                    }
                    
                    // 3. Añadir a los días (TERCER ELEMENTO DEL ORDEN REQUERIDO)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(AppColors.primary)
                            Text("Añadir a los días:")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(WorkoutDay.allCases, id: \.self) { day in
                                Button {
                                    if selectedDays.contains(day) {
                                        selectedDays.remove(day)
                                    } else {
                                        selectedDays.insert(day)
                                    }
                                } label: {
                                    Text(day.shortName)
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(selectedDays.contains(day) ? .white : AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                        .frame(width: 50, height: 50)
                                        .background(selectedDays.contains(day) ? AppColors.primary : AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedDays.contains(day) ? Color.clear : AppColors.primary.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    // 4. Configuración del Timer (CUARTO ELEMENTO DEL ORDEN REQUERIDO)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Configuración del Timer")
                            .font(.headline.weight(.bold))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        HStack {
                            Text("Tiempo de descanso")
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            Spacer()
                            Text("\(viewModel.restDuration / 60):\(String(format: "%02d", viewModel.restDuration % 60))")
                                .foregroundColor(AppColors.primary)
                                .fontWeight(.bold)
                        }
                        
                        HStack(spacing: 8) {
                            RestDurationButton(duration: 30, current: viewModel.restDuration, isDarkMode: themeManager.isDarkMode) {
                                viewModel.restDuration = 30
                            }
                            RestDurationButton(duration: 60, current: viewModel.restDuration, isDarkMode: themeManager.isDarkMode) {
                                viewModel.restDuration = 60
                            }
                            RestDurationButton(duration: 90, current: viewModel.restDuration, isDarkMode: themeManager.isDarkMode) {
                                viewModel.restDuration = 90
                            }
                            RestDurationButton(duration: 120, current: viewModel.restDuration, isDarkMode: themeManager.isDarkMode) {
                                viewModel.restDuration = 120
                            }
                        }
                        
                        HStack {
                            Text("Tiempo personalizado (segundos)")
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            Spacer()
                            TextField("90", value: Binding(
                                get: { viewModel.restDuration },
                                set: { viewModel.restDuration = $0 }
                            ), format: .number)
                            .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                            .frame(width: 80)
                            .keyboardType(.numberPad)
                            
                            Button("Aplicar") {
                                // El binding ya actualiza automáticamente
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .frame(width: 80)
                        }
                        
                        // Botón de añadir ejercicio (movido justo después del timer)
                        Button {
                            saveExercise()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Añadir Ejercicio")
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(exerciseName.isEmpty || selectedDays.isEmpty ? Color.gray : AppColors.primary)
                            .cornerRadius(16)
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(exerciseName.isEmpty || selectedDays.isEmpty)
                        .padding(.top, 20)
                    }
                    Button {
                        saveExercise()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Añadir Ejercicio")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(exerciseName.isEmpty || selectedDays.isEmpty ? Color.gray : AppColors.primary)
                        .cornerRadius(16)
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(exerciseName.isEmpty || selectedDays.isEmpty)
                }
                .padding(20)
                .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                .cornerRadius(20)
                .shadow(color: .black.opacity(themeManager.isDarkMode ? 0.3 : 0.1), radius: 10, x: 0, y: 4)
                .padding(.horizontal)
                
                // Resetear progreso (contenedor separado)
                VStack(spacing: 12) {
                    Text("Resetear todo el progreso")
                        .font(.headline.weight(.bold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Button {
                        viewModel.resetAllData()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reset App")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(AppColors.primary)
                        .cornerRadius(16)
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(20)
                .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                .cornerRadius(20)
                .shadow(color: .black.opacity(themeManager.isDarkMode ? 0.3 : 0.1), radius: 10, x: 0, y: 4)
                .padding(.horizontal)
            }
        }
        .background(AppColors.background(isDark: themeManager.isDarkMode))
    }
    
    // Función para guardar el ejercicio
    private func saveExercise() {
        let newExercise = Exercise(
            name: exerciseName,
            repetitions: repetitions,
            weight: weight,
            totalSets: totalSets,
            completedSets: 0
        )
        
        for day in selectedDays {
            viewModel.addExercise(newExercise, to: day)
        }
        
        // Limpiar el formulario
        exerciseName = ""
        repetitions = 10
        totalSets = 3
        weight = 0
        selectedDays = [.monday]
        description = ""
    }
}

// MARK: - Pestaña de Lista de Ejercicios
struct ExercisesListTab: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var selectedDay: WorkoutDay = .monday
    @State private var editingExercise: Exercise?
    
    var filteredExercises: [Exercise] {
        let dayExercises = viewModel.exercises[selectedDay] ?? []
        if searchText.isEmpty {
            return dayExercises
        } else {
            return dayExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Selector de día
            daySelector
            
            // Buscador
            searchBarContent
            
            // Lista de ejercicios
            exercisesListContent
            
            Spacer()
        }
        .padding()
        .background(AppColors.background(isDark: themeManager.isDarkMode))
        .sheet(item: $editingExercise) { exercise in
            EditExerciseView(exercise: exercise, day: selectedDay)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
    }
    
    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(WorkoutDay.allCases, id: \.self) { day in
                    dayButton(for: day)
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func dayButton(for day: WorkoutDay) -> some View {
        Button {
            selectedDay = day
        } label: {
            VStack(spacing: 4) {
                Text(day.shortName)
                    .font(.caption.weight(.bold))
                    .foregroundColor(selectedDay == day ? .white : AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                if let exercises = viewModel.exercises[day], !exercises.isEmpty {
                    Circle()
                        .fill(selectedDay == day ? .white.opacity(0.3) : AppColors.primary)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 60, height: 60)
            .background(selectedDay == day ? AppColors.primary : AppColors.cardBackground(isDark: themeManager.isDarkMode))
            .cornerRadius(16)
            .shadow(color: selectedDay == day ? AppColors.primary.opacity(0.3) : .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private var searchBarContent: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            
            TextField("Buscar ejercicios...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
        }
        .padding(16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: .black.opacity(themeManager.isDarkMode ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
    }
    
    private var exercisesListContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ejercicios del \(selectedDay.rawValue)")
                .font(.title2.weight(.bold))
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            if filteredExercises.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: searchText.isEmpty ? "dumbbell" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.5))
                    
                    Text(searchText.isEmpty ? "No hay ejercicios para este día" : "No se encontraron ejercicios")
                        .font(.body.weight(.medium))
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredExercises, id: \.id) { exercise in
                        ExerciseRowView(
                            exercise: exercise,
                            onEdit: { editingExercise = exercise },
                            onDelete: { 
                                viewModel.removeExercise(from: selectedDay, at: indexOfExercise(exercise))
                            }
                        )
                        .environmentObject(themeManager)
                    }
                }
            }
        }
    }
    
    private func indexOfExercise(_ exercise: Exercise) -> Int {
        let dayExercises = viewModel.exercises[selectedDay] ?? []
        return dayExercises.firstIndex(of: exercise) ?? 0
    }
}

// MARK: - Components

struct RestDurationButton: View {
    let duration: Int
    let current: Int
    let isDarkMode: Bool
    let action: () -> Void
    
    private var isSelected: Bool {
        return duration == current
    }
    
    var body: some View {
        Button(action: action) {
            Text(duration >= 60 ? "\(duration / 60):\(String(format: "%02d", duration % 60))" : "\(duration)s")
        }
        .buttonStyle(RestDurationButtonStyle(isSelected: isSelected, isDarkMode: isDarkMode))
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    let onEdit: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.body.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text("\(exercise.repetitions) reps × \(exercise.totalSets) series")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                
                if exercise.weight > 0 {
                    Text("Peso: \(exercise.weight, specifier: "%.1f") kg")
                        .font(.caption.weight(.medium))
                        .foregroundColor(AppColors.primary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.primary)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: .black.opacity(themeManager.isDarkMode ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Edit Exercise View
struct EditExerciseView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    let exercise: Exercise
    let day: WorkoutDay
    
    @State private var exerciseName: String
    @State private var repetitions: Int
    @State private var totalSets: Int
    @State private var weight: Double
    
    init(exercise: Exercise, day: WorkoutDay) {
        self.exercise = exercise
        self.day = day
        self._exerciseName = State(initialValue: exercise.name)
        self._repetitions = State(initialValue: exercise.repetitions)
        self._totalSets = State(initialValue: exercise.totalSets)
        self._weight = State(initialValue: exercise.weight)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header con botón X de cerrar
                HStack {
                    Spacer()
                    CloseButton {
                        dismiss()
                    }
                    .padding(.trailing)
                }
                .padding(.top, 8)
                
                // Contenido del formulario
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Editar Ejercicio")
                                .font(.title2.weight(.bold))
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            // Nombre del ejercicio
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nombre del ejercicio")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                
                                TextField("Nombre del ejercicio", text: $exerciseName)
                                    .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                            }
                            
                            // Repeticiones y Series
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Repeticiones")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    
                                    HStack {
                                        Button("-") {
                                            if repetitions > 1 { repetitions -= 1 }
                                        }
                                        .frame(width: 44, height: 44)
                                        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                        .cornerRadius(8)
                                        
                                        Text("\(repetitions)")
                                            .frame(maxWidth: .infinity)
                                            .font(.body.weight(.medium))
                                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                        
                                        Button("+") {
                                            if repetitions < 50 { repetitions += 1 }
                                        }
                                        .frame(width: 44, height: 44)
                                        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Series")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    
                                    HStack {
                                        Button("-") {
                                            if totalSets > 1 { totalSets -= 1 }
                                        }
                                        .frame(width: 44, height: 44)
                                        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                        .cornerRadius(8)
                                        
                                        Text("\(totalSets)")
                                            .frame(maxWidth: .infinity)
                                            .font(.body.weight(.medium))
                                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                        
                                        Button("+") {
                                            if totalSets < 10 { totalSets += 1 }
                                        }
                                        .frame(width: 44, height: 44)
                                        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            
                            // Peso
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Peso (kg)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                
                                HStack {
                                    TextField("0", value: $weight, format: .number)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                                    Text("kg")
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                        .font(.body.weight(.medium))
                                }
                            }
                            
                            // Botón de guardar
                            Button {
                                saveChanges()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                    Text("Guardar Cambios")
                                        .font(.headline.weight(.bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(exerciseName.isEmpty ? Color.gray : AppColors.primary)
                                .cornerRadius(16)
                                .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(exerciseName.isEmpty)
                        }
                        .padding(20)
                        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(themeManager.isDarkMode ? 0.3 : 0.1), radius: 10, x: 0, y: 4)
                        .padding(.horizontal)
                    }
                }
            }
            .background(AppColors.background(isDark: themeManager.isDarkMode))
        }
    }
    
    private func saveChanges() {
        var updatedExercise = exercise
        updatedExercise.name = exerciseName
        updatedExercise.repetitions = repetitions
        updatedExercise.totalSets = totalSets
        updatedExercise.weight = weight
        
        viewModel.updateExercise(updatedExercise, in: day)
        dismiss()
    }
}

#Preview {
    ExerciseManagementView()
        .environmentObject(WorkoutViewModel())
        .environmentObject(ThemeManager())
}
