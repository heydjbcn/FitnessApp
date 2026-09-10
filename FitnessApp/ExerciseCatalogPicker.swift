//
//  ExerciseCatalogPicker.swift
//  ChamaFit
//
//  Catálogo de ejercicios en estilo «Pulso»: buscador, chips por grupo
//  muscular y la lista, con opción de crear uno desde cero.
//

import SwiftUI

struct ExerciseCatalogPicker: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    /// nil = crear personalizado.
    let onSelect: (CatalogExercise?) -> Void

    @State private var query = ""
    @State private var group: String? = nil
    @FocusState private var searching: Bool

    private var p: Palette { themeManager.p }
    private var results: [CatalogExercise] { ExerciseCatalog.filtered(group: group, query: query) }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "\(ExerciseCatalog.all.count) ejercicios", p: p)
                    Text("Catálogo").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 14, weight: .semibold)).foregroundColor(p.mute)
                TextField("", text: $query, prompt: Text("Buscar ejercicio").foregroundColor(p.mute.opacity(0.8)))
                    .font(.fig(15, .medium))
                    .foregroundColor(p.ink)
                    .focused($searching)
                    .submitLabel(.search)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(p.mute)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(searching ? p.acc : p.line, lineWidth: 1))
            .padding(.horizontal, 22)
            .padding(.top, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    chip("Todos", active: group == nil) { group = nil }
                    ForEach(MuscleGroup.all, id: \.self) { g in
                        chip(g, active: group == g) { group = (group == g ? nil : g) }
                    }
                }
                .padding(.horizontal, 22)
            }
            .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 6) {
                    Button { onSelect(nil); dismiss() } label: {
                        HStack(spacing: 12) {
                            IconTile(symbol: "plus", size: 40, radius: 13, gradient: true, p: p)
                            Text("Crear ejercicio desde cero")
                                .font(.fig(15, .bold)).foregroundColor(p.ink)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(p.mute)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .pulsoCard(p, radius: 16)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 4)

                    if results.isEmpty {
                        Text("Nada con «\(query)». Créalo desde cero.")
                            .font(.fig(13, .medium)).foregroundColor(p.mute)
                            .frame(maxWidth: .infinity).padding(20)
                    }
                    ForEach(results) { ex in
                        Button { onSelect(ex); dismiss() } label: {
                            HStack(spacing: 12) {
                                IconTile(symbol: ex.icon, size: 40, radius: 13, p: p)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name).font(.fig(14, .semibold)).foregroundColor(p.ink)
                                    Text("\(ex.muscleGroup) · \(ex.sets) × \(ex.reps > 0 ? "\(ex.reps)" : "tiempo")\(ex.weight > 0 ? " · \(Int(ex.weight)) kg" : "")")
                                        .font(.fig(12, .medium)).foregroundColor(p.mute)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(p.mute)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("catalog.\(ex.name)")
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func chip(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button { action(); HapticManager.shared.selectionFeedback() } label: {
            Text(title)
                .font(.fig(13, active ? .bold : .semibold))
                .foregroundColor(active ? p.onacc : p.mute)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(Capsule().fill(active ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
                .overlay(Capsule().strokeBorder(active ? .clear : p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("catalog.chip.\(title)")
    }
}
