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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(userManager.getGreeting())
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))

                if !userManager.userName.isEmpty {
                    Text("¡Vamos por un gran entrenamiento!")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Botón Configuración del Programa
                Button { 
                    presentedSheet = .programSettings
                } label: { 
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primary(themeManager: themeManager)) 
                }
            }
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
