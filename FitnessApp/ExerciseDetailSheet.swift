//
//  ExerciseDetailSheet.swift
//  FitnessApp
//
//  Detalle de ejercicio del rediseño «Pulso»: icono grande, días, técnica,
//  tabla de datos, historial y "Editar ejercicio" — como el prototipo — más lo
//  que la app ya hacía y el prototipo no dibuja: series de hoy con su tipo,
//  peso, reps y RPE, superserie, calculadora de discos y gráfica de progreso.
//

import SwiftUI

struct ExerciseDetailSheet: View {
    let exerciseId: UUID
    var workoutExerciseId: UUID? = nil
    var day: WorkoutDay? = nil

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingPlates = false
    @State private var showingEdit = false

    private var p: Palette { themeManager.p }
    private var exercise: Exercise? { viewModel.getExercise(by: exerciseId) }

    private var todayRecord: WorkoutExercise? {
        guard let wid = workoutExerciseId, let d = day else { return nil }
        return viewModel.dailyWorkoutRecords[d]?.first(where: { $0.id == wid })
    }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)

            if let ex = exercise {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        hero(ex)
                        dataTable(ex).padding(.top, 20)
                        if let rec = todayRecord { todaySets(rec).padding(.top, 20) }
                        platesButton.padding(.top, 12)
                        progress.padding(.top, 20)
                        history(ex).padding(.top, 20)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)
                }
            } else {
                Spacer()
                Text("Ejercicio no disponible").font(.fig(14, .medium)).foregroundColor(p.mute)
                Spacer()
            }
        } footer: {
            if exercise != nil {
                SheetFooter(p: p) {
                    SoftButton(title: "Editar ejercicio", icon: "pencil", height: 50, fontSize: 15, p: p) {
                        showingEdit = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingPlates) {
            PlateCalculatorView(initialWeight: exercise?.weight ?? 0)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingEdit) {
            if let ex = exercise {
                ExerciseFormSheet(editing: ex, prefillDay: nil)
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
            }
        }
    }

    // MARK: - Cabecera

    private func hero(_ ex: Exercise) -> some View {
        VStack(spacing: 0) {
            if let data = ex.imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 92, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: p.glow1, radius: 20, y: 16)
            } else {
                IconTile(symbol: ExerciseSymbols.symbol(for: ex), size: 92, radius: 30,
                         gradient: true, glow: true, iconSize: 38, p: p)
            }

            Text(ex.name)
                .font(.bri(24))
                .em(-0.02, size: 24)
                .foregroundColor(p.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            let days = viewModel.days(for: ex.id)
            if !days.isEmpty {
                HStack(spacing: 5) {
                    ForEach(days) { DayTag(text: $0.shortLabel, p: p) }
                }
                .padding(.top, 10)
            }

            if !ex.info.isEmpty {
                Text(ex.info)
                    .font(.fig(14, .medium))
                    .lineSpacing(5)
                    .foregroundColor(p.mute)
                    .multilineTextAlignment(.center)
                    .padding(.top, 14)
            }

            if let last = viewModel.lastPerformance(for: exerciseId) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 12, weight: .semibold))
                    Text("Última vez: \(WorkoutViewModel.kg(last.weight)) × \(last.reps) reps")
                        .font(.fig(13, .semibold))
                }
                .foregroundColor(p.acc)
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tabla de datos

    private func dataTable(_ ex: Exercise) -> some View {
        var rows: [(String, String)] = [("Series", "\(ex.totalSets)")]
        if ex.segundos > 0 { rows.append(("Segundos", "\(ex.segundos) s")) }
        else if ex.repetitions > 0 { rows.append(("Repeticiones", "\(ex.repetitions)")) }
        if ex.weight > 0 { rows.append(("Peso", WorkoutViewModel.kg(ex.weight))) }
        if ex.rir > 0 { rows.append(("RIR", "\(ex.rir)")) }
        rows.append(("Descanso", WorkoutViewModel.restText(ex.restDuration)))
        if let g = ex.muscleGroup { rows.append(("Grupo muscular", g)) }
        if let pr = viewModel.personalRecord(for: exerciseId), pr.weight > 0 {
            let when = viewModel.recordDate(for: exerciseId).map { " · \(Self.shortDate($0))" } ?? ""
            rows.append(("Récord personal", WorkoutViewModel.kg(pr.weight) + when))
            rows.append(("1RM estimado", WorkoutViewModel.kg((pr.oneRepMax * 10).rounded() / 10)))
        }

        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                HStack {
                    Text(row.0).font(.fig(14, .medium)).foregroundColor(p.mute)
                    Spacer()
                    Text(row.1).font(.bri(15)).foregroundColor(p.ink)
                }
                .padding(.vertical, 11)
                .overlay(alignment: .bottom) {
                    if i < rows.count - 1 { Rectangle().fill(p.line).frame(height: 1) }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(p.line, lineWidth: 1))
    }

    // MARK: - Series de hoy (tipo, peso, reps, RPE) y superserie

    private func todaySets(_ rec: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                UpperLabel(text: "Series de hoy", p: p)
                Spacer()
                Menu {
                    Button("Sin superserie") { setSuperset(nil) }
                    ForEach(0..<4, id: \.self) { g in
                        Button("Superserie \(Self.ssLetter(g))") { setSuperset(g) }
                    }
                } label: {
                    Text(rec.supersetGroup.map { "Superserie \(Self.ssLetter($0))" } ?? "+ Superserie")
                        .font(.fig(12, .semibold))
                        .foregroundColor(p.acc)
                }
            }

            if rec.setLogs.isEmpty {
                Text("Aún no has marcado series hoy. Toca las bolitas del ejercicio en Inicio y aquí podrás ajustar peso, repeticiones, tipo de serie y RPE.")
                    .font(.fig(13, .medium))
                    .lineSpacing(3)
                    .foregroundColor(p.mute)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(p.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            } else {
                ForEach(Array(rec.setLogs.enumerated()), id: \.element.id) { idx, log in
                    SetLogRow(index: idx + 1, log: log, p: p) { updated in
                        if let wid = workoutExerciseId, let d = day {
                            viewModel.updateSetLog(updated, for: wid, in: d)
                        }
                    }
                }
            }
        }
    }

    private var platesButton: some View {
        Button { showingPlates = true } label: {
            HStack(spacing: 12) {
                IconTile(symbol: "circle.hexagongrid.fill", size: 38, radius: 12, p: p)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calculadora de discos").font(.fig(15, .semibold)).foregroundColor(p.ink)
                    Text("Qué discos poner en cada lado de la barra").font(.fig(12, .medium)).foregroundColor(p.mute)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(p.mute)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.soft))
        }
        .buttonStyle(.plain)
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 8) {
            UpperLabel(text: "Progreso", p: p)
            ExerciseProgressChart(exerciseId: exerciseId)
        }
    }

    // MARK: - Historial

    private func history(_ ex: Exercise) -> some View {
        let entries = historyEntries(ex)
        return VStack(alignment: .leading, spacing: 8) {
            UpperLabel(text: "Historial", p: p)
            if entries.isEmpty {
                Text("Aún no has realizado este ejercicio.")
                    .font(.fig(13, .medium))
                    .foregroundColor(p.mute)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(p.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            } else {
                ForEach(entries, id: \.date) { e in
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(WeeklyCalendarView.longDate(e.date)).font(.fig(14, .semibold)).foregroundColor(p.ink)
                            Spacer()
                            Text(e.text).font(.fig(12, .semibold)).foregroundColor(p.mute)
                        }
                        // Cada serie de ese día: kg × reps, con su tipo y RPE si los tiene.
                        if !e.logs.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(Array(e.logs.enumerated()), id: \.element.id) { _, log in
                                    HStack(spacing: 3) {
                                        if let tag = log.type.shortTag {
                                            Text(tag).font(.fig(9, .bold)).foregroundColor(p.acc)
                                        }
                                        Text("\(String(format: "%g", log.weight))×\(log.reps)")
                                            .font(.fig(11, .semibold)).foregroundColor(p.ink)
                                        if let rpe = log.rpe {
                                            Text("@\(rpe)").font(.fig(9, .medium)).foregroundColor(p.mute)
                                        }
                                    }
                                    .padding(.horizontal, 7).padding(.vertical, 4)
                                    .background(Capsule().fill(p.card))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.top, 8)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(p.card)
                                Capsule().fill(p.hgrad).frame(width: geo.size.width * e.pct)
                            }
                        }
                        .frame(height: 5)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
                }
            }
        }
    }

    private func historyEntries(_ ex: Exercise) -> [(date: Date, text: String, pct: Double, logs: [SetLog])] {
        viewModel.workoutHistory
            .sorted { $0.key > $1.key }
            .prefix(30)
            .compactMap { date, byDay in
                let recs = byDay.values.flatMap { $0 }.filter { $0.exerciseId == ex.id && $0.completedSets > 0 }
                guard let r = recs.max(by: { $0.completedSets < $1.completedSets }) else { return nil }
                let kg = r.setLogs.map(\.weight).max() ?? 0
                let volume = r.setLogs.reduce(0) { $0 + $1.volume }
                var text = "\(r.completedSets)/\(ex.totalSets) series"
                if kg > 0 { text += " · máx \(WorkoutViewModel.kg(kg))" }
                if volume > 0 { text += " · \(Int(volume)) kg" }
                return (date, text, min(1, Double(r.completedSets) / Double(max(1, ex.totalSets))), r.setLogs)
            }
    }

    static func ssLetter(_ g: Int) -> String { String(UnicodeScalar(UInt8(65 + max(0, g)))) }

    /// "3 jun"
    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "d MMM"
        return f.string(from: date).replacingOccurrences(of: ".", with: "")
    }

    private func setSuperset(_ g: Int?) {
        if let wid = workoutExerciseId, let d = day {
            viewModel.setSupersetGroup(g, for: wid, in: d)
        }
    }
}

// MARK: - Fila editable de una serie registrada

/// Tipo de serie (menú), peso, repeticiones y RPE de una serie ya hecha.
private struct SetLogRow: View {
    let index: Int
    let log: SetLog
    let p: Palette
    let onUpdate: (SetLog) -> Void

    @State private var weight = ""
    @State private var reps = ""
    @State private var type: SetType = .normal
    @State private var rpe = ""

    private func tagColor(_ t: SetType) -> Color {
        switch t {
        case .normal:  return .clear
        case .warmup:  return Color(hex: "#FBBF24")
        case .drop:    return Color(hex: "#60A5FA")
        case .failure: return Pulso.danger(isDark: p.dark)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(SetType.allCases, id: \.self) { t in
                    Button(t.label) { type = t; commit() }
                }
            } label: {
                Text(type.shortTag ?? "\(index)")
                    .font(.bri(13))
                    .foregroundColor(type == .normal ? p.onacc : .white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(type == .normal ? AnyShapeStyle(p.grad) : AnyShapeStyle(tagColor(type)))
                    )
            }

            field($weight, suffix: "kg", keyboard: .decimalPad, width: 46)
            Text("×").font(.fig(14, .semibold)).foregroundColor(p.mute)
            field($reps, suffix: "reps", keyboard: .numberPad, width: 30)

            Spacer(minLength: 2)

            HStack(spacing: 4) {
                Text("RPE").font(.fig(10, .bold)).tracking(0.4).foregroundColor(p.mute)
                TextField("–", text: $rpe)
                    .keyboardType(.numberPad)
                    .font(.fig(14, .bold))
                    .foregroundColor(p.ink)
                    .frame(width: 22)
                    .multilineTextAlignment(.center)
                    .onChange(of: rpe) { _, _ in commit() }
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.card))
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
        .onAppear {
            weight = String(format: "%g", log.weight)
            reps = "\(log.reps)"
            type = log.type
            rpe = log.rpe.map { "\($0)" } ?? ""
        }
    }

    private func field(_ text: Binding<String>, suffix: String, keyboard: UIKeyboardType, width: CGFloat) -> some View {
        HStack(spacing: 4) {
            TextField("0", text: text)
                .keyboardType(keyboard)
                .font(.bri(15))
                .foregroundColor(p.ink)
                .frame(width: width)
                .multilineTextAlignment(.trailing)
                .onChange(of: text.wrappedValue) { _, _ in commit() }
            Text(suffix).font(.fig(11, .medium)).foregroundColor(p.mute)
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.card))
    }

    private func commit() {
        var updated = log
        if let w = Double(weight.replacingOccurrences(of: ",", with: ".")) { updated.weight = w }
        if let r = Int(reps) { updated.reps = r }
        updated.type = type
        updated.rpe = Int(rpe)
        onUpdate(updated)
    }
}
