//
//  ExerciseLibraryView.swift
//  FitnessApp
//
//  Vista principal para mostrar y gestionar ejercicios de Firebase
//

import SwiftUI

struct ExerciseLibraryView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String = "Todos"
    @State private var showingAddExercise = false
    @State private var exerciseToEdit: Exercise?
    @State private var isRefreshing = false
    
    // Lista de grupos musculares para el filtro - basado en Firebase
    private let muscleGroups = [
        "Todos", "Chest", "Back", "Shoulders", "Arms", "Legs", "Core", "Cardio"
    ]
    
    // Ejercicios filtrados
    private var filteredExercises: [Exercise] {
        var exercises = workoutViewModel.availableExercises
        
        // Filtrar por búsqueda
        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.targetMuscle.localizedCaseInsensitiveContains(searchText) ||
                exercise.info.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filtrar por grupo muscular
        if selectedMuscleGroup != "Todos" {
            exercises = exercises.filter { exercise in
                // Buscar coincidencia exacta en targetMuscle
                exercise.targetMuscle == selectedMuscleGroup
            }
        }
        
        return exercises.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header con búsqueda y filtros
                headerSection
                
                // Lista de ejercicios
                exerciseListSection
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle("Ejercicios")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddExercise = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColors.accentRed)
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        refreshExercises()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppColors.accentRed)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                NavigationView {
                    ExerciseFormView()
                        .environmentObject(workoutViewModel)
                        .environmentObject(themeManager)
                }
            }
            .sheet(item: $exerciseToEdit) { exercise in
                NavigationView {
                    ExerciseFormView(exercise: exercise)
                        .environmentObject(workoutViewModel)
                        .environmentObject(themeManager)
                }
            }
        }
        .task {
            await loadExercises()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Barra de búsqueda
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Buscar ejercicios...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.backgroundCard)
            .cornerRadius(12)
            
            // Filtro de grupos musculares
            VStack(alignment: .leading, spacing: 8) {
                Text("Filtrar por grupo muscular:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(muscleGroups, id: \.self) { group in
                            FilterChip(
                                title: group,
                                isSelected: selectedMuscleGroup == group
                            ) {
                                selectedMuscleGroup = group
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Contador de ejercicios
            HStack {
                Text("\(filteredExercises.count) ejercicios")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if workoutViewModel.isLoadingFirebaseExercises {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Cargando...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(AppColors.backgroundPrimary)
    }
    
    // MARK: - Exercise List Section
    
    private var exerciseListSection: some View {
        Group {
            if workoutViewModel.isLoadingFirebaseExercises && workoutViewModel.availableExercises.isEmpty {
                loadingView
            } else if filteredExercises.isEmpty && !workoutViewModel.isLoadingFirebaseExercises {
                emptyStateView
            } else {
                exerciseGridView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Cargando ejercicios desde Firebase...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Por favor espera mientras cargamos los 157 ejercicios")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            if searchText.isEmpty && selectedMuscleGroup == "Todos" {
                VStack(spacing: 12) {
                    Text("No hay ejercicios disponibles")
                        .font(.title2)
                        .bold()
                    
                    Text("Parece que aún no se han cargado los ejercicios de Firebase")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showingAddExercise = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Añadir Ejercicio")
                        }
                        .padding()
                        .background(AppColors.accentRed)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text("No se encontraron ejercicios")
                        .font(.title2)
                        .bold()
                    
                    Text("Intenta cambiar los filtros o el término de búsqueda")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        searchText = ""
                        selectedMuscleGroup = "Todos"
                    } label: {
                        Text("Limpiar Filtros")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(AppColors.accentRed.opacity(0.1))
                            .foregroundColor(AppColors.accentRed)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
    }
    
    private var exerciseGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 1),
                spacing: 12
            ) {
                ForEach(filteredExercises) { exercise in
                    ExerciseLibraryCard(exercise: exercise) {
                        exerciseToEdit = exercise
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .refreshable {
            await refreshExercisesAsync()
        }
    }
    
    // MARK: - Actions
    
    private func loadExercises() async {
        // Ya no necesitamos cargar desde FirebaseService directamente
        // El WorkoutViewModel ya se encarga de esto
        print("📚 Ejercicios disponibles en ExerciseLibraryView: \(workoutViewModel.availableExercises.count)")
        
        // Debug: Mostrar algunos grupos musculares únicos que vienen de Firebase
        let uniqueMuscleGroups = Set(workoutViewModel.availableExercises.map { $0.targetMuscle }).sorted()
        print("🎯 Grupos musculares únicos en Firebase: \(uniqueMuscleGroups)")
    }
    
    private func refreshExercises() {
        isRefreshing = true
        workoutViewModel.refreshExercisesFromFirebase()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRefreshing = false
        }
    }
    
    private func refreshExercisesAsync() async {
        await workoutViewModel.loadExercisesFromFirebase()
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppColors.accentRed : AppColors.backgroundCard)
            )
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.accentRed : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ExerciseLibraryCard: View {
    let exercise: Exercise
    let onEdit: () -> Void
    @State private var showingInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header con nombre y botones
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Botones de acción
                HStack(spacing: 12) {
                    // Botón de información
                    Button(action: { showingInfo = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            Text("Info")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.accentRed.opacity(0.1))
                        .foregroundColor(AppColors.accentRed)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    // Botón de editar
                    Button(action: onEdit) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.caption)
                            Text("Editar")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.accentRed.opacity(0.1))
                        .foregroundColor(AppColors.accentRed)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Información del ejercicio (SOLO datos de Firebase)
            VStack(alignment: .leading, spacing: 8) {
                // Grupo muscular
                if !exercise.targetMuscle.isEmpty {
                    HStack {
                        Image(systemName: "figure.strengthtraining.functional")
                            .foregroundColor(AppColors.accentRed)
                            .frame(width: 16)
                        
                        Text("Grupo: \(exercise.targetMuscle)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                
                // Tipo de ejercicio (Peso libre vs Máquina)
                HStack {
                    Image(systemName: exercise.isBodyWeight ? "figure.mind.and.body" : "dumbbell")
                        .foregroundColor(AppColors.accentRed)
                        .frame(width: 16)
                    
                    Text("Tipo: \(exerciseTypeText)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(16)
        .background(AppColors.backgroundCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingInfo) {
            ExerciseLibraryInfoSheet(exercise: exercise)
        }
    }
    
    private var exerciseTypeText: String {
        if exercise.isBodyWeight {
            return "Peso Corporal"
        } else {
            // Aquí puedes agregar lógica adicional para distinguir entre máquina y peso libre
            // Por ahora, usaremos información general
            return "Peso Libre / Máquina"
        }
    }
}

// MARK: - Exercise Info Sheet

struct ExerciseLibraryInfoSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header con nombre
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        if !exercise.targetMuscle.isEmpty {
                            Text(exercise.targetMuscle)
                                .font(.headline)
                                .foregroundColor(AppColors.accentRed)
                        }
                    }
                    
                    Divider()
                    
                    // Información básica
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(title: "Tipo", value: exercise.isBodyWeight ? "Peso Corporal" : "Peso Libre / Máquina", icon: "dumbbell")
                        InfoRow(title: "Categoría", value: exercise.category.displayName, icon: "tag")
                        
                        if exercise.totalSets > 0 {
                            InfoRow(title: "Series por defecto", value: "\(exercise.totalSets)", icon: "repeat")
                        }
                        
                        if exercise.repetitions > 0 {
                            InfoRow(title: "Repeticiones por defecto", value: "\(exercise.repetitions)", icon: "number")
                        }
                        
                        if exercise.weight > 0 {
                            InfoRow(title: "Peso por defecto", value: "\(String(format: "%.1f", exercise.weight)) kg", icon: "scalemass")
                        }
                        
                        if exercise.restDuration > 0 {
                            let minutes = exercise.restDuration / 60
                            let seconds = exercise.restDuration % 60
                            InfoRow(title: "Descanso", value: "\(minutes)m \(seconds)s", icon: "timer")
                        }
                    }
                    
                    // Descripción
                    if !exercise.info.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Descripción")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(exercise.info)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Instrucciones
                    if !exercise.instructions.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instrucciones")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(exercise.instructions)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle("Información del Ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentRed)
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.accentRed)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

struct ExerciseInfoPill: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppColors.backgroundPrimary)
        .cornerRadius(6)
    }
}

#Preview {
    ExerciseLibraryView()
        .environmentObject(WorkoutViewModel())
        .environmentObject(ThemeManager())
}
