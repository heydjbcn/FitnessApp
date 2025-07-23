import SwiftUI

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
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Spacer().frame(width: 16)
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(AppColors.primary)
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
                        // Modo Día/Noche
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Apariencia")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            HStack {
                                Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(themeManager.isDarkMode ? "Modo Noche" : "Modo Día")
                                        .font(AppFonts.body)
                                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    
                                    Text("Ajusta la apariencia de la aplicación")
                                        .font(AppFonts.caption)
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $themeManager.isDarkMode)
                                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary(themeManager: themeManager)))
                            }
                            .padding()
                            .cardStyle(isDarkMode: themeManager.isDarkMode)
                        }
                        
                        // Selector de Color de Acento
                        VStack(alignment: .leading, spacing: 12) {
                            
                            // Título con icono
                            HStack(spacing: 8) {
                                Image(systemName: "paintpalette.fill")
                                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                                    .font(.title2)
                                
                                Text("Color Personalizado")
                                    .font(AppFonts.subtitle)
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            }
                            
                            // Descripción
                            Text("Selecciona el color principal de la app")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                .padding(.bottom, 8)
                            
                            // Paleta de colores (8 bolitas en una sola fila)
                            HStack(spacing: 16) {
                                ForEach(AccentColor.allCases) { color in
                                    Button(action: {
                                        HapticManager.shared.buttonTapped()
                                        themeManager.setAccentColor(color)
                                    }) {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(themeManager.selectedAccentColor == color ? AppColors.textPrimary(isDark: themeManager.isDarkMode) : Color.clear, lineWidth: 2)
                                            )
                                            .scaleEffect(themeManager.selectedAccentColor == color ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: themeManager.selectedAccentColor)
                                    }
                                }
                            }
                        }
                        .padding()
                        .cardStyle(isDarkMode: themeManager.isDarkMode)
                        
                        // Timer de descanso
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Timer de Descanso")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            HStack {
                                Image(systemName: themeManager.isTimerEnabled ? "timer.circle.fill" : "timer.circle")
                                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(themeManager.isTimerEnabled ? "Timer Activo" : "Timer Desactivado")
                                        .font(AppFonts.body)
                                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    
                                    Text("Mostrar timer de descanso entre series")
                                        .font(AppFonts.caption)
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $themeManager.isTimerEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary(themeManager: themeManager)))
                            }
                            .padding()
                            .cardStyle(isDarkMode: themeManager.isDarkMode)
                        }
                        
                        // CTA Tutorial Prominente
                        VStack(spacing: 16) {
                            Text("¿Nuevo en FitnessApp?")
                                .font(AppFonts.title)
                                .foregroundColor(AppColors.primary(themeManager: themeManager))
                            
                            Button(action: {
                                viewModel.onboardingManager.resetOnboarding()
                                viewModel.onboardingManager.startOnboarding(force: true)
                                
                                // Navegar a la pantalla principal si tenemos el binding
                                if let mainTab = mainSelectedTab {
                                    mainTab.wrappedValue = 0 // Ir a la pantalla principal
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    dismiss() // Cierra la configuración tras activar el onboarding
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Ver tutorial y empezar")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(AppColors.primary(themeManager: themeManager))
                                .cornerRadius(16)
                                .shadow(color: AppColors.primary(themeManager: themeManager).opacity(0.3), radius: 10, x: 0, y: 4)
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .cardStyle(isDarkMode: themeManager.isDarkMode)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
        }
        .background(AppColors.background(isDark: themeManager.isDarkMode))
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
                .environmentObject(themeManager)
        }
    }
}

#Preview {
    ProgramSettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(UserManager())
        .environmentObject(WorkoutViewModel())
}
