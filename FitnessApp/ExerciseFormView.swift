//
//  ExerciseFormView.swift
//  FitnessApp
//
//  Vista de formulario para añadir/editar ejercicios
//

import SwiftUI
import PhotosUI

@MainActor
struct ExerciseFormView: View {
    @StateObject private var formModel = ExerciseFormModel()
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @Environment(\.dismiss) private var dismiss
    
    let exerciseToEdit: Exercise?
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingIconPicker = false
    
    // Manejar la carga de la imagen de forma asíncrona
    private func handlePhotoSelection(item: PhotosPickerItem?) {
        Task {
            if let item = item,
               let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    formModel.imageData = data
                }
            }
        }
    }
    
    init(exercise: Exercise? = nil) {
        self.exerciseToEdit = exercise
    }
    
    var body: some View {
        Form {
            basicInfoSection
            muscleGroupSection
            workoutDaysSection
            exerciseParametersSection
            mediaSection
            restTimeSection
        }
        .background(AppColors.backgroundPrimary)
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancelar") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(formModel.isEditing ? "Guardar" : "Añadir") {
                    saveExercise()
                }
                .disabled(!formModel.isValid)
                .bold()
            }
        }
        .onAppear {
            if let exercise = exerciseToEdit {
                formModel.loadFromExercise(exercise)
            }
        }
    }
    
    private var basicInfoSection: some View {
        Section("Información Básica") {
            TextField("Nombre del ejercicio", text: $formModel.name)
                .textFieldStyle(.roundedBorder)
            
            TextField("Descripción", text: $formModel.description, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private var muscleGroupSection: some View {
        Section("Grupo Muscular y Tipo") {
            if !formModel.isEditing {
                Picker("Grupo Muscular", selection: $formModel.muscleGroup) {
                    ForEach(MuscleGroup.allCases) { group in
                        HStack {
                            Image(systemName: group.icon)
                                .foregroundColor(group.color)
                            Text(group.displayName)
                        }
                        .tag(group)
                    }
                }
                .pickerStyle(.menu)
            } else {
                HStack {
                    Image(systemName: formModel.muscleGroup.icon)
                        .foregroundColor(formModel.muscleGroup.color)
                    Text("Grupo: \(formModel.muscleGroup.displayName)")
                    Spacer()
                    Text("(No editable)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Picker("Tipo de Ejercicio", selection: $formModel.exerciseType) {
                ForEach(ExerciseType.allCases) { type in
                    HStack {
                        Image(systemName: type.icon)
                        Text(type.displayName)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var workoutDaysSection: some View {
        Section("Días de Entrenamiento") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(WorkoutDay.allCases, id: \.self) { day in
                    Button(action: {
                        if formModel.selectedDays.contains(day) {
                            formModel.selectedDays.remove(day)
                        } else {
                            formModel.selectedDays.insert(day)
                        }
                    }) {
                        HStack {
                            Image(systemName: formModel.selectedDays.contains(day) ? "checkmark.circle.fill" : "circle")
                            Text(day.displayName)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(formModel.selectedDays.contains(day) ? 
                                     AppColors.accentRed.opacity(0.1) : 
                                     AppColors.backgroundCard)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(formModel.selectedDays.contains(day) ? 
                                       AppColors.accentRed : 
                                       Color.clear, lineWidth: 1)
                        )
                    }
                    .foregroundColor(AppColors.textPrimary)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var exerciseParametersSection: some View {
        Section("Parámetros del Ejercicio") {
            VStack(spacing: 16) {
                // Series
                Toggle("Series", isOn: $formModel.hasSets)
                if formModel.hasSets {
                    HStack {
                        Text("Cantidad:")
                        Spacer()
                        Stepper("\(formModel.sets)", value: $formModel.sets, in: 1...20)
                    }
                    .padding(.leading, 20)
                }
                
                Divider()
                
                // Repeticiones
                Toggle("Repeticiones", isOn: $formModel.hasReps)
                if formModel.hasReps {
                    HStack {
                        Text("Cantidad:")
                        Spacer()
                        Stepper("\(formModel.reps)", value: $formModel.reps, in: 1...100)
                    }
                    .padding(.leading, 20)
                }
                
                Divider()
                
                // Peso
                Toggle("Peso", isOn: $formModel.hasWeight)
                if formModel.hasWeight {
                    HStack {
                        Text("Kg:")
                        Spacer()
                        TextField("0.0", value: $formModel.weight, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    .padding(.leading, 20)
                }
                
                Divider()
                
                // Tiempo
                Toggle("Tiempo (segundos)", isOn: $formModel.hasTime)
                if formModel.hasTime {
                    HStack {
                        Text("Segundos:")
                        Spacer()
                        Stepper("\(formModel.timeSeconds)", value: $formModel.timeSeconds, in: 0...3600, step: 5)
                    }
                    .padding(.leading, 20)
                }
                
                Divider()
                
                // RIR
                Toggle("RIR (Repeticiones en Reserva)", isOn: $formModel.hasRIR)
                if formModel.hasRIR {
                    HStack {
                        Text("RIR:")
                        Spacer()
                        Stepper("\(formModel.rir)", value: $formModel.rir, in: 0...10)
                    }
                    .padding(.leading, 20)
                }
            }
        }
    }
    
    private var mediaSection: some View {
        let hasImage = formModel.hasImage
        
        return Section("Icono y Media") {
            // Selector de icono
            Button(action: { showingIconPicker = true }) {
                HStack {
                    Image(systemName: formModel.selectedIcon)
                        .foregroundColor(formModel.iconColor)
                        .frame(width: 30, height: 30)
                    
                    Text("Cambiar Icono")
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(AppColors.textPrimary)
            
            // Selector de foto
            PhotoPickerView(
                selectedPhotoItem: $selectedPhotoItem,
                hasImage: hasImage,
                themeManager: themeManager,
                onPhotoSelected: handlePhotoSelection
            )
        }
    }

    private var restTimeSection: some View {
        Section("Tiempo de Descanso") {
            VStack(spacing: 12) {
                HStack {
                    Text("Entre series:")
                    Spacer()
                    Text("\(formModel.restTime / 60)m \(formModel.restTime % 60)s")
                        .foregroundColor(AppColors.accentRed)
                        .bold()
                }
                
                Slider(
                    value: Binding(
                        get: { Double(formModel.restTime) },
                        set: { formModel.restTime = Int($0) }
                    ),
                    in: 30...300,
                    step: 15
                )
                .accentColor(AppColors.accentRed)
                
                HStack {
                    Text("30s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("5min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func saveExercise() {
        let exercise = formModel.createExercise()
        
        if formModel.isEditing {
            // Actualizar ejercicio existente
            workoutViewModel.updateExercise(exercise)
        } else {
            // Crear nuevo ejercicio
            workoutViewModel.addExerciseBulk(exercise, toDays: Array(formModel.selectedDays))
        }
        
        dismiss()
    }
}

// Vista auxiliar para el selector de fotos que evita problemas de concurrencia
private struct PhotoPickerView: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let hasImage: Bool
    let themeManager: ThemeManager
    let onPhotoSelected: (PhotosPickerItem?) -> Void
    
    var body: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack {
                Image(systemName: "photo")
                    .frame(width: 30, height: 30)
                
                Text("Añadir Foto")
                
                Spacer()
                
                if hasImage {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
        }
        .foregroundColor(AppColors.textPrimary)
        .onChange(of: selectedPhotoItem) { _, newItem in
            onPhotoSelected(newItem)
        }
    }
}

#Preview {
    ExerciseFormView()
        .environmentObject(WorkoutViewModel())
        .environmentObject(ThemeManager())
}
