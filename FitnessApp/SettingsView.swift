import SwiftUI

enum SettingsTab: String, CaseIterable {
    case configuration = "Configuración"
    case addExercise = "Añadir Ejercicio"
    case exercises = "Ejercicios"
}

struct FocusModeSettingsCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var focusManager = FocusModeManager()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Modo de Enfoque")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mantener pantalla encendida")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        Text("Evita que la pantalla se apague durante entrenamientos")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                    Spacer()
                    Toggle("", isOn: $focusManager.keepScreenOn)
                        .tint(AppColors.primary(themeManager: themeManager))
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Modo de enfoque automático")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        Text("Activa automáticamente durante entrenamientos")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                    Spacer()
                    Toggle("", isOn: $focusManager.isActive)
                        .tint(AppColors.primary(themeManager: themeManager))
                }
                
                if focusManager.isActive {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Ocultar barra de pestañas")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            Spacer()
                            Toggle("", isOn: $focusManager.hideTabBar)
                                .tint(AppColors.primary(themeManager: themeManager))
                        }
                        
                        HStack {
                            Text("Reducir brillo de la interfaz")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            Spacer()
                            Toggle("", isOn: $focusManager.dimUI)
                                .tint(AppColors.primary(themeManager: themeManager))
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .cardStyle(isDarkMode: themeManager.isDarkMode)
    }
}

struct SettingsView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .configuration
    @State private var showingResetAlert = false
    @State private var customTimeInput = ""

    var body: some View {
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
            
            VStack(spacing: 8) {
                // Selector de pestañas
                tabSelector
                
                // Contenido según la pestaña seleccionada
                TabView(selection: $selectedTab) {
                    configurationMainView
                        .tag(SettingsTab.configuration)
                    
                    configurationView
                        .tag(SettingsTab.addExercise)
                    
                    ExerciseManagementView()
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                        .tag(SettingsTab.exercises)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .background(AppColors.background(isDark: themeManager.isDarkMode))
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(AppFonts.subtitle)
                            .foregroundColor(selectedTab == tab ? AppColors.primary(themeManager: themeManager) : AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Rectangle()
                            .fill(selectedTab == tab ? AppColors.primary(themeManager: themeManager) : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
    }
    
    private var configurationMainView: some View {
        ZStack(alignment: .top) {
            AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Card para modo enfoque
                    FocusModeSettingsCard()
                        .environmentObject(themeManager)
                    
                    // Card para tutorial
                    VStack(spacing: 12) {
                        Text("Tutorial")
                            .font(AppFonts.subtitle)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        Button(action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                viewModel.showTutorial()
                            }
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("Ver Tutorial")
                                    .font(AppFonts.body)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(AppColors.primary(themeManager: themeManager))
                    }
                    .padding()
                    .cardStyle(isDarkMode: themeManager.isDarkMode)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var configurationView: some View {
        ZStack(alignment: .top) {
            AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) { // Reducido de 16 a 8
                    // Card para personalización de colores
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Text("Color Personalizado")
                                .font(AppFonts.title)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            Text("Selecciona el color principal de la app")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Selector de colores en grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                            ForEach(AccentColor.allCases, id: \.id) { color in
                                Button(action: {
                                    themeManager.setAccentColor(color)
                                }) {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(themeManager.selectedAccentColor == color ? AppColors.textPrimary(isDark: themeManager.isDarkMode) : Color.clear, lineWidth: 3)
                                        )
                                        .scaleEffect(themeManager.selectedAccentColor == color ? 1.2 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: themeManager.selectedAccentColor)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 20)
                    .cardStyle(isDarkMode: themeManager.isDarkMode)
                    
                    // Card combinado para añadir ejercicios y timer
                    VStack(spacing: 20) {
                        // Sección para días/ejercicios
                        SettingsDayView()
                            .environmentObject(viewModel)
                            .environmentObject(themeManager)
                        
                        Divider()
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.3))
                        
                        // Configuración del timer
                        VStack(spacing: 16) {
                            Text("Configuración del Timer")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Tiempo de descanso")
                                        .font(AppFonts.body)
                                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    Spacer()
                                    Text("\(viewModel.restDuration / 60):\(String(format: "%02d", viewModel.restDuration % 60))")
                                        .font(AppFonts.body.weight(.semibold))
                                        .foregroundColor(AppColors.primary)
                                }
                                
                                HStack(spacing: 16) {
                                    Button("30s") {
                                        print("SettingsView: Botón 30s presionado")
                                        viewModel.updateRestDuration(30)
                                    }
                                    .buttonStyle(RestDurationButtonStyle(isSelected: viewModel.restDuration == 30, isDarkMode: themeManager.isDarkMode, themeManager: themeManager))
                                    
                                    Button("1:00") {
                                        print("SettingsView: Botón 1:00 presionado")
                                        viewModel.updateRestDuration(60)
                                    }
                                    .buttonStyle(RestDurationButtonStyle(isSelected: viewModel.restDuration == 60, isDarkMode: themeManager.isDarkMode, themeManager: themeManager))
                                    
                                    Button("1:30") {
                                        print("SettingsView: Botón 1:30 presionado")
                                        viewModel.updateRestDuration(90)
                                    }
                                    .buttonStyle(RestDurationButtonStyle(isSelected: viewModel.restDuration == 90, isDarkMode: themeManager.isDarkMode, themeManager: themeManager))
                                    
                                    Button("2:00") {
                                        print("SettingsView: Botón 2:00 presionado")
                                        viewModel.updateRestDuration(120)
                                    }
                                    .buttonStyle(RestDurationButtonStyle(isSelected: viewModel.restDuration == 120, isDarkMode: themeManager.isDarkMode, themeManager: themeManager))
                                }
                                
                                // Input personalizado para tiempo
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Tiempo personalizado (segundos)")
                                        .font(AppFonts.caption)
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                    
                                    HStack(spacing: 12) {
                                        TextField("90", text: $customTimeInput)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.numberPad)
                                            .frame(width: 80)
                                        
                                        Button("Aplicar") {
                                            if let seconds = Int(customTimeInput), seconds > 0 {
                                                print("SettingsView: Duración personalizada aplicada: \(seconds) segundos")
                                                viewModel.updateRestDuration(seconds)
                                                customTimeInput = ""
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(AppColors.primary(themeManager: themeManager))
                                        .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .cardStyle(isDarkMode: themeManager.isDarkMode)

                    // Card para gestión de datos
                    VStack(spacing: 12) {
                        Text("Gestión de Datos")
                            .font(AppFonts.subtitle)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        VStack(spacing: 8) {
                            Button(action: {
                                viewModel.emergencyCleanup()
                                HapticManager.shared.selectionFeedback()
                            }) {
                                HStack {
                                    Image(systemName: "trash.circle")
                                    Text("Limpiar datos antiguos")
                                        .font(AppFonts.body)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            
                            Button(action: {
                                print(viewModel.getDataSizeInfo())
                                HapticManager.shared.selectionFeedback()
                            }) {
                                HStack {
                                    Image(systemName: "info.circle")
                                    Text("Ver información de datos")
                                        .font(AppFonts.body)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                            
                            // BOTÓN TEMPORAL DE PRUEBA
                            Button(action: {
                                viewModel.addTestExerciseWithSeconds()
                                HapticManager.shared.selectionFeedback()
                            }) {
                                HStack {
                                    Image(systemName: "timer.circle")
                                    Text("🔥 CREAR EJERCICIO DE PRUEBA (45s)")
                                        .font(AppFonts.body)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    .padding()
                    .cardStyle(isDarkMode: themeManager.isDarkMode)

                    // Card para el botón de reset
                    VStack(spacing: 12) {
                        Text("Resetear todo el progreso")
                            .font(AppFonts.subtitle)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        Button(action: { showingResetAlert = true }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset App")
                                    .font(AppFonts.body.weight(.bold))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle(themeManager: themeManager))
                    }
                    .padding()
                    .cardStyle(isDarkMode: themeManager.isDarkMode)
                }
                .padding(.top, 4) // Reducido de 16 a 4 para minimizar el margen
                .padding(.bottom, 40)
                .padding(.horizontal)
            }
        }
        .alert("¿Seguro que quieres resetear todos los datos?", isPresented: $showingResetAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Resetear", role: .destructive) {
                viewModel.resetAllData()
                dismiss()
            }
        } message: {
            Text("Se borrarán todos tus ejercicios y el historial de forma permanente.")
        }
    }
}
