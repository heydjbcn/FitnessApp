//
//  CoachAIView.swift
//  FitnessApp
//
//  Pantalla del Coach IA: pide ajustes/consejos sobre la rutina usando Claude.
//

import SwiftUI

struct CoachAIView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var coach = AICoachManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var prompt: String = ""
    @State private var answer: String = ""
    @State private var loading = false
    @State private var errorMsg: String?
    @State private var keyDraft: String = ""

    private var isDark: Bool { themeManager.isDarkMode }

    private let suggestions = [
        "Ajusta mi rutina del lunes para ganar fuerza",
        "¿Estoy entrenando equilibrado por grupos musculares?",
        "Dame un calentamiento para piernas",
        "¿Cómo progreso de peso sin estancarme?"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(isDark: isDark).ignoresSafeArea()
                if !coach.hasKey {
                    keyEntry
                } else {
                    chat
                }
            }
            .navigationTitle("Coach IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
            }
        }
    }

    // MARK: - Entrada de API key
    private var keyEntry: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                Text("Activa el Coach IA")
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.textPrimary(isDark: isDark))
                Text("Pega tu API key de Anthropic (Claude). Es de pago por uso y se guarda solo en este dispositivo.")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary(isDark: isDark))
                SecureField("sk-ant-...", text: $keyDraft)
                    .padding(.horizontal, 14).frame(height: 48)
                    .background(AppColors.cardBackground(isDark: isDark)).cornerRadius(12)
                    .foregroundColor(AppColors.textPrimary(isDark: isDark))
                Button(action: { coach.apiKey = keyDraft }) { Text("Guardar y activar") }
                    .buttonStyle(PrimaryButtonStyle(themeManager: themeManager))
                    .disabled(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
    }

    // MARK: - Chat
    private var chat: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if answer.isEmpty && !loading {
                        Text("PRUEBA A PREGUNTAR")
                            .font(AppFonts.label).tracking(1.0)
                            .foregroundColor(AppColors.textSecondary(isDark: isDark))
                        ForEach(suggestions, id: \.self) { s in
                            Button { prompt = s } label: {
                                HStack {
                                    Text(s).font(AppFonts.body)
                                        .foregroundColor(AppColors.textPrimary(isDark: isDark))
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.textTertiary(isDark: isDark))
                                }
                                .padding(14).cardStyle(isDarkMode: isDark)
                            }
                        }
                    }
                    if loading {
                        HStack(spacing: 8) {
                            ProgressView().tint(AppColors.primary(themeManager: themeManager))
                            Text("Pensando…").font(AppFonts.body)
                                .foregroundColor(AppColors.textSecondary(isDark: isDark))
                        }
                    }
                    if let e = errorMsg {
                        Text(e).font(AppFonts.caption).foregroundColor(AppColors.danger)
                    }
                    if !answer.isEmpty {
                        Text(answer)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary(isDark: isDark))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .cardStyle(isDarkMode: isDark)
                    }
                }
                .padding()
            }
            // Barra de entrada
            HStack(spacing: 10) {
                TextField("Pregunta a tu coach…", text: $prompt, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(AppColors.cardBackground(isDark: isDark)).cornerRadius(14)
                    .foregroundColor(AppColors.textPrimary(isDark: isDark))
                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(AppColors.primary(themeManager: themeManager)))
                }
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty || loading)
            }
            .padding()
        }
    }

    private func send() {
        let q = prompt.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        loading = true; errorMsg = nil; answer = ""
        let ctx = buildContext()
        Task {
            do {
                let res = try await coach.ask(q, context: ctx)
                answer = res
            } catch {
                errorMsg = error.localizedDescription
            }
            loading = false
        }
    }

    private func buildContext() -> String {
        var lines: [String] = []
        for day in viewModel.activeDays {
            let recs = viewModel.dailyWorkoutRecords[day] ?? []
            guard !recs.isEmpty else { continue }
            lines.append("\(day.rawValue):")
            for r in recs {
                if let ex = viewModel.getExercise(by: r.exerciseId) {
                    let grp = ex.muscleGroup.map { " (\($0))" } ?? ""
                    lines.append("  - \(ex.name)\(grp): \(ex.totalSets)x\(ex.repetitions) @ \(Int(ex.weight))kg")
                }
            }
        }
        if lines.isEmpty { return "El usuario aún no tiene ejercicios en su rutina." }
        return lines.joined(separator: "\n")
    }
}
