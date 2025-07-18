import SwiftUI

enum PresentedSheet: String, CaseIterable, Identifiable {
    case history = "history"
    case addExercise = "addExercise"
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
                    .font(.title2.bold())
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                if !userManager.userName.isEmpty {
                    Text("¡Vamos por un gran entrenamiento!")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Botón Historial
                Button { 
                    presentedSheet = .history
                } label: { 
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundColor(AppColors.primary) 
                }
                
                // Botón Añadir/Editar Ejercicios
                Button { 
                    presentedSheet = .addExercise
                } label: { 
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primary) 
                }
                
                // Botón Configuración del Programa
                Button { 
                    presentedSheet = .programSettings
                } label: { 
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primary) 
                }
            }
        }
        .padding(.horizontal)
        .sheet(item: $presentedSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .history:
                    HistoryView()
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                case .addExercise:
                    SettingsView()
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                case .programSettings:
                    ProgramSettingsView()
                        .environmentObject(themeManager)
                        .environmentObject(userManager)
                }
            }
        }
    }
}
