//
//  SettingsDayView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import SwiftUI
import PhotosUI

struct SettingsDayView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var machineName: String = ""
    @State private var repetitions: String = ""
    @State private var weight: String = ""
    @State private var sets: String = "4"
    @State private var infoText: String = ""
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedDays: Set<WorkoutDay> = []
    @State private var isPhotoPickerPresented = false
    
    enum Field: Hashable {
        case machine, reps, weight, sets
    }
    @FocusState private var focusedField: Field?

    var isFormValid: Bool { !machineName.isEmpty && !repetitions.isEmpty && !weight.isEmpty && !sets.isEmpty && !selectedDays.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            HStack(spacing: 8) {
                Image(systemName: "dumbbell.fill").foregroundColor(AppColors.primary(themeManager: themeManager))
                Text("Máquina").foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            }.font(AppFonts.subtitle)
            TextField("Ej: Press banca", text: $machineName)
                .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                .focused($focusedField, equals: .machine)
                .addFocusGlow(isFocused: focusedField == .machine)

            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) { Image(systemName: "repeat").foregroundColor(AppColors.primary(themeManager: themeManager)); Text("Reps").foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode)) }.font(AppFonts.subtitle)
                    TextField("10", text: $repetitions)
                        .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode)).keyboardType(.numberPad)
                        .focused($focusedField, equals: .reps)
                        .addFocusGlow(isFocused: focusedField == .reps)
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) { Image(systemName: "scalemass").foregroundColor(AppColors.primary(themeManager: themeManager)); Text("Peso").foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode)) }.font(AppFonts.subtitle)
                    TextField("50.0", text: $weight)
                        .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode)).keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .addFocusGlow(isFocused: focusedField == .weight)
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) { Image(systemName: "number").foregroundColor(AppColors.primary(themeManager: themeManager)); Text("Series").foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode)) }.font(AppFonts.subtitle)
                    TextField("4", text: $sets)
                        .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode)).keyboardType(.numberPad)
                        .focused($focusedField, equals: .sets)
                        .addFocusGlow(isFocused: focusedField == .sets)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) { Image(systemName: "note.text").foregroundColor(AppColors.primary(themeManager: themeManager)); Text("Descripción / Notas").foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode)) }.font(AppFonts.subtitle)
                TextEditor(text: $infoText)
                    .frame(height: 100).padding(8).background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                    .cornerRadius(12).foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode)).scrollContentBackground(.hidden)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.primary(themeManager: themeManager).opacity(0.3), lineWidth: 1))
            }
            
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label(photoData == nil ? "Añadir Foto (Opcional)" : "Cambiar Foto", systemImage: "photo.fill")
                    .foregroundColor(themeManager.selectedAccentColor.color)
            }
            .disabled(isPhotoPickerPresented)
            .onChange(of: selectedPhotoItem) { _, newItem in 
                guard !isPhotoPickerPresented else { return }
                isPhotoPickerPresented = true
                Task { 
                    if let data = try? await newItem?.loadTransferable(type: Data.self) { 
                        await MainActor.run {
                            photoData = data
                            isPhotoPickerPresented = false
                        }
                    } else {
                        await MainActor.run {
                            isPhotoPickerPresented = false
                        }
                    }
                } 
            }
            
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage).resizable().scaledToFit().frame(maxHeight: 120)
                    .cornerRadius(10).shadow(radius: 5)
            }
            
            Divider().padding(.vertical, 10)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) { Image(systemName: "calendar.badge.plus").foregroundColor(AppColors.primary); Text("Añadir a los días:").foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode)) }.font(AppFonts.subtitle)
                HStack(spacing: 10) {
                    ForEach(WorkoutDay.allCases) { day in
                        Button(action: { toggleDaySelection(day) }) {
                            Text(day.rawValue.prefix(3).uppercased())
                                .font(.caption.weight(.bold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                                .foregroundColor(selectedDays.contains(day) ? .white : AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                .background(selectedDays.contains(day) ? AppColors.primary : AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                .cornerRadius(10).shadow(color: selectedDays.contains(day) ? AppColors.primary.opacity(0.6) : .clear, radius: 6, x: 0, y: 3)
                        }
                    }
                }
            }

            Button(action: addExerciseToSelectedDays) {
                Label("Añadir Ejercicio", systemImage: "plus.circle.fill")
                    .font(.title2.weight(.semibold)).foregroundColor(.black).frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(themeManager: themeManager)).padding(.top, 10).disabled(!isFormValid)
            .opacity(isFormValid ? 1.0 : 0.6).animation(.easeInOut, value: isFormValid)
        }
        .padding(.horizontal, 20)
    }

    private func toggleDaySelection(_ day: WorkoutDay) { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { if selectedDays.contains(day) { selectedDays.remove(day) } else { selectedDays.insert(day) } } }
    private func addExerciseToSelectedDays() { 
        guard let reps = Int(repetitions), let weightValue = Double(weight), let setsValue = Int(sets) else { return }
        viewModel.addExercise(name: machineName, reps: reps, weight: weightValue, sets: setsValue, info: infoText, imageData: photoData, restDuration: 120, toDays: selectedDays)
        clearForm() 
    }
    private func clearForm() { machineName = ""; repetitions = ""; weight = ""; infoText = ""; sets = "4"; selectedDays.removeAll(); photoData = nil; selectedPhotoItem = nil; UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
}
