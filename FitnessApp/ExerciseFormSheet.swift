//
//  ExerciseFormSheet.swift
//  FitnessApp
//
//  Alta y edición de ejercicios del rediseño «Pulso»: el asistente de cinco
//  pasos del prototipo (nombre → días → icono y foto → parámetros → descanso),
//  con el catálogo de ejercicios y el grupo muscular de la app en el paso 1.
//

import SwiftUI

struct ExerciseFormSheet: View {
    /// nil = ejercicio nuevo.
    let editing: Exercise?
    /// Día que llega marcado (desde "+ Añadir" de un día concreto).
    let prefillDay: WorkoutDay?

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var name = ""
    @State private var info = ""
    @State private var muscleGroup: String? = nil
    @State private var days: Set<WorkoutDay> = []
    @State private var icon = "dumbbell.fill"
    @State private var imageData: Data? = nil
    @State private var params = FormParams()
    @State private var restMin = 2
    @State private var restSec = 0
    @State private var showingCatalog = false
    @State private var confirmDelete = false
    @State private var loaded = false

    private var p: Palette { themeManager.p }
    private let steps = 5
    private var isEdit: Bool { editing != nil }

    var body: some View {
        PulsoSheet(p: p) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    switch step {
                    case 0: stepName
                    case 1: stepDays
                    case 2: stepIcon
                    case 3: stepParams
                    default: stepRest
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 10)
                .animation(.easeOut(duration: 0.2), value: step)
            }
            .scrollDismissesKeyboard(.interactively)
        } footer: {
            SheetFooter(p: p) {
                Button {
                    if step == 0 { dismiss() } else { step -= 1 }
                    HapticManager.shared.buttonTapped()
                } label: {
                    Text("Atrás")
                        .font(.fig(14, .semibold))
                        .foregroundColor(p.ink)
                        .padding(.horizontal, 20)
                        .frame(height: 50)
                        .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
                }
                .buttonStyle(.plain)

                PrimaryButton(title: step == steps - 1 ? "Guardar ejercicio" : "Siguiente",
                              height: 50, enabled: canAdvance, p: p) {
                    if step == steps - 1 { save() } else { step += 1 }
                }
            }
        }
        .onAppear(perform: load)
        .sheet(isPresented: $showingCatalog) {
            ExerciseCatalogPicker { picked in
                if let c = picked { applyCatalog(c) }
            }
            .environmentObject(themeManager)
        }
        .confirmationDialog("¿Eliminar este ejercicio?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Eliminar ejercicio", role: .destructive) {
                if let ex = editing { viewModel.removeExercise(baseExercise: ex) }
                dismiss()
            }
        } message: {
            Text("Se quitará de todos los días. El historial ya registrado se conserva.")
        }
    }

    // MARK: - Cabecera con progreso

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PASO \(step + 1) DE \(steps)")
                        .font(.fig(11, .bold))
                        .tracking(0.9)
                        .foregroundColor(p.mute)
                    Text(isEdit ? "Editar ejercicio" : "Nuevo ejercicio")
                        .font(.bri(22))
                        .em(-0.02, size: 22)
                        .foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(p.soft)
                    Capsule().fill(p.hgrad)
                        .frame(width: geo.size.width * Double(step + 1) / Double(steps))
                        .animation(.easeOut(duration: 0.3), value: step)
                }
            }
            .frame(height: 6)
            .padding(.top, 14)
        }
        .padding(.horizontal, 22)
        .padding(.top, 24)
    }

    private func stepTitle(_ title: String, _ desc: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.bri(18))
                .em(-0.02, size: 18)
                .foregroundColor(p.ink)
            Text(desc)
                .font(.fig(13, .medium))
                .lineSpacing(3)
                .foregroundColor(p.mute)
        }
    }

    // MARK: - Paso 1: nombre

    private var stepName: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepTitle("¿Qué ejercicio es?", "Ponle un nombre claro y, si quieres, una nota sobre la técnica.")

            if !isEdit {
                Button { showingCatalog = true } label: {
                    HStack(spacing: 12) {
                        IconTile(symbol: "books.vertical.fill", size: 38, radius: 12, p: p)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Elegir del catálogo").font(.fig(15, .semibold)).foregroundColor(p.ink)
                            Text("\(ExerciseCatalog.all.count) ejercicios con series y peso de partida")
                                .font(.fig(12, .medium)).foregroundColor(p.mute)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(p.mute)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(p.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
            }

            HStack(spacing: 2) {
                UpperLabel(text: "Nombre", p: p)
                Text("*").font(.fig(11, .medium)).foregroundColor(p.acc)
            }
            .padding(.top, 18)
            .padding(.bottom, 6)
            PulsoField(placeholder: "Ej. Sentadilla, Press de banca…", text: $name, height: 50, fontSize: 16, p: p)

            UpperLabel(text: "Descripción", p: p)
                .padding(.top, 16)
                .padding(.bottom, 6)
            ZStack(alignment: .topLeading) {
                if info.isEmpty {
                    Text("Describe cómo realizar el ejercicio…")
                        .font(.fig(14, .medium))
                        .foregroundColor(p.mute.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $info)
                    .font(.fig(14, .medium))
                    .foregroundColor(p.ink)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 4)
            }
            .frame(height: 104)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(p.line, lineWidth: 1))

            UpperLabel(text: "Grupo muscular", p: p)
                .padding(.top, 16)
                .padding(.bottom, 8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(MuscleGroup.all, id: \.self) { g in
                        let on = muscleGroup == g
                        Button { muscleGroup = on ? nil : g } label: {
                            Text(g)
                                .font(.fig(13, on ? .bold : .semibold))
                                .foregroundColor(on ? p.onacc : p.mute)
                                .padding(.horizontal, 14)
                                .frame(height: 34)
                                .background(Capsule().fill(on ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
                                .overlay(Capsule().strokeBorder(on ? .clear : p.line, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Paso 2: días

    private var orderedDays: [WorkoutDay] { WorkoutDay.allCases.sorted { $0.weekOrder < $1.weekOrder } }

    private var stepDays: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepTitle("¿Qué días lo haces?", "Puedes elegir varios. Se añadirá a la sesión de cada día marcado.")

            HStack(spacing: 6) {
                ForEach(orderedDays) { d in
                    let on = days.contains(d)
                    Button {
                        if on { days.remove(d) } else { days.insert(d) }
                        HapticManager.shared.selectionFeedback()
                    } label: {
                        VStack(spacing: 6) {
                            Text(d.shortLabel).font(.bri(13))
                            if on {
                                Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy))
                                    .frame(height: 14)
                            } else {
                                Circle().strokeBorder(p.line, lineWidth: 1.5).frame(width: 14, height: 14)
                            }
                        }
                        .foregroundColor(on ? p.onacc : p.mute)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(on ? AnyShapeStyle(p.grad) : AnyShapeStyle(p.soft)))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(on ? .clear : p.line, lineWidth: 1))
                        .shadow(color: on ? p.glow1 : .clear, radius: 10, y: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 18)

            (Text("Días: ").foregroundColor(p.mute)
             + Text(daysText).foregroundColor(p.ink).font(.fig(13, .semibold)))
                .font(.fig(13, .medium))
                .padding(.top, 14)
        }
    }

    private var daysText: String {
        let list = orderedDays.filter { days.contains($0) }
        return list.isEmpty ? "ninguno" : list.map(\.shortLabel).joined(separator: ", ")
    }

    // MARK: - Paso 3: icono y foto

    private var iconOptions: [(symbol: String, label: String)] {
        var all = ExerciseSymbols.all
        if !all.contains(where: { $0.symbol == icon }) { all.insert((icon, "Actual"), at: 0) }
        return all
    }

    private var stepIcon: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepTitle("Icono y foto", "El icono identifica el ejercicio en las listas. La foto es opcional.")

            HStack(spacing: 14) {
                Group {
                    if let data = imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFill()
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(p.onacc)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(p.grad)
                    }
                }
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: p.glow1, radius: 15, y: 12)

                if imageData == nil {
                    PhotoPickerButton(imageData: $imageData) {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.plus").font(.system(size: 20, weight: .semibold))
                            Text("Añadir foto").font(.fig(12, .semibold))
                        }
                        .foregroundColor(p.mute)
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(p.soft))
                        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(p.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                    }
                } else {
                    Button { imageData = nil } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 20, weight: .semibold))
                                .foregroundColor(p.acc)
                            Text("Foto añadida · quitar").font(.fig(12, .semibold))
                        }
                        .foregroundColor(p.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(p.soft))
                        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(p.acc, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 18)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(iconOptions, id: \.symbol) { opt in
                    let on = icon == opt.symbol
                    Button { icon = opt.symbol; HapticManager.shared.selectionFeedback() } label: {
                        VStack(spacing: 6) {
                            Image(systemName: opt.symbol).font(.system(size: 18, weight: .semibold))
                                .frame(height: 22)
                            Text(opt.label).font(.fig(11, on ? .semibold : .medium)).lineLimit(1)
                        }
                        .foregroundColor(on ? p.acc : p.mute)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(on ? p.soft : .clear))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(on ? p.acc : p.line, lineWidth: on ? 1.5 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Paso 4: parámetros

    private var stepParams: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepTitle("Parámetros", "Activa solo lo que quieras registrar. Los segundos sustituyen a las repeticiones.")
            VStack(spacing: 8) {
                ForEach(FormParams.Key.allCases, id: \.self) { key in
                    paramRow(key)
                }
            }
            .padding(.top, 16)
        }
    }

    @ViewBuilder private func paramRow(_ key: FormParams.Key) -> some View {
        let on = params.isOn(key)
        if on {
            HStack(spacing: 12) {
                Button { params.toggle(key) } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(p.onacc)
                        .frame(width: 24, height: 24)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(p.grad))
                }
                .buttonStyle(.plain)
                .disabled(key == .sets)
                Text(key.label).font(.fig(14, .semibold)).foregroundColor(p.ink)
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    stepper("−") { params.bump(key, -1) }
                    Text(params.display(key))
                        .font(.bri(15))
                        .foregroundColor(p.ink)
                        .frame(minWidth: 64)
                    stepper("+") { params.bump(key, 1) }
                }
            }
            .padding(.vertical, 10)
            .padding(.leading, 14)
            .padding(.trailing, 12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(p.line, lineWidth: 1))
        } else {
            Button { params.toggle(key) } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(p.line, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    Text(key.label).font(.fig(14, .semibold))
                    Spacer()
                    Text("Añadir").font(.fig(12, .medium))
                }
                .foregroundColor(p.mute)
                .padding(.vertical, 14)
                .padding(.leading, 14)
                .padding(.trailing, 12)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(p.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private func stepper(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.shared.selectionFeedback()
        } label: {
            Text(symbol)
                .font(.fig(18, .bold))
                .foregroundColor(p.ink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(p.card))
                .overlay(Circle().strokeBorder(p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Paso 5: descanso y resumen

    private var restPreview: String { String(format: "%d:%02d", restMin, restSec) }

    private var stepRest: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepTitle("Descanso entre series", "El temporizador arranca solo al marcar cada serie.")

            HStack(spacing: 14) {
                restColumn(value: "\(restMin)", unit: "min",
                           up: { restMin = min(10, restMin + 1) }, down: { restMin = max(0, restMin - 1) })
                Text(":").font(.bri(32)).foregroundColor(p.mute).padding(.bottom, 22)
                restColumn(value: String(format: "%02d", restSec), unit: "seg",
                           up: { restSec = restSec >= 45 ? 0 : restSec + 15 },
                           down: { restSec = restSec <= 0 ? 45 : restSec - 15 })
                VStack(spacing: 2) {
                    Text("TIEMPO").font(.fig(10, .bold)).tracking(0.8).opacity(0.85)
                    Text(restPreview).font(.bri(22))
                }
                .foregroundColor(p.onacc)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.grad))
                .shadow(color: p.glow1, radius: 10, y: 8)
                .padding(.leading, 10)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(p.soft))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(p.line, lineWidth: 1))
            .padding(.top, 18)

            UpperLabel(text: "Resumen", p: p)
                .padding(.top, 18)
                .padding(.bottom, 8)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(p.acc)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
                VStack(alignment: .leading, spacing: 3) {
                    Text(name.isEmpty ? "Sin nombre" : name)
                        .font(.fig(15, .bold)).foregroundColor(p.ink).lineLimit(1)
                    Text("\(params.summary) · descanso \(restPreview)")
                        .font(.fig(12, .medium)).foregroundColor(p.mute)
                    Text(daysText).font(.fig(12, .semibold)).foregroundColor(p.acc)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(p.line, lineWidth: 1))

            if isEdit {
                SoftButton(title: "Eliminar ejercicio", height: 42, fontSize: 13,
                           color: p.danger, filled: false, p: p) { confirmDelete = true }
                    .padding(.top, 14)
            }
        }
    }

    private func restColumn(value: String, unit: String, up: @escaping () -> Void, down: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            chevron("chevron.up", up)
            Text(value).font(.bri(40)).foregroundColor(p.ink).frame(minWidth: 56)
            chevron("chevron.down", down)
            Text(unit.uppercased()).font(.fig(11, .medium)).tracking(0.66).foregroundColor(p.mute)
        }
    }

    private func chevron(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.shared.selectionFeedback()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(p.ink)
                .frame(width: 40, height: 34)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.card))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lógica

    private var canAdvance: Bool {
        switch step {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return !days.isEmpty
        default: return !name.trimmingCharacters(in: .whitespaces).isEmpty && !days.isEmpty
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let ex = editing {
            name = ex.name
            info = ex.info
            muscleGroup = ex.muscleGroup
            days = Set(viewModel.days(for: ex.id))
            icon = ExerciseSymbols.symbol(for: ex)
            imageData = ex.imageData
            params = FormParams(exercise: ex)
            restMin = ex.restDuration / 60
            restSec = Int((Double(ex.restDuration % 60) / 15).rounded()) * 15 % 60
        } else {
            if let d = prefillDay { days = [d] }
            // Descanso por defecto de Configuración, redondeado a los pasos de 15 s.
            restMin = viewModel.defaultRestDuration / 60
            restSec = Int((Double(viewModel.defaultRestDuration % 60) / 15).rounded()) * 15 % 60
        }
    }

    private func applyCatalog(_ c: CatalogExercise) {
        name = c.name
        muscleGroup = c.muscleGroup
        icon = c.icon
        params.reps = .init(on: c.reps > 0, value: Double(max(1, c.reps)))
        params.kg = .init(on: c.weight > 0, value: c.weight > 0 ? c.weight : 20)
        params.sets = .init(on: true, value: Double(c.sets))
    }

    private func save() {
        let restDuration = restMin * 60 + restSec
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        let cleanInfo = info.trimmingCharacters(in: .whitespacesAndNewlines)

        if var ex = editing {
            ex.name = cleanName
            ex.info = cleanInfo
            ex.muscleGroup = muscleGroup
            ex.sfSymbolIcon = icon
            ex.imageData = imageData
            params.apply(to: &ex)
            ex.restDuration = restDuration
            viewModel.updateBaseExercise(ex)
            viewModel.setDays(days, for: ex.id)
            HapticManager.shared.exerciseEdited()
        } else {
            var ex = Exercise(id: UUID(), name: cleanName, repetitions: 0, weight: 0, totalSets: 4,
                              info: cleanInfo, imageData: imageData, restDuration: restDuration,
                              sfSymbolIcon: icon, iconColor: "accent", segundos: 0, rir: 0,
                              muscleGroup: muscleGroup)
            params.apply(to: &ex)
            viewModel.createExercise(ex, days: days)
        }
        dismiss()
    }
}

// MARK: - Parámetros del paso 4

/// Los cinco parámetros activables del prototipo con sus pasos y límites.
struct FormParams {
    struct Value { var on: Bool; var value: Double }

    enum Key: CaseIterable {
        case reps, kg, sets, seconds, rir
        var label: String {
            switch self {
            case .reps: return "Repeticiones"
            case .kg: return "Peso"
            case .sets: return "Series"
            case .seconds: return "Segundos"
            case .rir: return "RIR (reps en reserva)"
            }
        }
        var step: Double { self == .kg ? 2.5 : self == .seconds ? 5 : 1 }
        var range: ClosedRange<Double> {
            switch self {
            case .reps: return 1...100
            case .kg: return 0...500
            case .sets: return 1...12
            case .seconds: return 5...600
            case .rir: return 0...6
            }
        }
    }

    var reps = Value(on: true, value: 10)
    var kg = Value(on: true, value: 20)
    var sets = Value(on: true, value: 4)
    var seconds = Value(on: false, value: 30)
    var rir = Value(on: false, value: 2)

    init() {}

    init(exercise ex: Exercise) {
        reps = Value(on: ex.repetitions > 0, value: Double(max(1, ex.repetitions == 0 ? 10 : ex.repetitions)))
        kg = Value(on: ex.weight > 0, value: ex.weight > 0 ? ex.weight : 20)
        sets = Value(on: true, value: Double(max(1, ex.totalSets)))
        seconds = Value(on: ex.segundos > 0, value: Double(ex.segundos > 0 ? ex.segundos : 30))
        rir = Value(on: ex.rir > 0, value: Double(ex.rir > 0 ? ex.rir : 2))
    }

    private subscript(key: Key) -> Value {
        get {
            switch key { case .reps: return reps; case .kg: return kg; case .sets: return sets
            case .seconds: return seconds; case .rir: return rir }
        }
        set {
            switch key { case .reps: reps = newValue; case .kg: kg = newValue; case .sets: sets = newValue
            case .seconds: seconds = newValue; case .rir: rir = newValue }
        }
    }

    func isOn(_ key: Key) -> Bool { self[key].on }

    mutating func toggle(_ key: Key) {
        guard key != .sets else { return }   // las series son obligatorias
        self[key].on.toggle()
    }

    mutating func bump(_ key: Key, _ dir: Double) {
        let v = (self[key].value + dir * key.step)
        self[key].value = min(key.range.upperBound, max(key.range.lowerBound, v))
    }

    func display(_ key: Key) -> String {
        let v = self[key].value
        switch key {
        case .kg: return WorkoutViewModel.kg(v)
        case .seconds: return "\(Int(v)) s"
        default: return "\(Int(v))"
        }
    }

    var summary: String {
        var parts = ["\(Int(sets.value)) series"]
        if seconds.on { parts.append("\(Int(seconds.value)) s") } else if reps.on { parts.append("\(Int(reps.value)) reps") }
        if kg.on && kg.value > 0 { parts.append(WorkoutViewModel.kg(kg.value)) }
        if rir.on { parts.append("RIR \(Int(rir.value))") }
        return parts.joined(separator: " · ")
    }

    func apply(to ex: inout Exercise) {
        ex.totalSets = Int(sets.value)
        ex.repetitions = reps.on ? Int(reps.value) : 0
        ex.weight = kg.on ? kg.value : 0
        ex.segundos = seconds.on ? Int(seconds.value) : 0
        ex.rir = rir.on ? Int(rir.value) : 0
    }
}
