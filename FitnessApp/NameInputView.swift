//
//  NameInputView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 16/7/25.
//

import SwiftUI

struct NameInputView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var nameInput: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(AppColors.primary(themeManager: themeManager))

                        Text("¡Bienvenido a AppFit!")
                            .font(AppFonts.largeTitle)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            .multilineTextAlignment(.center)

                        Text("Para personalizar tu experiencia, cuéntanos tu nombre")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 20) {
                        TextField("Tu nombre", text: $nameInput)
                            .textFieldStyle(ModernTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                            .onSubmit {
                                saveNameIfValid()
                            }
                        
                        Button(action: saveNameIfValid) {
                            HStack {
                                Text("Continuar")
                                    .font(AppFonts.subtitle)
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                       AppColors.textSecondary(isDark: themeManager.isDarkMode) : AppColors.primary(themeManager: themeManager))
                            .cornerRadius(12)
                        }
                        .disabled(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func saveNameIfValid() {
        let trimmedName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            // Haptic feedback para guardar nombre
            HapticManager.shared.success()
            userManager.saveUserProfile(name: trimmedName, age: "", height: "", weight: "")
        } else {
            // Haptic feedback para error si el nombre está vacío
            HapticManager.shared.error()
        }
    }
}
