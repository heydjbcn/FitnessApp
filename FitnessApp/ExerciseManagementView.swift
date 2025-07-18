//
//  ExerciseManagementView.swift
//  FitnessApp
//
//  Created by Assistant on 17/7/25.
//

import SwiftUI
import PhotosUI

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
                    .onboardingHighlight(
                        isHighlighted: viewModel.onboardingManager.showingOnboarding && 
                                     viewModel.onboardingManager.onboardingStep == 3 &&
                                     OnboardingManager.onboardingSteps[3].highlightArea == .exerciseList
                    )
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
        return viewModel.availableExercises
    }
    
    // MARK: - Vista del Formulario de Añadir Ejercicio
    private var addExerciseFormView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                AddExerciseForm()
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                    .onboardingHighlight(
                        isHighlighted: viewModel.onboardingManager.showingOnboarding && 
                                     (viewModel.onboardingManager.onboardingStep == 1 || 
                                      viewModel.onboardingManager.onboardingStep == 2) &&
                                     (OnboardingManager.onboardingSteps[viewModel.onboardingManager.onboardingStep].highlightArea == .addExerciseForm)
                    )
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
                    Spacer()
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
                    Spacer()
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
        for (day, workoutExercises) in viewModel.dailyWorkoutRecords {
            if workoutExercises.contains(where: { $0.exerciseId == exerciseId }) {
                days.append(day.displayName)
            }
        }
        return days
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
    @State private var totalSets: Int = 4
    @State private var timerMinutes: Int = 2
    @State private var timerSeconds: Int = 0
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
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
                        VStack(spacing: 12) {
                            // Mostrar imagen actual si existe
                            if let imageData = selectedImageData ?? exercise.imageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green, lineWidth: 2)
                                    )
                            }
                            
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.green)
                                    Text(selectedImageData != nil || exercise.imageData != nil ? "Cambiar Foto" : "Añadir Foto")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.green)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
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
                        
                        TextField("", value: $repetitions, format: .number)
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
                        
                        TextField("", value: $weight, format: .number)
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
                
                // Cargar la duración de descanso del ejercicio existente
                timerMinutes = exercise.restDuration / 60
                timerSeconds = exercise.restDuration % 60
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let newItem = newItem {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
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
        updatedExercise.restDuration = timerMinutes * 60 + timerSeconds
        
        // Actualizar imagen si se seleccionó una nueva
        if let imageData = selectedImageData {
            updatedExercise.imageData = imageData
        }
        
        // Encontrar el día del ejercicio
        if let day = findDayForExercise(exercise) {
            viewModel.updateExercise(updatedExercise, in: day)
        }
        dismiss()
    }
    
    private func deleteExercise() {
        // Eliminar el ejercicio base completamente (de todos los días)
        viewModel.removeExercise(baseExercise: exercise)
        dismiss()
    }
    
    private func findDayForExercise(_ exercise: Exercise) -> WorkoutDay? {
        for (day, workoutExercises) in viewModel.dailyWorkoutRecords {
            if workoutExercises.contains(where: { $0.exerciseId == exercise.id }) {
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
    @StateObject private var focusManager = FocusModeManager()
    
    @State private var name: String = ""
    @State private var info: String = ""
    @State private var repetitions: String = ""
    @State private var weight: String = ""
    @State private var totalSets: Int = 4
    @State private var selectedDays: Set<String> = []
    @State private var timerMinutes: Int = 2
    @State private var timerSeconds: Int = 0
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingIconPicker = false
    @State private var selectedIcon: String? = nil
    @State private var iconColor: String = "blue"
    
    let days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]
    
    var body: some View {
        VStack(spacing: 24) {
            // Botón de modo de enfoque
            HStack {
                Button(action: {
                    focusManager.toggleFocusMode()
                }) {
                    HStack {
                        Image(systemName: focusManager.isActive ? "brain.head.profile.fill" : "brain.head.profile")
                            .foregroundColor(focusManager.isActive ? .white : .blue)
                        Text(focusManager.isActive ? "Desactivar Enfoque" : "Modo de Enfoque")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(focusManager.isActive ? .white : .blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(focusManager.isActive ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            
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
                
                // Selector de icono o foto
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Botón para seleccionar icono SF Symbol
                        Button(action: {
                            showingIconPicker = true
                        }) {
                            HStack {
                                Image(systemName: "square.grid.3x3.fill")
                                    .foregroundColor(.orange)
                                Text("Seleccionar Icono")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Botón para añadir foto
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.green)
                                Text(photoData != nil ? "Cambiar Foto" : "Añadir Foto")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Previsualización del icono seleccionado
                    if let icon = selectedIcon {
                        VStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 40))
                                .foregroundColor(colorFromString(iconColor))
                            Text("Icono seleccionado")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Previsualización de la imagen seleccionada
                    if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.top, 8)
                    }
                }
            }
            
            // Repeticiones con validación
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "repeat.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    Text("Repeticiones")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                TextField("Repeticiones", text: $repetitions)
                    .integerTextField(
                        text: $repetitions,
                        placeholder: "Repeticiones",
                        validationMessage: "Ingrese solo números enteros"
                    )
            }
            
            // Peso con validación
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    Text("Peso (kg)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                TextField("Peso", text: $weight)
                    .numericTextField(
                        text: $weight,
                        placeholder: "Peso",
                        validationMessage: "Ingrese solo números (ej: 75.5)"
                    )
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
                    Color.gray.opacity(0.6) : Color.green
                )
                .cornerRadius(12)
                .shadow(color: (name.isEmpty || selectedDays.isEmpty) ? 
                       Color.clear : Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .disabled(name.isEmpty || selectedDays.isEmpty)
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
            
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(AppColors.background(isDark: themeManager.isDarkMode))
        .focusMode() // Aplicar modificador de modo de enfoque
        .onTapGesture {
            // Dismissar el teclado al tocar fuera de los campos
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Color.clear.edgesIgnoringSafeArea(.all)
            }
            .onDisappear {
                showingImagePicker = false
            }
        }
        .sheet(isPresented: $showingIconPicker) {
            SFSymbolIconPicker(selectedIcon: $selectedIcon, iconColor: $iconColor)
        }
        .onChange(of: selectedPhotoItem) { oldItem, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    self.photoData = data
                    // Si se selecciona una foto, limpiar el icono
                    self.selectedIcon = nil
                }
                selectedPhotoItem = nil
            }
        }
    }
    
    private func addExercise() {
        // Convertir strings a números con valores por defecto
        let reps = Int(repetitions) ?? 0
        let exerciseWeight = Double(weight) ?? 0.0
        
        // Añadir el ejercicio a todos los días seleccionados con iconos SF Symbols
        let workoutDays = Set(selectedDays.compactMap { day in
            WorkoutDay.allCases.first(where: { $0.rawValue == day })
        })
        
        viewModel.addExercise(
            name: name,
            reps: reps,
            weight: exerciseWeight,
            sets: totalSets,
            info: info,
            imageData: photoData,
            restDuration: timerMinutes * 60 + timerSeconds,
            toDays: workoutDays,
            sfSymbolIcon: selectedIcon,
            iconColor: iconColor
        )
        
        // Limpiar formulario
        name = ""
        info = ""
        repetitions = ""
        weight = ""
        totalSets = 4
        selectedDays = []
        timerMinutes = 2
        timerSeconds = 0
        photoData = nil
        selectedIcon = nil
        iconColor = "blue"
        
        // Haptic feedback de éxito
        HapticManager.shared.successOccurred()
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
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "teal": return .teal
        default: return .blue
        }
    }
}
