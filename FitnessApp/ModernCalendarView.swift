//
//  ModernCalendarView.swift - VERSIÓN SIMPLIFICADA PARA COMPILAR
//  FitnessApp
//

import SwiftUI

struct ModernCalendarView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @State private var selectedDay: WorkoutDay = getCurrentDay()
    @State private var showingExerciseDetail = false
    @State private var showingExerciseEdit = false
    @State private var selectedExercise: Exercise?
    var onNavigateToAddExercise: (() -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                ModernWeekSelector(selectedDay: $selectedDay)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let workoutRecords = viewModel.dailyWorkoutRecords[selectedDay], !workoutRecords.isEmpty {
                            // VERSIÓN SIMPLIFICADA - Sin bindings complejos
                            ForEach(workoutRecords.indices, id: \.self) { index in
                                let workoutRecord = workoutRecords[index]
                                if let exercise = viewModel.getExercise(by: workoutRecord.exerciseId) {
                                    SimpleExerciseCard(
                                        exercise: exercise,
                                        workoutRecord: workoutRecord,
                                        onInfoTap: {
                                            selectedExercise = exercise
                                            showingExerciseDetail = true
                                        },
                                        onEditTap: {
                                            selectedExercise = exercise
                                            showingExerciseEdit = true
                                        }
                                    )
                                }
                            }
                        } else {
                            EmptyWorkoutView(onAddExercise: onNavigateToAddExercise)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle(selectedDay.displayName)
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingExerciseDetail) {
            if let exercise = selectedExercise {
                ExerciseDetailView(exercise: exercise)
            }
        }
        .sheet(isPresented: $showingExerciseEdit) {
            if let exercise = selectedExercise {
                ExerciseFormView(exercise: exercise)
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
            }
        }
    }
}

// MARK: - Simple Exercise Card (Sin bindings complejos)
struct SimpleExerciseCard: View {
    let exercise: Exercise
    let workoutRecord: WorkoutExercise
    let onInfoTap: () -> Void
    let onEditTap: () -> Void
    @EnvironmentObject var viewModel: WorkoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        if exercise.weight > 0 {
                            Text("\(String(format: "%.1f", exercise.weight)) kg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(exercise.repetitions) reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Progress indicator
                Text("\(workoutRecord.completedSets)/\(workoutRecord.totalSets)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.accentRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.accentRed.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Sets display (simplificado)
            HStack(spacing: 8) {
                ForEach(0..<workoutRecord.totalSets, id: \.self) { setIndex in
                    Circle()
                        .fill(setIndex < workoutRecord.completedSets ? AppColors.accentRed : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
                
                Spacer()
                
                Button("Info", action: onInfoTap)
                    .font(.caption)
                    .foregroundColor(AppColors.accentRed)
                
                Button("Edit", action: onEditTap)
                    .font(.caption)
                    .foregroundColor(AppColors.accentRed)
            }
        }
        .padding(16)
        .background(AppColors.backgroundCard)
        .cornerRadius(12)
    }
}

// MARK: - Week Selector (Simplificado)
struct ModernWeekSelector: View {
    @Binding var selectedDay: WorkoutDay
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(WorkoutDay.allCases, id: \.self) { day in
                    Button(action: { selectedDay = day }) {
                        VStack(spacing: 4) {
                            Text(day.shortName)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(day.displayName)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedDay == day ? AppColors.accentRed : Color.clear)
                        .foregroundColor(selectedDay == day ? .white : .primary)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Empty State
struct EmptyWorkoutView: View {
    let onAddExercise: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No hay ejercicios para hoy")
                .font(.headline)
            
            Text("Añade ejercicios para comenzar tu entrenamiento")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let onAddExercise = onAddExercise {
                Button("Añadir Ejercicio", action: onAddExercise)
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.accentRed)
            }
        }
        .padding(40)
    }
}

// Helper function
private func getCurrentDay() -> WorkoutDay {
    return WorkoutDay.monday // Simplificado por ahora
}

// MARK: - Preview
#Preview {
    ModernCalendarView()
        .environmentObject(WorkoutViewModel())
        .environmentObject(ThemeManager())
        .environmentObject(UserManager())
}
