import SwiftUI

struct ProgramSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var showingProfileEdit = false
    
    var body: some View {
        NavigationStack {
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
                            Text("Color de Acento")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Color Personalizado")
                                        .font(AppFonts.body)
                                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    
                                    Text("Selecciona el color principal de la app")
                                        .font(AppFonts.caption)
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                }
                                
                                Spacer()
                                
                                // Paleta de colores
                                HStack(spacing: 8) {
                                    ForEach(AccentColor.allCases) { color in
                                        Button(action: {
                                            HapticManager.shared.buttonTapped()
                                            themeManager.setAccentColor(color)
                                        }) {
                                            Circle()
                                                .fill(color.color)
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: themeManager.selectedAccentColor == color ? 3 : 0)
                                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                                )
                                                .scaleEffect(themeManager.selectedAccentColor == color ? 1.2 : 1.0)
                                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: themeManager.selectedAccentColor)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .cardStyle(isDarkMode: themeManager.isDarkMode)
                        }
                        
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
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $themeManager.isTimerEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary(themeManager: themeManager)))
                            }
                            .padding()
                            .cardStyle(isDarkMode: themeManager.isDarkMode)
                        }
                        
                        // Botón Editar Perfil
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Perfil")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            Button(action: {
                                showingProfileEdit = true
                            }) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Editar mi perfil")
                                            .font(AppFonts.body)
                                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                        
                                        Text("Modifica tu información personal")
                                            .font(AppFonts.caption)
                                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                        .font(.caption)
                                }
                                .padding()
                                .cardStyle(isDarkMode: themeManager.isDarkMode)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Onboarding
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ayuda")
                                .font(AppFonts.subtitle)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            Button(action: {
                                viewModel.onboardingManager.resetOnboarding()
                                viewModel.onboardingManager.startOnboarding()
                            }) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Ver tutorial")
                                            .font(AppFonts.body)
                                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                        
                                        Text("Volver a mostrar el tutorial de ejercicios")
                                            .font(AppFonts.caption)
                                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                        .font(.caption)
                                }
                                .padding()
                                .cardStyle(isDarkMode: themeManager.isDarkMode)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingProfileEdit) {
                ProfileEditView()
                    .environmentObject(userManager)
                    .environmentObject(themeManager)
            }
        }
    }
}

#Preview {
    ProgramSettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(UserManager())
        .environmentObject(WorkoutViewModel())
}
