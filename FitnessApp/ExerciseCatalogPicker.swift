//
//  ExerciseCatalogPicker.swift
//  FitnessApp
//
//  Selector del catálogo de ejercicios (buscable + filtro por grupo) con
//  opción de crear uno personalizado.
//

import SwiftUI

struct ExerciseCatalogPicker: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    /// nil = crear personalizado.
    let onSelect: (CatalogExercise?) -> Void

    @State private var query: String = ""
    @State private var group: String? = nil

    private var isDark: Bool { themeManager.isDarkMode }
    private var results: [CatalogExercise] { ExerciseCatalog.filtered(group: group, query: query) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(isDark: isDark).ignoresSafeArea()
                VStack(spacing: 12) {
                    // Buscador
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textSecondary(isDark: isDark))
                        TextField("Buscar ejercicio", text: $query)
                            .foregroundColor(AppColors.textPrimary(isDark: isDark))
                    }
                    .padding(.horizontal, 14).frame(height: 44)
                    .background(AppColors.cardBackground(isDark: isDark)).cornerRadius(12)
                    .padding(.horizontal)

                    // Filtro por grupo (chips)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip(title: "Todos", active: group == nil) { group = nil }
                            ForEach(MuscleGroup.all, id: \.self) { g in
                                chip(title: g, active: group == g) { group = (group == g ? nil : g) }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Lista
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            // Crear personalizado
                            Button { onSelect(nil) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus")
                                        .foregroundColor(AppColors.onPrimary(themeManager: themeManager))
                                        .frame(width: 40, height: 40)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(AppColors.primary(themeManager: themeManager)))
                                    Text("Crear ejercicio personalizado")
                                        .font(AppFonts.subtitle)
                                        .foregroundColor(AppColors.textPrimary(isDark: isDark))
                                    Spacer()
                                }
                                .padding(12).cardStyle(isDarkMode: isDark)
                            }

                            ForEach(results) { ex in
                                Button { onSelect(ex) } label: { row(ex) }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Añadir ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ ex: CatalogExercise) -> some View {
        HStack(spacing: 12) {
            Image(systemName: ex.icon)
                .foregroundColor(AppColors.primary(themeManager: themeManager))
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppColors.primary(themeManager: themeManager).opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.name).font(AppFonts.bodyMedium).foregroundColor(AppColors.textPrimary(isDark: isDark))
                Text(ex.muscleGroup).font(AppFonts.caption).foregroundColor(AppColors.textSecondary(isDark: isDark))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(AppColors.textTertiary(isDark: isDark))
        }
        .padding(12).cardStyle(isDarkMode: isDark)
    }

    @ViewBuilder
    private func chip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(active ? AppColors.onPrimary(themeManager: themeManager) : AppColors.textPrimary(isDark: isDark))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(
                    Capsule().fill(active ? AppColors.primary(themeManager: themeManager) : AppColors.cardBackground(isDark: isDark))
                )
        }
    }
}
