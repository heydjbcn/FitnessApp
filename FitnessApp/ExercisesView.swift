//
//  ExercisesView.swift
//  FitnessApp
//
//  Pestaña Ejercicios del rediseño «Pulso»: la biblioteca completa con los días
//  de cada ejercicio y su récord, alta con "Nuevo" y edición con el lápiz.
//

import SwiftUI

struct ExercisesView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var detail: Exercise? = nil
    @State private var editing: Exercise? = nil
    @State private var creating = false
    @State private var confirmReset = false

    private var p: Palette { themeManager.p }

    var body: some View {
        ZStack(alignment: .top) {
            PulsoBackground(p: p)
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(title: "Ejercicios",
                             subtitle: String(localized: "\(viewModel.availableExercises.count) en tu biblioteca"), p: p) {
                    Button {
                        HapticManager.shared.buttonTapped()
                        creating = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                            Text("Nuevo").font(.fig(13, .bold))
                        }
                        .foregroundColor(p.onacc)
                        .padding(.leading, 12)
                        .padding(.trailing, 16)
                        .frame(height: 40)
                        .background(Capsule().fill(p.hgrad))
                        .shadow(color: p.glow1, radius: 10, y: 8)
                    }
                    .buttonStyle(.plain)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if viewModel.availableExercises.isEmpty {
                            EmptyCard(icon: "dumbbell.fill",
                                      title: "Aún no hay ejercicios",
                                      message: "Crea tu primer ejercicio en cinco pasos: nombre, días, icono, parámetros y descanso.",
                                      p: p) {
                                PrimaryButton(title: "Crear ejercicio", p: p) { creating = true }
                                SoftButton(title: "Cargar rutina de ejemplo", p: p) { viewModel.loadSampleRoutine() }
                            }
                            .padding(.top, 10)
                        } else {
                            ForEach(viewModel.availableExercises) { ex in
                                card(ex).padding(.top, 10)
                            }
                            SoftButton(title: "Resetear todos los datos", icon: "trash", height: 46,
                                       color: p.danger, filled: false, p: p) { confirmReset = true }
                                .padding(.top, 26)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 120)
                }
                .padding(.top, 10)
            }
        }
        .sheet(item: $detail) { ex in
            ExerciseDetailSheet(exerciseId: ex.id)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .sheet(item: $editing) { ex in
            ExerciseFormSheet(editing: ex, prefillDay: nil)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $creating) {
            ExerciseFormSheet(editing: nil, prefillDay: nil)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .confirmationDialog("¿Resetear todos los datos?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Borrar ejercicios, rutina e historial", role: .destructive) {
                viewModel.resetAllData()
                HapticManager.shared.destructiveAction()
            }
        } message: {
            Text("Se borran todos los ejercicios, la rutina de cada día, el historial, el peso corporal y las notas. No se puede deshacer.")
        }
    }

    private func card(_ ex: Exercise) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ExerciseIcon(exercise: ex, size: 46, radius: 15, p: p)

            VStack(alignment: .leading, spacing: 0) {
                Text((ex.name).loc)
                    .font(.fig(16, .bold))
                    .em(-0.01, size: 16)
                    .foregroundColor(p.ink)
                    .lineLimit(2)
                Text("\(viewModel.meta(for: ex)) · descanso \(WorkoutViewModel.restText(ex.restDuration))")
                    .font(.fig(13, .medium))
                    .foregroundColor(p.mute)
                    .padding(.top, 3)
                FlowTags(p: p, days: viewModel.days(for: ex.id),
                         pr: viewModel.personalRecord(for: ex.id).map(\.weight).flatMap { $0 > 0 ? $0 : nil })
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button { editing = ex } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(p.mute)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().strokeBorder(p.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .pulsoCard(p, radius: 22)
        .contentShape(Rectangle())
        .onTapGesture { detail = ex }
    }
}

/// Etiquetas de días y de récord de una tarjeta de ejercicio.
private struct FlowTags: View {
    let p: Palette
    let days: [WorkoutDay]
    let pr: Double?

    var body: some View {
        HStack(spacing: 5) {
            ForEach(days) { DayTag(text: $0.shortLabel, p: p) }
            if let pr {
                DayTag(text: String(localized: "PR \(WorkoutViewModel.kg(pr))"), icon: "trophy.fill", filled: true, p: p)
            }
        }
    }
}
