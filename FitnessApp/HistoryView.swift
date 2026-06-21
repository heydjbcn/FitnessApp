//
//  HistoryView.swift - SIMPLIFICADO
//  FitnessApp
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(AppColors.textSecondary)
            
            VStack(spacing: 8) {
                Text("Historial de Entrenamientos")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text("Próximamente")
                    .font(.headline)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("El historial estará disponible pronto")
                    .font(.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
    }
}
