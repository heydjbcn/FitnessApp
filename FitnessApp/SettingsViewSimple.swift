import SwiftUI

// --- VISTA SETTINGSVIEW SIMPLIFICADA PARA DIAGNÓSTICO ---
struct SettingsViewSimple: View {
    let mainSelectedTab: Binding<Int>?
    
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingProfileEdit = false
    
    init(mainSelectedTab: Binding<Int>? = nil) {
        self.mainSelectedTab = mainSelectedTab
        print("🔧 SettingsViewSimple: Inicialización SEGURA para diagnóstico")
    }

    var body: some View {
        ZStack {
            AppColors.background(isDark: themeManager.isDarkMode)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    Text("⚙️ CONFIGURACIÓN")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("🔧 VERSIÓN SIMPLIFICADA PARA DIAGNÓSTICO")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.bottom)
                    
                    // --- TARJETA DE MODO OSCURO BÁSICA ---
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(themeManager.isDarkMode ? .purple : .orange)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("Modo oscuro")
                                    .font(.headline)
                                Text("Cambia entre modo claro y oscuro")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                print("🎨 SettingsViewSimple: Cambiando tema...")
                                themeManager.toggleTheme()
                            }) {
                                Image(systemName: themeManager.isDarkMode ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // --- INFORMACIÓN DE DIAGNÓSTICO ---
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📊 INFORMACIÓN DE DIAGNÓSTICO")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("• Esta vista NO usa FocusModeManager")
                        Text("• Esta vista NO usa SpotifyManager")
                        Text("• Esta vista NO accede a UserDefaults complejos")
                        Text("• Si esta vista funciona, el problema está en los managers")
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            print("🔧 SettingsViewSimple: Vista cargada correctamente")
        }
    }
}

#Preview {
    SettingsViewSimple(mainSelectedTab: .constant(3))
        .environmentObject(WorkoutViewModel())
        .environmentObject(ThemeManager())
        .environmentObject(UserManager())
}
