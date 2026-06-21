//
//  SplashView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 28/7/25.
//

// 1. En Xcode: File → New → File
// 2. Elige "SwiftUI View"
// 3. Nómbralo "SplashView"
// 4. Reemplaza todo el contenido con:

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            AppColors.background(isDark: themeManager.isDarkMode)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                
                Text("FitnessApp")
                    .font(.title.bold())
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                ProgressView()
                    .tint(AppColors.primary(themeManager: themeManager))
            }
        }
    }
}
