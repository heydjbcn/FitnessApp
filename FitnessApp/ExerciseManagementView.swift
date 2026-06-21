//
//  ExerciseManagementView.swift - OPTIMIZADO Y CONSOLIDADO
//  FitnessApp
//

import SwiftUI

struct ExerciseManagementView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedTab: Tab = .exercises
    @State private var searchText = ""
    
    enum Tab: CaseIterable {
        case exercises, addExercise, debug
        
        var title: String {
            switch self {
            case .exercises: return "Ejercicios"
            case .addExercise: return "Añadir"
            case .debug: return "Debug"
            }
        }
        
        var icon: String {
            switch self {
            case .exercises: return "list.bullet"
            case .addExercise: return "plus.circle"
            case .debug: return "wrench"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            tabPicker
            
            // Content
            TabView(selection: $selectedTab) {
                exercisesView.tag(Tab.exercises)
                addExerciseView.tag(Tab.addExercise)
                debugView.tag(Tab.debug)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .background(AppColors.backgroundPrimary)
    }
    
    // MARK: - Tab Picker
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .medium))
                        
                        Text(tab.title)
                            .font(.caption.bold())
                    }
                    .foregroundColor(selectedTab == tab ? 
                                   AppColors.accentRed : 
                                   AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? 
                                 AppColors.accentRed.opacity(0.1) : 
                                 Color.clear)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppColors.backgroundCard)
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
    
    // MARK: - Exercises View
    private var exercisesView: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
            
            // Exercise List
            if filteredExercises.isEmpty {
                emptyStateView
            } else {
                exerciseList
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField("Buscar ejercicios...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(12)
        .background(AppColors.backgroundCard)
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var exerciseList: some View {
        List {
            ForEach(filteredExercises) { exercise in
                ExerciseRow(exercise: exercise)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteExercises)
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.loadFirebaseExercises()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 50))
                .foregroundColor(AppColors.textSecondary)
            
            VStack(spacing: 8) {
                Text("No hay ejercicios")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text("Añade ejercicios o cárgalos desde Firebase")
                    .font(.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Añadir Ejercicio") {
                    selectedTab = .addExercise
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accentRed)
                
                Button("Cargar desde Firebase") {
                    Task { await viewModel.loadFirebaseExercises() }
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Add Exercise View
    private var addExerciseView: some View {
        ExerciseFormView()
    }
    
    // MARK: - Debug View
    private var debugView: some View {
        DebugView()
    }
    
    // MARK: - Helper Views
    struct ExerciseRow: View {
        let exercise: Exercise
        @EnvironmentObject var themeManager: ThemeManager
        
        var body: some View {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: exercise.sfSymbolIcon ?? "dumbbell.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.accentRed)
                    .frame(width: 30)
                
                // Exercise Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text(exercise.targetMuscle)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack {
                        Text("\(exercise.repetitions) reps")
                        Text("•")
                        Text("\(exercise.totalSets) sets")
                        
                        if exercise.weight > 0 {
                            Text("•")
                            Text("\(String(format: "%.1f", exercise.weight)) kg")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Source Badge
                Text(exercise.isFromFirebase ? "🔥" : "📱")
                    .font(.caption)
            }
            .padding(12)
            .background(AppColors.backgroundCard)
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Helper Properties
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return viewModel.availableExercises
        } else {
            return viewModel.availableExercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.targetMuscle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func deleteExercises(offsets: IndexSet) {
        for index in offsets {
            let exercise = filteredExercises[index]
            Task {
                await viewModel.deleteExercise(exercise)
            }
        }
    }
}
