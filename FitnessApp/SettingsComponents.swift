//
//  SettingsComponents.swift
//  FitnessApp
//
//  Consolidated settings components: SettingsDayView, SettingsHeaderView, ProgramSettingsView
//  Created by merging multiple settings-related components for better organization
//

import SwiftUI
import PhotosUI

// MARK: - Settings Header Component

struct SettingsHeaderView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar del usuario
            ZStack {
                Circle()
                    .fill(AppColors.primary(themeManager: themeManager).opacity(0.1))
                    .frame(width: 60, height: 60)
                
                if let profileImageData = userManager.profileImageData,
                   let profileImage = UIImage(data: profileImageData) {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Hola, \(userManager.userName.isEmpty ? "Usuario" : userManager.userName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text("Configuración de la app")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
    }
}

// MARK: - Exercise Day Configuration Component

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

    var isFormValid: Bool {
        !machineName.isEmpty && !repetitions.isEmpty && !weight.isEmpty && !sets.isEmpty && !selectedDays.isEmpty
    }

    // Helper function para evitar problemas de @MainActor
    private func getPrimaryColor() -> Color {
        return themeManager.selectedAccentColor.color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            HStack(spacing: 8) {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(getPrimaryColor())
                Text("Máquina")
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            }
            .font(AppFonts.subtitle)
            
            TextField("Ej: Press banca", text: $machineName)
                .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                .focused($focusedField, equals: .machine)
                .onSubmit { focusedField = .reps }
            
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "repeat")
                            .foregroundColor(getPrimaryColor())
                        Text("Repeticiones")
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    }
                    .font(AppFonts.subtitle)
                    
                    TextField("12", text: $repetitions)
                        .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .reps)
                        .onSubmit { focusedField = .weight }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "scalemass")
                            .foregroundColor(getPrimaryColor())
                        Text("Peso (kg)")
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    }
                    .font(AppFonts.subtitle)
                    
                    TextField("50", text: $weight)
                        .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .onSubmit { focusedField = .sets }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .foregroundColor(getPrimaryColor())
                    Text("Series")
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                .font(AppFonts.subtitle)
                
                TextField("4", text: $sets)
                    .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .sets)
            }
            
            // Day Selection
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(getPrimaryColor())
                    Text("Días de entrenamiento")
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                .font(AppFonts.subtitle)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                    ForEach(WorkoutDay.allCases, id: \.self) { day in
                        DaySelectionCard(
                            day: day,
                            isSelected: selectedDays.contains(day),
                            themeManager: themeManager
                        ) {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }
                    }
                }
            }
            
            // Photo Selection
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "photo")
                        .foregroundColor(getPrimaryColor())
                    Text("Imagen (opcional)")
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                .font(AppFonts.subtitle)
                
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    photoSelectionButton
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            photoData = data
                        }
                    }
                }
            }
            
            // Info Text
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(getPrimaryColor())
                    Text("Información adicional")
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                .font(AppFonts.subtitle)
                
                TextField("Notas sobre el ejercicio...", text: $infoText, axis: .vertical)
                    .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                    .lineLimit(3...6)
            }
            
            // Add Button
            Button(action: addExercise) {
                addExerciseButton
            }
            .disabled(!isFormValid)
            .animation(.easeInOut(duration: 0.2), value: isFormValid)
        }
        .padding(20)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .onTapGesture {
            focusedField = nil
        }
    }
    
    // MARK: - Extracted Views for Complex Expressions
    
    private var photoSelectionButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getPrimaryColor().opacity(0.3), lineWidth: 1)
                )
            
            if let photoData = photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipped()
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(getPrimaryColor())
                    Text("Agregar imagen")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
            }
        }
    }
    
    private var addExerciseButton: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
            Text("Agregar ejercicio")
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(addExerciseButtonBackground)
        .cornerRadius(12)
    }
    
    private var addExerciseButtonBackground: LinearGradient {
        if isFormValid {
            return LinearGradient(
                colors: [getPrimaryColor(), getPrimaryColor().opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color.gray, Color.gray.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private func addExercise() {
        guard isFormValid,
              let repsInt = Int(repetitions),
              let weightDouble = Double(weight),
              let setsInt = Int(sets) else { return }
        
        // CORREGIDO: Crear exercise directamente sin usar método inexistente
        let exercise = Exercise(
            id: UUID(),
            name: machineName,
            repetitions: repsInt,
            weight: weightDouble,
            totalSets: setsInt,
            info: infoText,
            imageData: photoData,
            restDuration: 60,
            sfSymbolIcon: "dumbbell.fill",
            iconColor: "blue",
            segundos: 0,
            rir: 0
        )
        
        // Añadir a ejercicios disponibles
        viewModel.availableExercises.append(exercise)
        
        // Añadir a días seleccionados
        for day in selectedDays {
            let workoutRecord = WorkoutExercise(from: exercise)
            viewModel.dailyWorkoutRecords[day]?.append(workoutRecord)
        }
        
        // Reset form
        machineName = ""
        repetitions = ""
        weight = ""
        sets = "4"
        infoText = ""
        photoData = nil
        selectedPhotoItem = nil
        selectedDays.removeAll()
        focusedField = .machine
    }
}

// MARK: - Day Selection Card

struct DaySelectionCard: View {
    let day: WorkoutDay
    let isSelected: Bool
    let themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: day.iconName)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : AppColors.primary(themeManager: themeManager))
                
                Text(day.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Spacer()
            }
            .padding(12)
            .background(cardBackground)
            .overlay(cardOverlay)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cardBackground: Color {
        if isSelected {
            return AppColors.primary(themeManager: themeManager)
        } else {
            return AppColors.cardBackground(isDark: themeManager.isDarkMode)
        }
    }
    
    private var cardOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(strokeColor, lineWidth: 1)
    }
    
    private var strokeColor: Color {
        if isSelected {
            return AppColors.primary(themeManager: themeManager)
        } else {
            return AppColors.primary(themeManager: themeManager).opacity(0.3)
        }
    }
}

// MARK: - Program Settings View

struct ProgramSettingsView: View {
    let mainSelectedTab: Binding<Int>?
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var showingNotifications = false
    @Environment(\.dismiss) private var dismiss
    
    init(mainSelectedTab: Binding<Int>? = nil) {
        self.mainSelectedTab = mainSelectedTab
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation only
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    
                    Button {
                        showingNotifications = true
                    } label: {
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                    }
                    
                    Spacer().frame(width: 16)
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                    }
                }
                .padding(.bottom, 10)
            }
            .background(AppColors.background(isDark: themeManager.isDarkMode))
            
            // Contenido principal
            ZStack {
                AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header del usuario
                        SettingsHeaderView()
                        
                        // Modo Día/Noche
                        SettingsOptionCard(
                            icon: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill",
                            title: "Modo de visualización",
                            subtitle: themeManager.isDarkMode ? "Modo oscuro activado" : "Modo claro activado",
                            themeManager: themeManager
                        ) {
                            Toggle("", isOn: $themeManager.isDarkMode)
                                .labelsHidden()
                                .tint(AppColors.primary(themeManager: themeManager))
                        }
                        
                        // Color de acento
                        SettingsColorCard(themeManager: themeManager)
                        
                        // Timer
                        SettingsTimerCard(viewModel: viewModel, themeManager: themeManager)
                        
                        // Usuario
                        SettingsUserCard(userManager: userManager, themeManager: themeManager)
                        
                        // Avanzado
                        SettingsAdvancedCard(
                            viewModel: viewModel,
                            themeManager: themeManager,
                            mainSelectedTab: mainSelectedTab
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
        }
    }
}

// MARK: - Settings Option Card

struct SettingsOptionCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let themeManager: ThemeManager
    let content: () -> Content
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.primary(themeManager: themeManager).opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            Spacer()
            
            content()
        }
        .padding(16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
}

// MARK: - Settings Color Card

struct SettingsColorCard: View {
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary(themeManager: themeManager).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "paintbrush.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Color de acento")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text("Personaliza el color principal")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Spacer()
            }
            
            // Paleta de colores
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(AccentColor.allCases, id: \.self) { color in
                    colorButton(for: color)
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    private func colorButton(for color: AccentColor) -> some View {
        Button {
            themeManager.selectedAccentColor = color
        } label: {
            Circle()
                .fill(color.color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: themeManager.selectedAccentColor == color ? 3 : 0)
                )
                .scaleEffect(themeManager.selectedAccentColor == color ? 1.2 : 1.0)
        }
        .animation(.spring(response: 0.3), value: themeManager.selectedAccentColor)
    }
}

// MARK: - Settings Timer Card

struct SettingsTimerCard: View {
    let viewModel: WorkoutViewModel
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary(themeManager: themeManager).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Timer de descanso")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text("Duración: \(Int(viewModel.restTime)) segundos")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(viewModel.isTimerEnabled))
                    .labelsHidden()
                    .tint(AppColors.primary(themeManager: themeManager))
            }
            
            if viewModel.isTimerEnabled {
                timerSlider
            }
        }
        .padding(16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    private var timerSlider: some View {
        Slider(
            value: Binding(
                get: { Double(Int(viewModel.restTime)) },
                set: { viewModel.updateRestDuration(Int($0)) }
            ),
            in: 30...300,
            step: 15
        ) {
            Text("Duración")
        } minimumValueLabel: {
            Text("30s")
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
        } maximumValueLabel: {
            Text("5m")
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
        }
        .tint(AppColors.primary(themeManager: themeManager))
    }
}

// MARK: - Settings User Card

struct SettingsUserCard: View {
    let userManager: UserManager
    let themeManager: ThemeManager
    
    var body: some View {
        NavigationLink {
            ProfileEditView()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary(themeManager: themeManager).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Perfil de usuario")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text("Editar información personal")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            .padding(16)
            .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Advanced Card

struct SettingsAdvancedCard: View {
    let viewModel: WorkoutViewModel
    let themeManager: ThemeManager
    let mainSelectedTab: Binding<Int>?
    
    var body: some View {
        VStack(spacing: 12) {
            // Exportar datos
            exportDataButton
            
            // Restablecer datos
            resetDataButton
        }
    }
    
    private var exportDataButton: some View {
        Button {
            // TODO: Implement data export
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Exportar datos")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Text("Crear backup de tus entrenamientos")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            .padding(16)
            .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var resetDataButton: some View {
        Button {
            // TODO: Implement data reset with confirmation
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Restablecer datos")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    
                    Text("Eliminar todos los datos de la app")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            .padding(16)
            .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ProgramSettingsView()
            .environmentObject(ThemeManager())
            .environmentObject(UserManager())
            .environmentObject(WorkoutViewModel())
    }
}
