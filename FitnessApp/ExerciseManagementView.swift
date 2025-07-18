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
    @State private var selectedTab: Int = 0 // 0: Ejercicios, 1: Añadir Ejercicio
    var shouldShowAddExerciseTab: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // TAB 1: Lista de Ejercicios
            exercisesListFullView
                .tag(0)
            
            // TAB 2: Añadir Ejercicio
            addExerciseFullView
                .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .background(AppColors.background(isDark: themeManager.isDarkMode))
        .onAppear {
            // Si se debe mostrar la pestaña de añadir ejercicio, cambiar a esa pestaña
            if shouldShowAddExerciseTab {
                selectedTab = 1
            }
        }
    }
    
    // MARK: - Vista de Lista de Ejercicios
    private var exercisesListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if getAllExercises().isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green.opacity(0.6))
                        
                        Text("No hay ejercicios añadidos")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        
                        Text("Añade ejercicios para empezar a entrenar")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                } else {
                    ForEach(getAllExercises(), id: \.id) { exercise in
                        EditableExerciseCard(exercise: exercise)
                            .environmentObject(viewModel)
                            .environmentObject(themeManager)
                    }
                }
                
                // Botón de Reset al final
                resetButtonView
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(AppColors.background(isDark: themeManager.isDarkMode))
    }
    
    // MARK: - Función para obtener todos los ejercicios
    private func getAllExercises() -> [Exercise] {
        var uniqueExercises: [Exercise] = []
        var seenIds: Set<UUID> = []
        
        for exercises in viewModel.exercises.values {
            for exercise in exercises {
                if !seenIds.contains(exercise.id) {
                    uniqueExercises.append(exercise)
                    seenIds.insert(exercise.id)
                }
            }
        }
        return uniqueExercises
    }
    
    // MARK: - Vista del Formulario de Añadir Ejercicio
    private var addExerciseFormView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                AddExerciseForm()
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
            }
            .padding(.horizontal, 0)
            .padding(.top, 20)
        }
        .background(AppColors.background(isDark: themeManager.isDarkMode))
    }
    
    // MARK: - Vista del Botón de Reset
    private var resetButtonView: some View {
        VStack(spacing: 16) {
            Button(action: {
                viewModel.resetAllData()
            }) {
                Text("Resetear Todos los Datos")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.background(isDark: themeManager.isDarkMode))
    }
    
    // MARK: - Vista Completa de Lista de Ejercicios
    private var exercisesListFullView: some View {
        VStack(spacing: 0) {
            // HEADER CON PESTAÑAS
            VStack(spacing: 0) {
                // Título y navegación
                HStack {
                    Text("Ejercicios")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Navegación entre pestañas
                HStack(spacing: 0) {
                    // Pestaña Ejercicios (activa)
                    Button(action: {
                        selectedTab = 0
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            Text("Ejercicios")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    
                    // Pestaña Añadir Ejercicio (inactiva)
                    Button(action: {
                        selectedTab = 1
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            Text("Añadir")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
                .background(AppColors.background(isDark: themeManager.isDarkMode))
            }
            .background(AppColors.background(isDark: themeManager.isDarkMode))
            
            // CONTENIDO
            exercisesListView
        }
        .background(AppColors.background(isDark: themeManager.isDarkMode))
    }
    
    // MARK: - Vista Completa de Añadir Ejercicio
    private var addExerciseFullView: some View {
        VStack(spacing: 0) {
            // HEADER CON PESTAÑAS
            VStack(spacing: 0) {
                // Título y navegación
                HStack {
                    Text("Añadir Ejercicio")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Navegación entre pestañas
                HStack(spacing: 0) {
                    // Pestaña Ejercicios (inactiva)
                    Button(action: {
                        selectedTab = 0
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            Text("Ejercicios")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    
                    // Pestaña Añadir Ejercicio (activa)
                    Button(action: {
                        selectedTab = 1
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            Text("Añadir")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
                .background(AppColors.background(isDark: themeManager.isDarkMode))
            }
            .background(AppColors.background(isDark: themeManager.isDarkMode))
            
            // CONTENIDO
            addExerciseFormView
        }
        .background(AppColors.background(isDark: themeManager.isDarkMode))
    }
}

// MARK: - Componente para mostrar y editar ejercicios
struct EditableExerciseCard: View {
    let exercise: Exercise
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    if !exercise.info.isEmpty {
                        Text(exercise.info)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            
            // Mostrar configuración del ejercicio
            VStack(alignment: .leading, spacing: 4) {
                Text("Configuración:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                
                HStack {
                    if exercise.repetitions > 0 {
                        Text("\(exercise.repetitions) reps")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    }
                    
                    if exercise.weight > 0 {
                        Text("- \(exercise.weight, specifier: "%.1f") kg")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    }
                    
                    if exercise.totalSets > 0 {
                        Text("- \(exercise.totalSets) series")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    }
                    
                    Spacer()
                }
                
                // Mostrar días configurados
                if !getDaysForExercise(exercise.id).isEmpty {
                    HStack {
                        Text("Días:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        
                        HStack(spacing: 4) {
                            ForEach(getDaysForExercise(exercise.id), id: \.self) { day in
                                Text(dayShortName(day))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingEditSheet) {
            ExerciseEditView(exercise: exercise)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
    }
    
    // Función para obtener los días donde está configurado el ejercicio
    private func getDaysForExercise(_ exerciseId: UUID) -> [String] {
        var days: [String] = []
        for (day, exercises) in viewModel.exercises {
            if exercises.contains(where: { $0.id == exerciseId }) {
                days.append(day.rawValue)
            }
        }
        return days.sorted()
    }
    
    // Función para obtener nombre corto del día
    private func dayShortName(_ day: String) -> String {
        switch day {
        case "Lunes": return "LUN"
        case "Martes": return "MAR"
        case "Miércoles": return "MIE"
        case "Jueves": return "JUE"
        case "Viernes": return "VIE"
        default: return day
        }
    }
}

// MARK: - Vista de edición de ejercicio
struct ExerciseEditView: View {
    let exercise: Exercise
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var info: String = ""
    @State private var repetitions: Int = 0
    @State private var weight: Double = 0.0
    @State private var totalSets: Int = 1
    @State private var timerMinutes: Int = 0
    @State private var timerSeconds: Int = 30
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Nombre del ejercicio
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "dumbbell.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                            Text("Nombre del Ejercicio")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        }
                        
                        TextField("Nombre", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Información
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                            Text("Información")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        }
                        
                        TextField("Información del ejercicio", text: $info, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                        
                        // Botón para añadir foto
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.green)
                                Text("Cambiar Foto")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Repeticiones
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "repeat.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                            Text("Repeticiones")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        }
                        
                        TextField("Repeticiones", value: $repetitions, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    // Peso
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "scalemass.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                            Text("Peso (kg)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        }
                        
                        TextField("Peso", value: $weight, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    
                    // Total de Sets
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "list.number.rtl")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                            Text("Total de Sets")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        }
                        
                        TextField("Sets", value: $totalSets, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    // Timer de descanso
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "timer.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                            Text("Timer de Descanso")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        }
                            .frame(height: 44)
                            .background(Color.clear)
                            .cornerRadius(8)
                        
                        HStack(spacing: 16) {
                            // Minutos
                            VStack {
                                Text("Minutos")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                
                                Picker("Minutos", selection: $timerMinutes) {
                                    ForEach(0..<10) { minute in
                                        Text("\(minute)").tag(minute)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 65)
                                .clipped()
                            }
                            
                            // Segundos
                            VStack {
                                Text("Segundos")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                
                                Picker("Segundos", selection: $timerSeconds) {
                                    ForEach([0, 15, 30, 45], id: \.self) { second in
                                        Text("\(second)").tag(second)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 65)
                                .clipped()
                            }
                        }
                        .padding(.vertical, 8)
                        .background(AppColors.background(isDark: themeManager.isDarkMode))
                        .cornerRadius(8)
                    }
                    
                    // Botón de eliminar ejercicio
                    Button(action: deleteExercise) {
                        Text("Eliminar Ejercicio")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Editar Ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                name = exercise.name
                info = exercise.info
                repetitions = exercise.repetitions
                weight = exercise.weight
                totalSets = exercise.totalSets
                timerMinutes = 0
                timerSeconds = 30
            }
            .sheet(isPresented: $showingImagePicker) {
                // Aquí iría el selector de imágenes
                // Por ahora mostramos un placeholder
                VStack {
                    Text("Selector de Imágenes")
                        .font(.title)
                        .padding()
                    Text("Funcionalidad próximamente")
                        .foregroundColor(.secondary)
                    Button("Cerrar") {
                        showingImagePicker = false
                    }
                    .padding()
                }
            }
        }
    }
    
    private func saveChanges() {
        // Actualizar el ejercicio
        var updatedExercise = exercise
        updatedExercise.name = name
        updatedExercise.info = info
        updatedExercise.repetitions = repetitions
        updatedExercise.weight = weight
        updatedExercise.totalSets = totalSets
        
        // Encontrar el día del ejercicio
        if let day = findDayForExercise(exercise) {
            viewModel.updateExercise(updatedExercise, in: day)
        }
        dismiss()
    }
    
    private func deleteExercise() {
        if let day = findDayForExercise(exercise) {
            viewModel.removeExercise(exercise, from: day)
        }
        dismiss()
    }
    
    private func findDayForExercise(_ exercise: Exercise) -> WorkoutDay? {
        for (day, exercises) in viewModel.exercises {
            if exercises.contains(where: { $0.id == exercise.id }) {
                return day
            }
        }
        return nil
    }
}

// MARK: - Formulario para añadir ejercicio
struct AddExerciseForm: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var name: String = ""
    @State private var info: String = ""
    @State private var repetitions: Int = 0
    @State private var weight: Double = 0.0
    @State private var totalSets: Int = 1
    @State private var selectedDays: Set<String> = []
    @State private var timerMinutes: Int = 0
    @State private var timerSeconds: Int = 30
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]
    
    var body: some View {
        VStack(spacing: 24) {
            // Día selector
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    Text("Días de la Semana")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                // Botones horizontales para días
                HStack(spacing: 4) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        Button(action: {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }) {
                            Text(dayShortName(day))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedDays.contains(day) ? .white : AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedDays.contains(day) ? Color.green : AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Nombre del ejercicio
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    Text("Nombre del Ejercicio")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                TextField("Ej: Press de banca", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 44)
                    .background(Color.clear)
                    .cornerRadius(8)
            }
            
            // Información
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    Text("Información")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                TextField("Información del ejercicio", text: $info, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                    .frame(minHeight: 60)
                    .background(Color.clear)
                    .cornerRadius(8)
                
                // Botón para añadir foto
                Button(action: {
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.green)
                        Text("Añadir Foto")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .alert("Funcionalidad próximamente", isPresented: $showingImagePicker) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("La funcionalidad de añadir fotos estará disponible en una próxima actualización.")
                }
            }
            
            // Repeticiones
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "repeat.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    Text("Repeticiones")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                TextField("Repeticiones", value: $repetitions, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(height: 44)
                    .background(Color.clear)
                    .cornerRadius(8)
            }
            
            // Peso
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    Text("Peso (kg)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                TextField("Peso", value: $weight, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(height: 44)
                    .background(Color.clear)
                    .cornerRadius(8)
            }
            
            // Total de Series
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "list.number.rtl")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    Text("Total de Series")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                TextField("Series", value: $totalSets, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(height: 44)
                    .background(Color.clear)
                    .cornerRadius(8)
            }
            
            // Timer de descanso
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "timer.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    Text("Timer de Descanso")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                HStack(spacing: 16) {
                    // Minutos
                    VStack {
                        Text("Minutos")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        
                        Picker("Minutos", selection: $timerMinutes) {
                            ForEach(0..<10) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 65)
                        .clipped()
                    }
                    
                    // Segundos
                    VStack {
                        Text("Segundos")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        
                        Picker("Segundos", selection: $timerSeconds) {
                            ForEach([0, 15, 30, 45], id: \.self) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 65)
                        .clipped()
                    }
                }
                .padding(.vertical, 8)
                .background(AppColors.background(isDark: themeManager.isDarkMode))
                .cornerRadius(8)
            }
            
            // Botón para añadir ejercicio
            Button(action: {
                // Validar que todos los campos requeridos estén completos
                if name.isEmpty {
                    alertMessage = "Por favor, ingresa un nombre para el ejercicio."
                    showingAlert = true
                    return
                }
                
                if selectedDays.isEmpty {
                    alertMessage = "Por favor, selecciona al menos un día."
                    showingAlert = true
                    return
                }
                
                // Crear y añadir el ejercicio
                addExercise()
                
                // Dismissar el teclado
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                    Text("Añadir Ejercicio")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    (name.isEmpty || selectedDays.isEmpty) ? 
                    Color.gray.opacity(0.6) : AppColors.primary
                )
                .cornerRadius(12)
                .shadow(color: (name.isEmpty || selectedDays.isEmpty) ? 
                       Color.clear : AppColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .disabled(name.isEmpty || selectedDays.isEmpty)
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
            
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(AppColors.background(isDark: themeManager.isDarkMode))
        .onTapGesture {
            // Dismissar el teclado al tocar fuera de los campos
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .sheet(isPresented: $showingImagePicker) {
            // Aquí iría el selector de imágenes
            // Por ahora mostramos un placeholder
            VStack {
                Text("Selector de Imágenes")
                    .font(.title)
                    .padding()
                Text("Funcionalidad próximamente")
                    .foregroundColor(.secondary)
                Button("Cerrar") {
                    showingImagePicker = false
                }
                .padding()
            }
        }
    }
    
    private func addExercise() {
        let newExercise = Exercise(
            id: UUID(),
            name: name,
            repetitions: repetitions,
            weight: weight,
            totalSets: totalSets,
            completedSets: 0,
            lastSetCompletedAt: nil,
            info: info
        )
        
        // Añadir el ejercicio a todos los días seleccionados
        for selectedDay in selectedDays {
            if let workoutDay = WorkoutDay.allCases.first(where: { $0.rawValue == selectedDay }) {
                viewModel.addExercise(newExercise, to: workoutDay)
            }
        }
        
        // Limpiar formulario
        name = ""
        info = ""
        repetitions = 0
        weight = 0.0
        totalSets = 1
        selectedDays = []
        timerMinutes = 0
        timerSeconds = 30
    }
    
    private func dayShortName(_ day: String) -> String {
        switch day {
        case "Lunes": return "LUN"
        case "Martes": return "MAR"
        case "Miércoles": return "MIE"
        case "Jueves": return "JUE"
        case "Viernes": return "VIE"
        default: return day
        }
    }
}
