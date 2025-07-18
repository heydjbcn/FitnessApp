//
//  SFSymbolIconPicker.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 18/7/25.
//

import SwiftUI

struct SFSymbolIconPicker: View {
    @Binding var selectedIcon: String?
    @Binding var iconColor: String
    @Environment(\.dismiss) private var dismiss
    
    let fitnessIcons = [
        "dumbbell", "dumbbell.fill", "figure.strengthtraining.traditional",
        "figure.strengthtraining.functional", "figure.gymnastics", "figure.boxing",
        "figure.wrestling", "figure.martial.arts", "figure.flexibility",
        "figure.cooldown", "figure.dance", "figure.run", "figure.walk",
        "figure.outdoor.cycle", "figure.indoor.cycle", "figure.elliptical",
        "figure.swimming", "figure.rowing", "figure.stairs", "figure.step.training",
        "figure.pilates", "figure.yoga", "figure.core.training",
        "figure.mixed.cardio", "figure.strengthtraining.traditional.and.functional",
        "stopwatch", "timer", "heart.circle", "heart.circle.fill",
        "target", "flame", "flame.fill", "bolt", "bolt.fill",
        "arrow.up.circle", "arrow.down.circle", "plus.circle", "minus.circle"
    ]
    
    let colors = [
        "blue", "red", "green", "orange", "purple", "pink", "yellow", "cyan", "indigo", "teal"
    ]
    
    private let columns = [
        GridItem(.adaptive(minimum: 50), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ColorSelectorView(iconColor: $iconColor, colors: colors)
                    IconGridView(selectedIcon: $selectedIcon, iconColor: iconColor, icons: fitnessIcons)
                }
                .padding(.top)
            }
            .navigationTitle("Seleccionar Icono")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "teal": return .teal
        default: return .blue
        }
    }
}

struct ColorSelectorView: View {
    @Binding var iconColor: String
    let colors: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color del Icono")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: {
                            iconColor = color
                            HapticManager.shared.buttonTapped()
                        }) {
                            Circle()
                                .fill(colorFromString(color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: iconColor == color ? 3 : 0)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "teal": return .teal
        default: return .blue
        }
    }
}

struct IconGridView: View {
    @Binding var selectedIcon: String?
    let iconColor: String
    let icons: [String]
    
    private let columns = [
        GridItem(.adaptive(minimum: 50), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Iconos de Fitness")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(icons, id: \.self) { icon in
                    Button(action: {
                        selectedIcon = icon
                        HapticManager.shared.buttonTapped()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: icon)
                                .font(.system(size: 24))
                                .foregroundColor(selectedIcon == icon ? .white : colorFromString(iconColor))
                                .frame(width: 50, height: 50)
                                .background(
                                    selectedIcon == icon ? 
                                    colorFromString(iconColor) : Color.clear
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Text(icon)
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "teal": return .teal
        default: return .blue
        }
    }
}

#Preview {
    SFSymbolIconPicker(selectedIcon: .constant("dumbbell"), iconColor: .constant("blue"))
}
