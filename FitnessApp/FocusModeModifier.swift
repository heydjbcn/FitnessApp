//
//  FocusModeModifier.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 18/7/25.
//

import SwiftUI

// MARK: - Focus Mode Modifier
struct FocusModeModifier: ViewModifier {
    @StateObject private var focusManager = FocusModeManager()
    @StateObject private var themeManager = ThemeManager()
    
    func body(content: Content) -> some View {
        content
            .opacity(focusManager.isActive && focusManager.dimUI ? 0.6 : 1.0)
            .overlay(
                Group {
                    if focusManager.isActive && focusManager.showWorkoutTimer {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Spacer()
                                
                                // Indicador de modo de enfoque
                                Button(action: {
                                    // Haptic feedback para toggle de modo enfoque
                                    HapticManager.shared.buttonTapped()
                                    focusManager.toggleFocusMode()
                                }) {
                                    Image(systemName: "eye.fill")
                                        .font(.title2)
                                        .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                                        .padding()
                                        .background(AppColors.primary(themeManager: themeManager))
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                }
                                .padding()
                            }
                        }
                    }
                }
            )
            .allowsHitTesting(focusManager.isActive && focusManager.preventAccidentalTouches ? false : true)
    }
}

// MARK: - View Extension
extension View {
    func focusMode() -> some View {
        self.modifier(FocusModeModifier())
    }
}