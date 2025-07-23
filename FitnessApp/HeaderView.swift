import SwiftUI

struct HeaderView: View {
    let mainSelectedTab: Binding<Int>?
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var viewModel: WorkoutViewModel
    
    init(mainSelectedTab: Binding<Int>? = nil) {
        self.mainSelectedTab = mainSelectedTab
    }
    
    var body: some View {
        // Solo el header con saludo (fijo)
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
        }
        .padding(.horizontal)
    }
}
