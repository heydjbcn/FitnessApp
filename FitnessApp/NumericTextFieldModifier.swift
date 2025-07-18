//
//  NumericTextFieldModifier.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 18/7/25.
//

import SwiftUI

struct NumericTextFieldModifier: ViewModifier {
    @Binding var text: String
    let placeholder: String
    let validationMessage: String
    @State private var isValid = true
    @State private var showError = false
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 2)
                )
                .keyboardType(.numberPad)
                .onChange(of: text) { _, newValue in
                    validateInput(newValue)
                }
            
            if showError && !isValid {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
    }
    
    private var borderColor: Color {
        if showError && !isValid {
            return .red
        }
        return Color.gray.opacity(0.3)
    }
    
    private func validateInput(_ input: String) {
        if input.isEmpty {
            isValid = true
            showError = false
            return
        }
        
        // Validar que solo contiene números y punto decimal
        let validCharacters = CharacterSet(charactersIn: "0123456789.")
        let characterSet = CharacterSet(charactersIn: input)
        
        if !validCharacters.isSuperset(of: characterSet) {
            isValid = false
            showError = true
            HapticManager.shared.errorOccurred()
        } else {
            // Validar que no hay múltiples puntos decimales
            let decimalCount = input.components(separatedBy: ".").count - 1
            if decimalCount > 1 {
                isValid = false
                showError = true
                HapticManager.shared.errorOccurred()
            } else {
                isValid = true
                showError = false
            }
        }
    }
}

struct IntegerTextFieldModifier: ViewModifier {
    @Binding var text: String
    let placeholder: String
    let validationMessage: String
    @State private var isValid = true
    @State private var showError = false
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 2)
                )
                .keyboardType(.numberPad)
                .onChange(of: text) { _, newValue in
                    validateInput(newValue)
                }
            
            if showError && !isValid {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
    }
    
    private var borderColor: Color {
        if showError && !isValid {
            return .red
        }
        return Color.gray.opacity(0.3)
    }
    
    private func validateInput(_ input: String) {
        if input.isEmpty {
            isValid = true
            showError = false
            return
        }
        
        // Validar que solo contiene números
        let validCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: input)
        
        if !validCharacters.isSuperset(of: characterSet) {
            isValid = false
            showError = true
            HapticManager.shared.errorOccurred()
        } else {
            isValid = true
            showError = false
        }
    }
}

// Extensiones para HapticManager
extension HapticManager {
    func errorOccurred() {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.error)
    }
    
    func successOccurred() {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
    }
}

// Extension para facilitar el uso
extension View {
    func numericTextField(
        text: Binding<String>,
        placeholder: String,
        validationMessage: String = "Ingrese solo números"
    ) -> some View {
        modifier(NumericTextFieldModifier(
            text: text,
            placeholder: placeholder,
            validationMessage: validationMessage
        ))
    }
    
    func integerTextField(
        text: Binding<String>,
        placeholder: String,
        validationMessage: String = "Ingrese solo números enteros"
    ) -> some View {
        modifier(IntegerTextFieldModifier(
            text: text,
            placeholder: placeholder,
            validationMessage: validationMessage
        ))
    }
}
