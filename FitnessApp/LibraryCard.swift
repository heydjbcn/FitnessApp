//
//  LibraryCard.swift
//  ChamaFit
//
//  En la ficha del ejercicio: vídeo, errores habituales, variante más fácil
//  y más difícil, y alternativas que puedes hacer con tu material. Con un
//  toque se cambia el ejercicio solo hoy o para siempre.
//

import SwiftUI

struct LibraryCard: View {
    let exercise: Exercise
    /// Registro de la sesión de hoy (si la ficha se abrió desde Inicio).
    var recordId: UUID? = nil
    var day: WorkoutDay? = nil
    let p: Palette
    /// Tras cambiar el ejercicio: la ficha se cierra (ya no es el de antes).
    var onSubstituted: () -> Void = {}

    @EnvironmentObject var viewModel: WorkoutViewModel
    @Environment(\.openURL) private var openURL
    @State private var pending: CatalogExercise? = nil

    private var details: ExerciseLibrary.Details? { ExerciseLibrary.details(for: exercise.name) }
    private var inPlan: Bool { recordId != nil || !viewModel.days(for: exercise.id).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            videoButton
            if let recordId, let original = viewModel.temporarySwapOriginal(recordId) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(p.acc)
                    Text("Hoy en lugar de \(original.name)").font(.fig(13, .semibold)).foregroundColor(p.ink)
                    Spacer()
                    Button("Volver") { swap(to: original, forever: false) }
                        .font(.fig(13, .bold)).foregroundColor(p.acc)
                        .accessibilityIdentifier("library.revert")
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
            }
            if let d = details {
                mistakes(d)
                variants(d)
                alternatives
            }
        }
        .confirmationDialog(pending.map { String(localized: "Cambiar \(exercise.name) por \($0.name)") } ?? "",
                            isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }),
                            titleVisibility: .visible, presenting: pending) { c in
            if recordId != nil {
                Button("Solo hoy") { swap(to: viewModel.exerciseFromCatalog(c), forever: false) }
                Button("Para siempre en esta rutina") { swap(to: viewModel.exerciseFromCatalog(c), forever: true) }
            } else {
                Button("En toda la rutina") { replaceEverywhere(with: viewModel.exerciseFromCatalog(c)) }
            }
            Button("Cancelar", role: .cancel) { pending = nil }
        } message: { _ in
            Text(recordId != nil ? "Las series que ya hayas hecho se quedan con \(exercise.name)." : "Se cambia en todos los días donde lo tienes.")
        }
    }

    // MARK: - Piezas

    private var videoButton: some View {
        let own = exercise.videoURL != nil
        let catalog = ExerciseVideos.catalogLink(for: exercise.name) != nil
        return Button { openURL(ExerciseVideos.url(for: exercise)) } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.rectangle.fill").font(.system(size: 18, weight: .semibold)).foregroundColor(p.onacc)
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.grad))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ver vídeo de la técnica").font(.fig(14, .bold)).foregroundColor(p.ink)
                    Text(own ? "Tu enlace" : catalog ? "YouTube" : "Buscar en YouTube")
                        .font(.fig(12, .medium)).foregroundColor(p.mute)
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .bold)).foregroundColor(p.mute)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("library.video")
    }

    private func mistakes(_ d: ExerciseLibrary.Details) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            UpperLabel(text: "Errores habituales", p: p)
            ForEach(d.mistakes, id: \.self) { m in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundColor(p.danger.opacity(0.85))
                    Text((m).loc).font(.fig(13, .medium)).foregroundColor(p.ink).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("library.mistakes")
    }

    @ViewBuilder private func variants(_ d: ExerciseLibrary.Details) -> some View {
        if d.easier != nil || d.harder != nil {
            VStack(alignment: .leading, spacing: 8) {
                UpperLabel(text: "Variantes", p: p)
                if let e = d.easier { variantRow("Más fácil", e, icon: "arrow.down.right") }
                if let h = d.harder { variantRow("Más difícil", h, icon: "arrow.up.right") }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
        }
    }

    private func variantRow(_ label: String, _ text: String, icon: String) -> some View {
        let entry = ExerciseCatalog.entry(named: text)
        return HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundColor(p.acc).frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text((label).loc).font(.fig(11, .semibold)).foregroundColor(p.mute)
                Text((text).loc).font(.fig(13, .semibold)).foregroundColor(p.ink).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            if let entry, inPlan {
                Button("Usar") { pending = entry }
                    .font(.fig(12, .bold)).foregroundColor(p.acc)
                    .accessibilityIdentifier("library.use.\(entry.name)")
            }
        }
    }

    @ViewBuilder private var alternatives: some View {
        let alts = viewModel.alternatives(for: exercise.name)
        if !alts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                UpperLabel(text: String(localized: "Alternativas · \(viewModel.activeEquipment.name)"), p: p)
                ForEach(alts) { c in
                    Button { if inPlan { pending = c } } label: {
                        HStack(spacing: 10) {
                            Image(systemName: c.icon).font(.system(size: 14, weight: .semibold)).foregroundColor(p.acc)
                                .frame(width: 32, height: 32)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(p.card))
                            VStack(alignment: .leading, spacing: 1) {
                                Text((c.name).loc).font(.fig(14, .semibold)).foregroundColor(p.ink)
                                Text((needsText(c)).loc).font(.fig(11, .medium)).foregroundColor(p.mute)
                            }
                            Spacer()
                            if inPlan {
                                Image(systemName: "arrow.left.arrow.right").font(.system(size: 12, weight: .bold)).foregroundColor(p.mute)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("library.alt.\(c.name)")
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
        }
    }

    private func needsText(_ c: CatalogExercise) -> String {
        let needs = c.details?.needs ?? []
        let what = needs.isEmpty ? "Sin material" : needs.sorted { $0.label < $1.label }.map(\.label).joined(separator: ", ")
        return "\(c.muscleGroup) · \(what)"
    }

    // MARK: - Acciones

    private func swap(to ex: Exercise, forever: Bool) {
        guard let recordId, let day else { return }
        viewModel.substitute(recordId: recordId, in: day, with: ex, forever: forever)
        HapticManager.shared.success()
        pending = nil
        onSubstituted()
    }

    private func replaceEverywhere(with ex: Exercise) {
        for d in WorkoutDay.allCases {
            for r in (viewModel.dailyWorkoutRecords[d] ?? []) where r.exerciseId == exercise.id {
                viewModel.substitute(recordId: r.id, in: d, with: ex, forever: true)
            }
        }
        HapticManager.shared.success()
        pending = nil
        onSubstituted()
    }
}
