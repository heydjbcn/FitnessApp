//
//  ExerciseManagementView.swift
//  FitnessApp
//
//  Created by Assistant on 17/7/25.
//

import SwiftUI
import PhotosUI
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
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
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
                AddExerciseForm(exerciseToEdit: nil)  // nil significa que estamos añadiendo
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
                // Navegación entre pestañas
                HStack(spacing: 0) {
                    // Pestaña Ejercicios (activa)
                    Button(action: {
                        selectedTab = 0
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.primary(themeManager: themeManager))
                            Text("Ejercicios")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.primary(themeManager: themeManager))
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
                                .foregroundColor(AppColors.primary(themeManager: themeManager))
                            Text("Añadir")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.primary(themeManager: themeManager))
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
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
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
                                    .background(AppColors.primary(themeManager: themeManager))
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
            NavigationView {
                AddExerciseForm(exerciseToEdit: exercise)  // Pasamos el ejercicio para editar
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                    .navigationTitle("Editar Ejercicio")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancelar") {
                                showingEditSheet = false
                            }
                        }
                    }
            }
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

struct AddExerciseForm: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    // Ejercicio opcional para editar (nil significa que estamos añadiendo)
    let exerciseToEdit: Exercise?
    
    // Campos básicos
    @State private var selectedDays: Set<String> = []
    @State private var exerciseName: String = ""
    @State private var exerciseDescription: String = ""
    @State private var selectedIcon: String = "dumbbell.fill"
    @State private var iconColor: Color = .blue
    @State private var selectedImageData: Data?
    
    // Campos opcionales con checkboxes
    @State private var includeRepetitions: Bool = false
    @State private var repetitions: String = ""
    
    @State private var includeWeight: Bool = false
    @State private var weight: String = ""
    
    @State private var includeTotalSets: Bool = false
    @State private var totalSets: String = ""
    
    @State private var includeSeconds: Bool = false
    @State private var seconds: String = ""
    
    @State private var includeRIR: Bool = false
    @State private var rir: String = ""
    
    // Timer
    @State private var timerMinutes: Int = 2
    @State private var timerSeconds: Int = 0
    
    // Estados para UI
    @State private var showingIconPicker = false
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]
    
    // Inicializadores
    init(exerciseToEdit: Exercise? = nil) {
        self.exerciseToEdit = exerciseToEdit
    }
    
    var isEditing: Bool {
        exerciseToEdit != nil
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                daySelector
                exerciseNameSection
                exerciseDescriptionSection
                iconAndPhotoSection
                optionalFieldsSection
                timerSection
                saveButtonSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(AppColors.background(isDark: themeManager.isDarkMode))
        .navigationBarHidden(true)
        .onAppear {
            if let exercise = exerciseToEdit {
                loadExerciseData(exercise)
            }
        }
        .sheet(isPresented: $showingIconPicker) {
            SFSymbolIconPicker(selectedIcon: Binding<String?>(
                get: { selectedIcon.isEmpty ? nil : selectedIcon },
                set: { selectedIcon = $0 != nil ? $0! : "dumbbell.fill" }
            ), iconColor: Binding<String>(
                get: { iconColor.toHexString() },
                set: { iconColor = Color.fromHexString($0) }
            ))
        }
        .sheet(isPresented: $showingImagePicker) {
            if #available(iOS 16.0, *) {
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Seleccionar Foto")
                }
                .presentationDetents([.medium])
            }
        }
        .onChange(of: selectedPhotoItem) { oldItem, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
                selectedPhotoItem = nil
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Secciones del Formulario
    
    private var daySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
                Text("Días de la Semana")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                Text("*")
                    .foregroundColor(.red)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    Button(action: {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    }) {
                        let isSelected = selectedDays.contains(day)
                        let textColor = isSelected ? .white : AppColors.textPrimary(isDark: themeManager.isDarkMode)
                        let bgColor = isSelected ? AppColors.primary(themeManager: themeManager) : AppColors.cardBackground(isDark: themeManager.isDarkMode)
                        
                        Text(dayShortName(day))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(bgColor)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? AppColors.primary(themeManager: themeManager) : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    private var exerciseNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
                Text("Nombre del Ejercicio")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                Text("*")
                    .foregroundColor(.red)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            TextField("Ej. Sentadillas, Press de Banca...", text: $exerciseName)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.background(isDark: themeManager.isDarkMode))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    private var exerciseDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
                Text("Descripción del Ejercicio")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            }
            
            TextField("Describe cómo realizar el ejercicio...", text: $exerciseDescription, axis: .vertical)
                .lineLimit(3...6)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.background(isDark: themeManager.isDarkMode))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    private var iconAndPhotoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
                Text("Icono y Foto del Ejercicio")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            }
            
            HStack(spacing: 20) {
                // Selector de icono
                Button(action: { showingIconPicker = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: selectedIcon)
                            .font(.title)
                            .foregroundColor(iconColor)
                            .frame(width: 80, height: 80)
                            .background(AppColors.background(isDark: themeManager.isDarkMode))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("Seleccionar Icono")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                }
                
                // Selector de foto
                Button(action: { showingImagePicker = true }) {
                    VStack(spacing: 8) {
                        if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .cornerRadius(12)
                                .clipped()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                                .frame(width: 80, height: 80)
                                .background(AppColors.background(isDark: themeManager.isDarkMode))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Text("Seleccionar Foto")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    private var optionalFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
                Text("Campos Opcionales")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            }
            
            VStack(spacing: 16) {
                // Repeticiones
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(action: {
                            includeRepetitions.toggle()
                            if !includeRepetitions {
                                repetitions = ""
                            }
                        }) {
                            Image(systemName: includeRepetitions ? "checkmark.square.fill" : "square")
                                .foregroundColor(includeRepetitions ? .green : .gray)
                                .font(.system(size: 20))
                        }
                        
                        Text("Repeticiones")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        Spacer()
                    }
                    
                    if includeRepetitions {
                        TextField("Ej. 12, 10-15...", text: $repetitions)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.background(isDark: themeManager.isDarkMode))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    }
                }
                
                // Peso
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(action: {
                            includeWeight.toggle()
                            if !includeWeight {
                                weight = ""
                            }
                        }) {
                            Image(systemName: includeWeight ? "checkmark.square.fill" : "square")
                                .foregroundColor(includeWeight ? .green : .gray)
                                .font(.system(size: 20))
                        }
                        
                        Text("Peso")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        Spacer()
                    }
                    
                    if includeWeight {
                        TextField("Ej. 50kg, 20-25kg...", text: $weight)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.background(isDark: themeManager.isDarkMode))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    }
                }
                
                // Total de series
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(action: {
                            includeTotalSets.toggle()
                            if !includeTotalSets {
                                totalSets = ""
                            }
                        }) {
                            Image(systemName: includeTotalSets ? "checkmark.square.fill" : "square")
                                .foregroundColor(includeTotalSets ? .green : .gray)
                                .font(.system(size: 20))
                        }
                        
                        Text("Total de Series")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        Spacer()
                    }
                    
                    if includeTotalSets {
                        TextField("Ej. 4, 3-5...", text: $totalSets)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.background(isDark: themeManager.isDarkMode))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    }
                }
                
                // Segundos
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(action: {
                            includeSeconds.toggle()
                            if !includeSeconds {
                                seconds = ""
                            }
                        }) {
                            Image(systemName: includeSeconds ? "checkmark.square.fill" : "square")
                                .foregroundColor(includeSeconds ? .green : .gray)
                                .font(.system(size: 20))
                        }
                        
                        Text("Segundos")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        Spacer()
                    }
                    
                    if includeSeconds {
                        TextField("Ej. 60, 45-90...", text: $seconds)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.background(isDark: themeManager.isDarkMode))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    }
                }
                
                // RIR
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(action: {
                            includeRIR.toggle()
                            if !includeRIR {
                                rir = ""
                            }
                        }) {
                            Image(systemName: includeRIR ? "checkmark.square.fill" : "square")
                                .foregroundColor(includeRIR ? .green : .gray)
                                .font(.system(size: 20))
                        }
                        
                        Text("RIR (Repeticiones en Reserva)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        Spacer()
                    }
                    
                    if includeRIR {
                        TextField("Ej. 2, 1-3...", text: $rir)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.background(isDark: themeManager.isDarkMode))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    private var timerSection: some View {
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
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    
                    Picker("Minutos", selection: $timerMinutes) {
                        ForEach(0...10, id: \.self) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80, height: 100)
                    .clipped()
                }
                
                Text(":")
                    .font(.title2)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                // Segundos
                VStack {
                    Text("Segundos")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    
                    Picker("Segundos", selection: $timerSeconds) {
                        ForEach(Array(stride(from: 0, through: 59, by: 15)), id: \.self) { second in
                            Text(String(format: "%02d", second)).tag(second)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80, height: 100)
                    .clipped()
                }
                
                Spacer()
                
                // Preview del tiempo
                VStack {
                    Text("Tiempo")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    
                    Text(String(format: "%02d:%02d", timerMinutes, timerSeconds))
                        .font(.title2.bold())
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.background(isDark: themeManager.isDarkMode))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    private var saveButtonSection: some View {
        VStack(spacing: 16) {
            // Botón principal (Guardar/Añadir)
            Button(action: saveExercise) {
                HStack {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 18))
                    Text(isEditing ? "Guardar Cambios" : "Añadir Ejercicio")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1.0 : 0.6)
            }
            
            // Botón de eliminar (solo cuando editamos)
            if isEditing {
                Button(action: deleteExercise) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                        Text("Eliminar Ejercicio")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, .red.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private var isFormValid: Bool {
        !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedDays.isEmpty
    }
    
    private func saveExercise() {
        // Convert string fields to appropriate types for Exercise model
        let repsValue = Int(repetitions.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let weightValue = Double(weight.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
        let setsValue = Int(totalSets.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 4
        let secondsValue = Int(seconds.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let rirValue = Int(rir.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let restTime = (timerMinutes * 60) + timerSeconds
        
        if let existingExercise = exerciseToEdit {
            // Estamos editando un ejercicio existente
            let updatedExercise = Exercise(
                id: existingExercise.id, // Mantener el mismo ID
                name: exerciseName.trimmingCharacters(in: .whitespacesAndNewlines),
                repetitions: repsValue,
                weight: weightValue,
                totalSets: setsValue,
                info: exerciseDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                imageData: selectedImageData,
                restDuration: restTime,
                sfSymbolIcon: selectedIcon.isEmpty ? nil : selectedIcon,
                iconColor: iconColor.toHexString(),
                segundos: secondsValue,
                rir: rirValue,
                personalRecordWeight: existingExercise.personalRecordWeight // Mantener el record existente
            )
            
            // Actualizar el ejercicio en todos los días donde aparece
            updateExerciseInAllDays(originalExercise: existingExercise, updatedExercise: updatedExercise, newSelectedDays: selectedDays)
        } else {
            // Estamos creando un nuevo ejercicio
            let newExercise = Exercise(
                id: UUID(),
                name: exerciseName.trimmingCharacters(in: .whitespacesAndNewlines),
                repetitions: repsValue,
                weight: weightValue,
                totalSets: setsValue,
                info: exerciseDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                imageData: selectedImageData,
                restDuration: restTime,
                sfSymbolIcon: selectedIcon.isEmpty ? nil : selectedIcon,
                iconColor: iconColor.toHexString(),
                segundos: secondsValue,
                rir: rirValue,
                personalRecordWeight: nil
            )
            
            // Add exercise to all selected days
            for dayString in selectedDays {
                if let workoutDay = WorkoutDay.allCases.first(where: { $0.rawValue == dayString }) {
                    viewModel.addExercise(newExercise, to: workoutDay)
                }
            }
        }
        
        HapticManager.shared.success()
        
        // Clear form only if we're adding (not editing)
        if exerciseToEdit == nil {
            clearForm()
        } else {
            dismiss() // Close the edit view
        }
    }
    
    private func loadExerciseData(_ exercise: Exercise) {
        exerciseName = exercise.name
        exerciseDescription = exercise.info
        selectedIcon = exercise.sfSymbolIcon ?? "dumbbell.fill"
        iconColor = Color.fromHexString(exercise.iconColor)
        selectedImageData = exercise.imageData
        
        // Cargar campos opcionales
        if exercise.repetitions > 0 {
            includeRepetitions = true
            repetitions = String(exercise.repetitions)
        }
        
        if exercise.weight > 0 {
            includeWeight = true
            weight = String(exercise.weight)
        }
        
        if exercise.totalSets > 0 {
            includeTotalSets = true
            totalSets = String(exercise.totalSets)
        }
        
        if exercise.segundos > 0 {
            includeSeconds = true
            seconds = String(exercise.segundos)
        }
        
        if exercise.rir > 0 {
            includeRIR = true
            rir = String(exercise.rir)
        }
        
        // Cargar timer
        timerMinutes = exercise.restDuration / 60
        timerSeconds = exercise.restDuration % 60
        
        // Cargar días donde está presente este ejercicio
        loadExerciseDays(for: exercise)
    }
    
    private func loadExerciseDays(for exercise: Exercise) {
        selectedDays = Set()
        for (day, records) in viewModel.dailyWorkoutRecords {
            if records.contains(where: { $0.exerciseId == exercise.id }) {
                selectedDays.insert(day.rawValue)
            }
        }
    }
    
    private func updateExerciseInAllDays(originalExercise: Exercise, updatedExercise: Exercise, newSelectedDays: Set<String>) {
        // Obtener días actuales donde está el ejercicio
        let currentDays = Set(viewModel.dailyWorkoutRecords.compactMap { (day, records) in
            records.contains(where: { $0.exerciseId == originalExercise.id }) ? day.rawValue : nil
        })
        
        let newWorkoutDays = Set(newSelectedDays.compactMap { dayString in
            WorkoutDay.allCases.first(where: { $0.rawValue == dayString })?.rawValue
        })
        
        // Actualizar ejercicio en días que permanecen
        for dayString in currentDays.intersection(newWorkoutDays) {
            if let workoutDay = WorkoutDay.allCases.first(where: { $0.rawValue == dayString }) {
                viewModel.updateExercise(updatedExercise, in: workoutDay)
            }
        }
        
        // Eliminar de días que ya no están seleccionados
        for dayString in currentDays.subtracting(newWorkoutDays) {
            if let workoutDay = WorkoutDay.allCases.first(where: { $0.rawValue == dayString }) {
                if let records = viewModel.dailyWorkoutRecords[workoutDay] {
                    if let recordToRemove = records.first(where: { $0.exerciseId == originalExercise.id }) {
                        viewModel.removeExercise(recordId: recordToRemove.id, from: workoutDay)
                    }
                }
            }
        }
        
        // Añadir a días nuevos
        for dayString in newWorkoutDays.subtracting(currentDays) {
            if let workoutDay = WorkoutDay.allCases.first(where: { $0.rawValue == dayString }) {
                viewModel.addExercise(updatedExercise, to: workoutDay)
            }
        }
    }
    
    private func deleteExercise() {
        guard let exercise = exerciseToEdit else { return }
        
        print("🗑️ Iniciando borrado del ejercicio: \(exercise.name)")
        
        // 1. Eliminar el ejercicio de la lista principal de ejercicios disponibles
        viewModel.availableExercises.removeAll { $0.id == exercise.id }
        print("✅ Ejercicio eliminado de availableExercises")
        
        // 2. Eliminar el ejercicio de todos los días donde aparece
        for (day, records) in viewModel.dailyWorkoutRecords {
            if let recordToRemove = records.first(where: { $0.exerciseId == exercise.id }) {
                viewModel.removeExercise(recordId: recordToRemove.id, from: day)
                print("✅ Ejercicio eliminado del día: \(day.rawValue)")
            }
        }
        
        // 3. Eliminar historial del ejercicio
        for (date, dayHistory) in viewModel.workoutHistory {
            var updatedDayHistory = dayHistory
            var hasChanges = false
            
            for (day, exercises) in dayHistory {
                let filteredExercises = exercises.filter { $0.exerciseId != exercise.id }
                if filteredExercises.count != exercises.count {
                    updatedDayHistory[day] = filteredExercises
                    hasChanges = true
                }
            }
            
            if hasChanges {
                if updatedDayHistory.values.allSatisfy({ $0.isEmpty }) {
                    // Si no quedan ejercicios para esa fecha, eliminar la entrada completa
                    viewModel.workoutHistory.removeValue(forKey: date)
                } else {
                    // Actualizar con los ejercicios filtrados
                    viewModel.workoutHistory[date] = updatedDayHistory
                }
            }
        }
        print("✅ Historial del ejercicio eliminado")
        
        // Los datos se guardan automáticamente a través de los métodos del viewModel
        print("✅ Datos guardados - Ejercicio '\(exercise.name)' eliminado completamente")
        
        HapticManager.shared.success()
        dismiss()
    }
    
    private func clearForm() {
        exerciseName = ""
        exerciseDescription = ""
        selectedDays.removeAll()
        selectedImageData = nil
        selectedIcon = "dumbbell.fill"
        iconColor = .blue
        
        // Clear optional fields
        includeRepetitions = false
        repetitions = ""
        includeWeight = false
        weight = ""
        includeTotalSets = false
        totalSets = ""
        includeSeconds = false
        seconds = ""
        includeRIR = false
        rir = ""
        
        // Reset timer
        timerMinutes = 2
        timerSeconds = 0
    }
    
    private func dayShortName(_ day: String) -> String {
        switch day {
        case "Lunes": return "L"
        case "Martes": return "M"
        case "Miércoles": return "M"
        case "Jueves": return "J"
        case "Viernes": return "V"
        case "Sábado": return "S"
        case "Domingo": return "D"
        default: return "?"
        }
    }
}

// MARK: - Extensions

extension Color {
    func toHexString() -> String {
        switch self {
        case .red: return "red"
        case .green: return "green"
        case .blue: return "blue"
        case .orange: return "orange"
        case .purple: return "purple"
        case .pink: return "pink"
        case .yellow: return "yellow"
        case .cyan: return "cyan"
        case .indigo: return "indigo"
        case .teal: return "teal"
        default: return "blue"
        }
    }
    
    static func fromHexString(_ hex: String) -> Color {
        switch hex {
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
    
    // MARK: - Helper Functions
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
