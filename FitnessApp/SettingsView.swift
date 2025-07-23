import SwiftUI

// --- COMPONENTE REUTILIZABLE PARA CADA FILA DE AJUSTES ---
// Esto garantiza que todas las filas tengan exactamente el mismo estilo y comportamiento.
struct SettingsRowView<TrailingContent: View>: View {
    let icon: String
    let iconBackgroundColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let trailingContent: TrailingContent
    
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 16) {
            // Círculo del icono
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconBackgroundColor)
            }
            
            // VStack para el texto
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    // --- CORRECCIÓN 1: Permite que el texto ocupe varias líneas si es necesario ---
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .multilineTextAlignment(.leading)
                    // --- CORRECCIÓN 2: Permite que el texto ocupe varias líneas si es necesario ---
                    .fixedSize(horizontal: false, vertical: true)
            }
            // --- CORRECCIÓN 3: Obliga a la VStack a ocupar todo el espacio horizontal disponible ---
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Contenido a la derecha (un Toggle, una flecha, etc.)
            trailingContent
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
    }
}

struct SettingsView: View {
    let mainSelectedTab: Binding<Int>?
    
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @StateObject private var focusManager = FocusModeManager() // Manager para los toggles
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingNotifications = false
    @State private var showingProfileEdit = false
    
    init(mainSelectedTab: Binding<Int>? = nil) {
        self.mainSelectedTab = mainSelectedTab
    }

    var body: some View {
        ZStack {
            AppColors.background(isDark: themeManager.isDarkMode)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) { // Espaciado consistente entre tarjetas
                    
                    // --- TARJETA DE PERFIL ---
                    Button(action: { showingProfileEdit = true }) {
                        SettingsRowView(
                            icon: "person.fill",
                            iconBackgroundColor: AppColors.primary(themeManager: themeManager),
                            title: "Gestiona tu información personal",
                            subtitle: "Nombre, edad, peso, altura"
                        ) {
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // --- TARJETA DE MODO OSCURO ---
                    SettingsRowView(
                        icon: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill",
                        iconBackgroundColor: themeManager.isDarkMode ? .purple : .orange,
                        title: "Modo oscuro",
                        subtitle: "Cambia entre modo claro y oscuro"
                    ) {
                        Toggle("", isOn: $themeManager.isDarkMode)
                            .tint(AppColors.primary(themeManager: themeManager))
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
                    
                    // --- TARJETA DE TUTORIAL ---
                    VStack(spacing: 12) {
                        Text("¿Nuevo en FitnessApp?")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            .padding(.bottom, 4) // Añadir padding debajo del texto
                        
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
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
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
