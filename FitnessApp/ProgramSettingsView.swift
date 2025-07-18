import SwiftUI

struct ProgramSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
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
                                    .foregroundColor(AppColors.primary)
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
                                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
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
                                        .foregroundColor(AppColors.primary)
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
}
