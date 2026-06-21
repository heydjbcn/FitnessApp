import SwiftUI

enum PresentedSheet: String, CaseIterable, Identifiable {
    case programSettings = "programSettings"
    
    var id: String { self.rawValue }
}

struct HeaderView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var viewModel: WorkoutViewModel
    @State private var presentedSheet: PresentedSheet?
    
    var body: some View {
        // Solo el header con saludo e iconos (fijo)
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // Etiqueta pequeña en lima, mayúsculas (saludo)
                Text(userManager.getGreeting().uppercased())
                    .font(AppFonts.label)
                    .tracking(1.5)
                    .foregroundColor(AppColors.primary(themeManager: themeManager))

                // Nombre grande (Space Grotesk)
                Text(userManager.userName.isEmpty ? "Hola" : userManager.userName)
                    .font(AppFonts.largeTitle)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))

                // Subtítulo gris
                Text("Vamos por un gran entrenamiento")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }

            Spacer()

            // Botón Configuración del Programa (icono en círculo arriba a la derecha)
            Button {
                presentedSheet = .programSettings
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                    )
                    .overlay(
                        Circle().stroke(AppColors.hairline(isDark: themeManager.isDarkMode), lineWidth: 1)
                    )
            }
            .padding(.top, 4)
        }
        .padding(.horizontal)
        .sheet(item: $presentedSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .programSettings:
                    ProgramSettingsView()
                        .environmentObject(themeManager)
                        .environmentObject(userManager)
                        .environmentObject(viewModel)
                }
            }
        }
    }
}
