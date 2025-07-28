import SwiftUI

// --- COMPONENTE REUTILIZABLE PARA CADA FILA DE AJUSTES ---
struct SettingsRowView<TrailingContent: View>: View {
    let icon: String
    let iconBackgroundColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let trailingContent: TrailingContent
    
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconBackgroundColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            
            trailingContent
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
    }
}

// --- VISTA PRINCIPAL DE CONFIGURACIÓN ---
struct SettingsView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    
    @StateObject private var focusManager = FocusModeManager()
    @StateObject private var spotifyManager = SpotifyManager()
    
    @State private var showingNotifications = false
    @State private var showingProfileEdit = false
    
    @Environment(\.dismiss) private var dismiss
    
    // Binding opcional para controlar el tab principal
    var mainSelectedTab: Binding<Int>? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // --- HEADER ---
                    SettingsHeaderView()
                        .environmentObject(themeManager)
                        .environmentObject(userManager)
                    
                    // --- TARJETA DE TEMA ---
                    SettingsRowView(
                        icon: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill",
                        iconBackgroundColor: themeManager.isDarkMode ? .purple : .orange,
                        title: "Modo oscuro",
                        subtitle: "Cambia entre modo claro y oscuro"
                    ) {
                        Button(action: {
                            print("🎨 SettingsView: Iniciando cambio de tema...")
                            HapticManager.shared.selectionFeedback()
                            themeManager.toggleTheme()
                        }) {
                            Image(systemName: themeManager.isDarkMode ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundColor(AppColors.primary(themeManager: themeManager))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // --- TARJETA DE MANTENER PANTALLA ENCENDIDA ---
                    SettingsRowView(
                        icon: "lightbulb.fill",
                        iconBackgroundColor: .yellow,
                        title: "Mantener pantalla encendida",
                        subtitle: "Evita que la pantalla se apague durante entrenamientos"
                    ) {
                        Toggle("", isOn: $focusManager.keepScreenOn)
                            .tint(AppColors.primary(themeManager: themeManager))
                    }

                    // --- TARJETA DE MODO DE ENFOQUE ---
                    SettingsRowView(
                        icon: "target",
                        iconBackgroundColor: .cyan,
                        title: "Modo de enfoque automático",
                        subtitle: "Activa automáticamente durante entrenamientos"
                    ) {
                        Toggle("", isOn: $focusManager.isActive)
                            .tint(AppColors.primary(themeManager: themeManager))
                    }
                    
                    // --- TARJETA DE SPOTIFY MEJORADA ---
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "music.note")
                                    .font(.system(size: 18))
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Conectar con Spotify")
                                    .font(AppFonts.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))

                                Text(spotifyManager.isConnected ? "Conectado a tu cuenta de Spotify" : "Controla tu música durante el entrenamiento")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                        }
                        
                        // Mostrar información de la canción actual si está conectado
                        if spotifyManager.isConnected && spotifyManager.currentTrackName != "No Conectado" {
                            HStack {
                                Image(systemName: "music.note")
                                    .frame(width: 40, height: 40)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(spotifyManager.currentTrackName)
                                        .font(.caption.bold())
                                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                        .lineLimit(1)
                                    
                                    Text(spotifyManager.currentArtistName)
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Image(systemName: spotifyManager.isPlaying ? "pause.fill" : "play.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                            .padding(12)
                            .background(AppColors.background(isDark: themeManager.isDarkMode))
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            HapticManager.shared.buttonTapped()
                            if spotifyManager.isConnected {
                                spotifyManager.disconnect()
                            } else {
                                spotifyManager.connect()
                            }
                        }) {
                            HStack {
                                Image(systemName: spotifyManager.isConnected ? "xmark.circle.fill" : "link.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text(spotifyManager.isConnected ? "Desconectar" : "Conectar")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(spotifyManager.isConnected ?
                                          LinearGradient(colors: [Color.red, Color.red.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                          LinearGradient(colors: [Color.green, Color.green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                            .shadow(color: (spotifyManager.isConnected ? Color.red : Color.green).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(20)
                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                    .cornerRadius(16)
                    
                    // --- TARJETA DE COLOR PERSONALIZADO ---
                    VStack(spacing: 12) {
                        Text("Elige el color personalizado de la App")
                            .font(AppFonts.body)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            ForEach(AccentColor.allCases, id: \.id) { color in
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
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                    .cornerRadius(16)
                    
                    // --- TARJETA DE NOTIFICACIONES ---
                    Button(action: { showingNotifications = true }) {
                        SettingsRowView(
                            icon: "bell.fill",
                            iconBackgroundColor: .red,
                            title: "Ver notificaciones",
                            subtitle: "No hay notificaciones nuevas"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // --- TARJETA DE CONFIGURACIÓN DE PROGRAMA ---
                    NavigationLink(destination: ProgramSettingsView().environmentObject(viewModel).environmentObject(themeManager)) {
                        SettingsRowView(
                            icon: "calendar",
                            iconBackgroundColor: .purple,
                            title: "Configuración del programa",
                            subtitle: "Días activos y rutina de entrenamiento"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // --- TARJETA DE DATOS DE SALUD ---
                    NavigationLink(destination: HealthDataView().environmentObject(viewModel).environmentObject(themeManager)) {
                        SettingsRowView(
                            icon: "heart.fill",
                            iconBackgroundColor: .red,
                            title: "Datos de salud",
                            subtitle: "Integración con Apple Health"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // --- TARJETA DE TUTORIAL ---
                    VStack(spacing: 12) {
                        Text("¿Nuevo en FitnessApp?")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            .padding(.bottom, 4)
                        
                        Button(action: {
                            viewModel.onboardingManager.resetOnboarding()
                            viewModel.onboardingManager.startOnboarding(force: true)
                            
                            if let mainTab = mainSelectedTab {
                                mainTab.wrappedValue = 0
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                dismiss()
                            }
                        }) {
                            Text("Ver tutorial y empezar")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primary(themeManager: themeManager))
                                .cornerRadius(12)
                        }
                    }
                    .padding(20)
                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                    .cornerRadius(16)
                    
                    // --- BOTÓN DE RESETEAR DATOS ---
                    Button(action: {
                        print("🚨 ¡RESETEAR DATOS!")
                        HapticManager.shared.warning()
                        viewModel.resetAllData()
                    }) {
                        SettingsRowView(
                            icon: "trash.fill",
                            iconBackgroundColor: .red,
                            title: "Resetear todos los datos",
                            subtitle: "⚠️ Esta acción no se puede deshacer"
                        ) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView()
                .environmentObject(userManager)
                .environmentObject(themeManager)
        }
    }
}