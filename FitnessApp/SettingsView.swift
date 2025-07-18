import SwiftUI

enum SettingsTab: String, CaseIterable {
    case configuration = "Añadir Ejercicio"
    case exercises = "Ejercicios"
}

struct SettingsView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
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
                    configurationView
                        .tag(SettingsTab.configuration)
                    
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
                        
                        Rectangle()
                            .fill(selectedTab == tab ? AppColors.primary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
    }
    
    private var configurationView: some View {
        ZStack(alignment: .top) {
            AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) { // Reducido de 16 a 8
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
                                        viewModel.restDuration = 30
                                        viewModel.timeRemaining = viewModel.restDuration
                                    }
                                    .buttonStyle(RestDurationButtonStyle(isSelected: viewModel.restDuration == 30, isDarkMode: themeManager.isDarkMode))
                                    
                                    Button("1:00") {
                                        viewModel.restDuration = 60
                                        viewModel.timeRemaining = viewModel.restDuration
                                    }
                                    .buttonStyle(RestDurationButtonStyle(isSelected: viewModel.restDuration == 60, isDarkMode: themeManager.isDarkMode))
                                    
                                    Button("1:30") {
                                        viewModel.restDuration = 90
                                        viewModel.timeRemaining = viewModel.restDuration
                                    }
                                    .buttonStyle(RestDurationButtonStyle(isSelected: viewModel.restDuration == 90, isDarkMode: themeManager.isDarkMode))
                                    
                                    Button("2:00") {
                                        viewModel.restDuration = 120
                                        viewModel.timeRemaining = viewModel.restDuration
                                    }
                                    .buttonStyle(RestDurationButtonStyle(isSelected: viewModel.restDuration == 120, isDarkMode: themeManager.isDarkMode))
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
                                                viewModel.restDuration = seconds
                                                viewModel.timeRemaining = viewModel.restDuration
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
                        .buttonStyle(PrimaryButtonStyle())
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
