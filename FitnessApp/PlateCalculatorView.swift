//
//  PlateCalculatorView.swift
//  FitnessApp
//
//  Calculadora de discos: dado un peso objetivo y la barra, indica qué discos
//  poner por lado.
//

import SwiftUI

struct PlateCalculatorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var targetText: String
    @State private var barWeight: Double = 20

    private var isDark: Bool { themeManager.isDarkMode }
    private let availablePlates: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    init(initialWeight: Double = 0) {
        _targetText = State(initialValue: initialWeight > 0 ? String(format: "%g", initialWeight) : "")
    }

    private var target: Double { Double(targetText.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    private var perSide: [(plate: Double, count: Int)] {
        var remaining = (target - barWeight) / 2
        guard remaining > 0 else { return [] }
        var result: [(Double, Int)] = []
        for p in availablePlates {
            let c = Int((remaining + 0.0001) / p)
            if c > 0 { result.append((p, c)); remaining -= Double(c) * p }
        }
        return result.map { (plate: $0.0, count: $0.1) }
    }

    private var residual: Double {
        let used = perSide.reduce(0) { $0 + $1.plate * Double($1.count) } * 2 + barWeight
        return target - used
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(isDark: isDark).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Peso objetivo
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PESO OBJETIVO").font(AppFonts.label).tracking(1.0)
                                .foregroundColor(AppColors.textSecondary(isDark: isDark))
                            HStack {
                                TextField("0", text: $targetText)
                                    .keyboardType(.decimalPad)
                                    .font(AppFonts.metric)
                                    .foregroundColor(AppColors.textPrimary(isDark: isDark))
                                Text("kg").font(AppFonts.body).foregroundColor(AppColors.textSecondary(isDark: isDark))
                            }
                            .padding(.horizontal, 14).frame(height: 56)
                            .background(AppColors.cardBackground(isDark: isDark)).cornerRadius(12)
                        }

                        // Barra
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BARRA").font(AppFonts.label).tracking(1.0)
                                .foregroundColor(AppColors.textSecondary(isDark: isDark))
                            HStack(spacing: 8) {
                                ForEach([20.0, 15.0, 10.0], id: \.self) { b in
                                    Button { barWeight = b } label: {
                                        Text("\(Int(b)) kg")
                                            .font(AppFonts.caption)
                                            .foregroundColor(barWeight == b ? AppColors.onPrimary(themeManager: themeManager) : AppColors.textPrimary(isDark: isDark))
                                            .padding(.horizontal, 16).padding(.vertical, 10)
                                            .background(Capsule().fill(barWeight == b ? AppColors.primary(themeManager: themeManager) : AppColors.cardBackground(isDark: isDark)))
                                    }
                                }
                            }
                        }

                        // Resultado
                        VStack(alignment: .leading, spacing: 12) {
                            Text("POR CADA LADO").font(AppFonts.label).tracking(1.0)
                                .foregroundColor(AppColors.textSecondary(isDark: isDark))
                            if target <= barWeight {
                                Text(target > 0 ? "El objetivo es igual o menor que la barra." : "Introduce un peso objetivo.")
                                    .font(AppFonts.body).foregroundColor(AppColors.textSecondary(isDark: isDark))
                            } else if perSide.isEmpty {
                                Text("No se puede formar con los discos disponibles.")
                                    .font(AppFonts.body).foregroundColor(AppColors.textSecondary(isDark: isDark))
                            } else {
                                ForEach(perSide, id: \.plate) { item in
                                    HStack {
                                        Text("\(plateStr(item.plate)) kg")
                                            .font(AppFonts.bodyMedium)
                                            .foregroundColor(AppColors.textPrimary(isDark: isDark))
                                        Spacer()
                                        Text("× \(item.count)")
                                            .font(AppFonts.bodyMedium)
                                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                                    }
                                    .padding(.horizontal, 14).frame(height: 48)
                                    .background(AppColors.cardBackground(isDark: isDark)).cornerRadius(12)
                                }
                                if abs(residual) > 0.01 {
                                    Text("Aprox. (faltan \(plateStr(abs(residual))) kg para el total exacto)")
                                        .font(AppFonts.caption)
                                        .foregroundColor(AppColors.accentOrange)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Calculadora de discos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
            }
        }
    }

    private func plateStr(_ v: Double) -> String { String(format: "%g", v) }
}
