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
                            
                            // Paleta de colores (las bolitas) - Una sola fila horizontal
                            HStack(spacing: 0) {
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
                                    .frame(maxWidth: .infinity)
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
