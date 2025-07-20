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
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                    Spacer()
                    Toggle("", isOn: $focusManager.keepScreenOn)
                        .tint(AppColors.primary)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Modo de enfoque automático")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        Text("Activa automáticamente durante entrenamientos")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                    Spacer()
                    Toggle("", isOn: $focusManager.isActive)
                        .tint(AppColors.primary)
                }
                
                if focusManager.isActive {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Ocultar barra de pestañas")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            Spacer()
                            Toggle("", isOn: $focusManager.hideTabBar)
                                .tint(AppColors.primary)
                        }
                        
                        HStack {
                            Text("Reducir brillo de la interfaz")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            Spacer()
                            Toggle("", isOn: $focusManager.dimUI)
                                .tint(AppColors.primary)
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
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(selectedTab == tab ? AppColors.primary : AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? AppColors.primary : Color.clear)
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
                            viewModel.onboardingManager.resetOnboarding()
                            viewModel.onboardingManager.startOnboarding()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("Ver Tutorial")
                                    .font(AppFonts.body)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(AppColors.primary)
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color de Acento")
                            .font(AppFonts.subtitle)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        Text("Selecciona el color principal de la app")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            .padding(.bottom, 8)
                        
                        // Paleta de colores (las bolitas)
                        HStack(spacing: 8) {
                            ForEach(AccentColor.allCases, id: \.id) { color in
                                Button(action: {
                                    themeManager.setAccentColor(color)
                                }) {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(themeManager.selectedAccentColor == color ? AppColors.textPrimary(isDark: themeManager.isDarkMode) : Color.clear, lineWidth: 2)
                                        )
                                        .scaleEffect(themeManager.selectedAccentColor == color ? 1.1 : 1.0)
                                        .animation(.spring(), value: themeManager.selectedAccentColor)
                                }
                            }
                            Spacer() // Empuja las bolitas a la izquierda
                        }
                    }
                    .padding()
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
                                        .tint(AppColors.primary)
                                        .foregroundColor(.black)
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
