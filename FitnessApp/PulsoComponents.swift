//
//  PulsoComponents.swift
//  FitnessApp
//
//  Piezas visuales del rediseño «Pulso», copiadas del marcado del prototipo
//  (ChamaFit.dc.html) con sus medidas: radios, pesos de letra, bordes y
//  resplandores. Todo lo que se repite en más de una pantalla vive aquí.
//

import SwiftUI
import PhotosUI

// MARK: - Paleta resuelta

/// Los colores del tema vivo, ya resueltos. Equivale a las variables CSS del
/// prototipo (--bg, --card, --soft, --line, --ink, --mute, --acc, --onacc…).
struct Palette {
    let dark: Bool
    let accent: AccentColor

    var bg: Color { Pulso.background(isDark: dark) }
    var card: Color { Pulso.card(isDark: dark) }
    var soft: Color { Pulso.soft(isDark: dark) }
    var line: Color { Pulso.line(isDark: dark) }
    var ink: Color { Pulso.ink(isDark: dark) }
    var mute: Color { Pulso.mute(isDark: dark) }
    var sheet: Color { Pulso.sheet(isDark: dark) }
    var danger: Color { Pulso.danger(isDark: dark) }
    var acc: Color { accent.accent(isDark: dark) }
    var onacc: Color { accent.onAccent(isDark: dark) }
    /// 135°: cuadros, chips, bolitas.
    var grad: LinearGradient { accent.gradient(isDark: dark) }
    /// 90°: botones, barras, texto.
    var hgrad: LinearGradient { accent.hGradient(isDark: dark) }
    var glow1: Color { accent.gradientColors(isDark: dark)[0].opacity(dark ? 0.5 : 0.22) }
    var glow2: Color { accent.gradientColors(isDark: dark)[1].opacity(dark ? 0.32 : 0.2) }
}

extension ThemeManager {
    var p: Palette { Palette(dark: isDarkMode, accent: selectedAccentColor) }
}

// MARK: - Fondo

/// Fondo de todas las pantallas del prototipo: el color base con dos
/// resplandores del acento, violeta arriba a la izquierda y cian a la derecha.
struct PulsoBackground: View {
    let p: Palette

    var body: some View {
        ZStack {
            p.bg
            Circle().fill(p.glow1).frame(width: 380, height: 380).blur(radius: 100)
                .offset(x: -110, y: -330)
            Circle().fill(p.glow2).frame(width: 320, height: 320).blur(radius: 110)
                .offset(x: 190, y: 40)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Tarjeta de cristal

extension View {
    /// `background:var(--card); border:1px solid var(--line); border-radius:R`
    func pulsoCard(_ p: Palette, radius: CGFloat = 22, dashed: Bool = false) -> some View {
        background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(p.card))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(p.line, style: StrokeStyle(lineWidth: 1, dash: dashed ? [5, 4] : []))
            )
    }

    /// Superficie secundaria dentro de una tarjeta.
    func pulsoSoft(_ p: Palette, radius: CGFloat, bordered: Bool = false) -> some View {
        background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(p.soft))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(bordered ? p.line : .clear, lineWidth: 1)
            )
    }
}

// MARK: - Texto

/// Titular pintado con el degradado horizontal del acento.
struct GradientText: View {
    let text: String
    let font: Font
    let p: Palette
    var tracking: CGFloat = 0

    var body: some View {
        Text(text)
            .font(font)
            .tracking(tracking)
            .foregroundStyle(p.hgrad)
    }
}

/// Rótulo pequeño en mayúsculas: "NOMBRE DEL DÍA", "APARIENCIA"…
struct UpperLabel: View {
    let text: String
    let p: Palette
    var spacing: CGFloat = 0.06

    var body: some View {
        Text(text.uppercased())
            .font(.fig(11, .medium))
            .tracking(spacing * 11)
            .foregroundColor(p.mute)
    }
}

/// Cabecera de pantalla: título grande y, debajo, la línea explicativa.
struct ScreenHeader<Trailing: View>: View {
    let title: String
    var size: CGFloat = 30
    var subtitle: String? = nil
    let p: Palette
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text(title)
                    .font(.bri(size))
                    .em(-0.03, size: size)
                    .foregroundColor(p.ink)
                    .lineLimit(1)
                Spacer(minLength: 0)
                trailing
            }
            if let subtitle {
                Text(subtitle)
                    .font(.fig(13, .medium))
                    .foregroundColor(p.mute)
                    .padding(.top, size >= 30 ? 4 : 6)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, size: CGFloat = 30, subtitle: String? = nil, p: Palette) {
        self.init(title: title, size: size, subtitle: subtitle, p: p) { EmptyView() }
    }
}

// MARK: - Botones

/// Botón principal: píldora con degradado horizontal y resplandor.
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var height: CGFloat = 48
    var fontSize: CGFloat = 15
    var enabled: Bool = true
    let p: Palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: fontSize - 1, weight: .bold)) }
                Text(title).font(.fig(fontSize, .bold))
            }
            .foregroundColor(enabled ? p.onacc : p.mute)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                Capsule().fill(enabled ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft))
            )
            .overlay(Capsule().strokeBorder(enabled ? .clear : p.line, lineWidth: 1))
            .shadow(color: enabled ? p.glow1 : .clear, radius: 12, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Botón secundario: píldora gris suave con borde.
struct SoftButton: View {
    let title: String
    var icon: String? = nil
    var height: CGFloat = 44
    var fontSize: CGFloat = 14
    var color: Color? = nil
    var filled: Bool = true
    let p: Palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: fontSize - 1, weight: .semibold)) }
                Text(title).font(.fig(fontSize, .semibold))
            }
            .foregroundColor(color ?? p.ink)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Capsule().fill(filled ? p.soft : .clear))
            .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Botón redondo de 36 con la ✕ de cerrar las hojas.
struct CloseCircle: View {
    let p: Palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(p.ink)
                .frame(width: 36, height: 36)
                .background(Circle().fill(p.soft))
                .overlay(Circle().strokeBorder(p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Selector de dos o más opciones en píldora: Semana/Mes, Oscuro/Claro.
struct PulsoSegmented: View {
    let options: [String]
    @Binding var selection: Int
    var onCard: Bool = true
    let p: Palette

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { selection = i }
                    HapticManager.shared.segmentChanged()
                } label: {
                    Text(options[i])
                        .font(.fig(12, i == selection ? .bold : .semibold))
                        .foregroundColor(i == selection ? p.onacc : p.mute)
                        .padding(.horizontal, 14)
                        .frame(height: 30)
                        .background(Capsule().fill(i == selection ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(Color.clear)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(onCard ? p.card : p.soft))
        .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
        .fixedSize()
    }
}

/// Interruptor de 48×28 del prototipo.
struct PulsoToggle: View {
    @Binding var isOn: Bool
    let p: Palette

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft))
                    .overlay(Capsule().strokeBorder(isOn ? .clear : p.line, lineWidth: 1))
                Circle()
                    .fill(isOn ? Color.white : p.mute)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(isOn ? 0.3 : 0), radius: 1.5, y: 1)
                    .padding(2)
            }
            .frame(width: 48, height: 28)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Iconos

/// Cuadro con icono: gris suave o relleno de degradado.
struct IconTile: View {
    let symbol: String
    var size: CGFloat = 38
    var radius: CGFloat = 12
    var gradient: Bool = false
    var glow: Bool = false
    var iconSize: CGFloat? = nil
    let p: Palette

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: iconSize ?? size * 0.42, weight: .semibold))
            .foregroundColor(gradient ? p.onacc : p.acc)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(gradient ? AnyShapeStyle(p.grad) : AnyShapeStyle(p.soft))
            )
            .shadow(color: glow ? p.glow1 : .clear, radius: size * 0.2, y: size * 0.14)
    }
}

/// Icono de un ejercicio: su foto si la tiene, si no su símbolo.
struct ExerciseIcon: View {
    let exercise: Exercise
    var size: CGFloat = 40
    var radius: CGFloat = 13
    var gradient: Bool = false
    let p: Palette

    var body: some View {
        if let data = exercise.imageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            IconTile(symbol: ExerciseSymbols.symbol(for: exercise), size: size, radius: radius,
                     gradient: gradient, glow: gradient, p: p)
        }
    }
}

/// Los doce iconos del prototipo, traducidos a SF Symbols.
enum ExerciseSymbols {
    static let all: [(symbol: String, label: String)] = [
        ("dumbbell.fill", "Mancuerna"),
        ("figure.strengthtraining.traditional", "Barra"),
        ("figure.run", "Cardio"),
        ("figure.outdoor.cycle", "Bici"),
        ("heart.fill", "Salud"),
        ("bolt.fill", "Potencia"),
        ("timer", "Tiempo"),
        ("flame.fill", "Quema"),
        ("target", "Precisión"),
        ("star.fill", "Favorito"),
        ("figure.core.training", "Core"),
        ("figure.strengthtraining.functional", "Fuerza"),
    ]

    /// El icono guardado si iOS lo conoce; si no (datos antiguos con nombres
    /// que no existen), la mancuerna — antes esos ejercicios salían sin icono.
    static func symbol(for exercise: Exercise) -> String {
        if let name = exercise.sfSymbolIcon, UIImage(systemName: name) != nil { return name }
        return "dumbbell.fill"
    }
}

// MARK: - Inicio: métricas, días, series

/// Las tres cifras de la tarjeta de sesión: Series, Tonelaje, Quedan.
struct StatTile: View {
    let label: String
    let value: String
    var unit: String? = nil
    let p: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.fig(11, .medium))
                .foregroundColor(p.mute)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.bri(18))
                    .foregroundColor(p.ink)
                if let unit {
                    Text(unit)
                        .font(.bri(13))
                        .foregroundColor(p.mute)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
    }
}

/// Un día de la tira semanal de Inicio.
struct DayChip: View {
    let day: WorkoutDay
    let isSelected: Bool
    let isDone: Bool
    let count: Int
    let p: Palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(day.shortLabel)
                    .font(.fig(12, isSelected ? .bold : .semibold))
                if isDone && !isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(p.acc)
                        .frame(height: 16)
                } else {
                    Text("\(count)")
                        .font(.bri(16))
                        .frame(height: 16)
                }
            }
            .foregroundColor(isSelected ? p.onacc : p.mute)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(p.grad) : AnyShapeStyle(p.card))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? .clear : p.line, lineWidth: 1)
            )
            .shadow(color: isSelected ? p.glow1 : .clear, radius: 10, y: 8)
        }
        .buttonStyle(.plain)
    }
}

/// "Hecho" (texto de acento sobre gris) o "En curso" (relleno de degradado).
struct StatusPill: View {
    let text: String
    var filled: Bool = false
    let p: Palette

    var body: some View {
        Text(text)
            .font(.fig(11, .bold))
            .foregroundColor(filled ? p.onacc : p.acc)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(filled ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
    }
}

/// Bolita de 42 con la que se marca cada serie.
struct SetDot: View {
    var number: Int? = nil
    let isDone: Bool
    let p: Palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isDone ? AnyShapeStyle(p.grad) : AnyShapeStyle(p.soft))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isDone ? .clear : p.line, lineWidth: 1)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(p.onacc)
                } else if let number {
                    Text("\(number)")
                        .font(.fig(14, .bold))
                        .foregroundColor(p.mute)
                }
            }
            .frame(width: 42, height: 42)
            .shadow(color: isDone ? p.glow1 : .clear, radius: 8, y: 6)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isDone)
    }
}

/// Fila de lista dentro de una tarjeta: icono, nombre, datos y chevrón.
struct ExerciseListRow: View {
    let exercise: Exercise
    let meta: String
    let p: Palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: ExerciseSymbols.symbol(for: exercise))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(p.acc)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.fig(14, .semibold))
                        .foregroundColor(p.ink)
                        .lineLimit(1)
                    Text(meta)
                        .font(.fig(12, .medium))
                        .foregroundColor(p.mute)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(p.mute)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
        }
        .buttonStyle(.plain)
    }
}

/// Etiqueta de día o de récord en las tarjetas de ejercicio.
struct DayTag: View {
    let text: String
    var icon: String? = nil
    var filled: Bool = false
    let p: Palette

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).font(.system(size: 9, weight: .bold)) }
            Text(text.uppercased())
                .font(.fig(10, .bold))
                .tracking(0.4)
        }
        .foregroundColor(filled ? p.onacc : p.acc)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(filled ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
        .overlay(Capsule().strokeBorder(filled ? .clear : p.line, lineWidth: 1))
    }
}

// MARK: - Estado vacío

/// Tarjeta de borde discontinuo con icono, título, explicación y acciones.
struct EmptyCard<Actions: View>: View {
    let icon: String
    let title: String
    let message: String
    let p: Palette
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: 0) {
            IconTile(symbol: icon, size: 56, radius: 18, p: p)
            Text(title)
                .font(.fig(17, .bold))
                .foregroundColor(p.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
            Text(message)
                .font(.fig(13))
                .lineSpacing(3)
                .foregroundColor(p.mute)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
            VStack(spacing: 8) { actions }
                .padding(.top, 18)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity)
        .pulsoCard(p, radius: 22, dashed: true)
    }
}

// MARK: - Calendario mensual

/// Rejilla de mes del prototipo (Calendario ▸ Mes e Historial).
struct MonthGrid: View {
    @Binding var month: Date
    @Binding var selected: Date
    let hasWorkout: (Date) -> Bool
    let p: Palette

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "es_ES")
        c.firstWeekday = 2
        return c
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: month).capitalized
    }

    /// 42 celdas; las que no son del mes van a nil.
    private var cells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let first = interval.start
        let lead = (calendar.component(.weekday, from: first) + 5) % 7
        let days = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        var out: [Date?] = Array(repeating: nil, count: lead)
        for d in 0..<days { out.append(calendar.date(byAdding: .day, value: d, to: first)) }
        // Siempre seis filas, como el prototipo: la tarjeta no cambia de alto al pasar de mes.
        while out.count < 42 { out.append(nil) }
        return out
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                arrow("chevron.left", -1)
                Spacer()
                Text(monthLabel)
                    .font(.bri(16))
                    .foregroundColor(p.ink)
                Spacer()
                arrow("chevron.right", 1)
            }
            .padding(.horizontal, 4)

            HStack(spacing: 0) {
                ForEach(["L", "M", "X", "J", "V", "S", "D"], id: \.self) { d in
                    Text(d)
                        .font(.fig(11, .semibold))
                        .foregroundColor(p.mute)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 14)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        cell(date)
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(.top, 6)
        }
        .padding(.top, 16)
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .pulsoCard(p, radius: 24)
    }

    private func arrow(_ symbol: String, _ dir: Int) -> some View {
        Button {
            if let m = calendar.date(byAdding: .month, value: dir, to: month) { month = m }
            HapticManager.shared.selectionFeedback()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(p.ink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(p.soft))
                .overlay(Circle().strokeBorder(p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func cell(_ date: Date) -> some View {
        let isSel = calendar.isDate(date, inSameDayAs: selected)
        let isToday = calendar.isDateInToday(date)
        let worked = hasWorkout(date)
        return Button {
            selected = date
            HapticManager.shared.selectionFeedback()
        } label: {
            // El cuadrado lo marca un Color.clear con proporción 1:1 que ocupa
            // todo el ancho de la columna: así todas las celdas miden igual y las
            // filas no bailan según haya huecos o no (antes el número mandaba en
            // el tamaño y el día elegido salía como una pastilla pequeña).
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSel ? AnyShapeStyle(p.grad) : AnyShapeStyle(Color.clear))
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isToday && !isSel ? p.acc : .clear, lineWidth: 1.5)
                        VStack(spacing: 3) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(isSel ? .bri(14) : .fig(14, isToday ? .bold : .medium))
                                .foregroundColor(isSel ? p.onacc : p.ink)
                            if worked {
                                Circle()
                                    .fill(isSel ? p.onacc : p.acc)
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                }
                .shadow(color: isSel ? p.glow1 : .clear, radius: 8, y: 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hojas modales

/// Contenedor de hoja del prototipo: fondo --sheet, esquinas de 30 y tirador.
struct PulsoSheet<Content: View, Footer: View>: View {
    let p: Palette
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(spacing: 0) {
            content
            footer
        }
        .background(p.sheet.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .presentationBackground(p.sheet)
    }
}

extension PulsoSheet where Footer == EmptyView {
    init(p: Palette, @ViewBuilder content: () -> Content) {
        self.init(p: p, content: content) { EmptyView() }
    }
}

/// Pie fijo de las hojas: línea arriba y los botones.
struct SheetFooter<Content: View>: View {
    let p: Palette
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(p.line).frame(height: 1)
            HStack(spacing: 8) { content }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
        .background(p.sheet)
    }
}

/// Campo de texto del prototipo: gris suave, radio 16, borde de un pelo.
struct PulsoField: View {
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 48
    var fontSize: CGFloat = 15
    var keyboard: UIKeyboardType = .default
    var centered: Bool = false
    var focusedBorder: Bool = false
    let p: Palette

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(p.mute.opacity(0.8)))
            .font(.fig(fontSize, .semibold))
            .foregroundColor(p.ink)
            .keyboardType(keyboard)
            .multilineTextAlignment(centered ? .center : .leading)
            .padding(.horizontal, 16)
            .frame(height: height)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(focusedBorder ? p.acc : p.line, lineWidth: 1)
            )
    }
}

// MARK: - Temporizador de descanso flotante

/// El descanso del prototipo: borde de degradado, cifra grande en degradado,
/// barra de progreso, "+30 s" y "Parar". Flota sobre la barra de pestañas en
/// cualquier pantalla.
struct PulsoRestTimer: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager

    private var p: Palette { themeManager.p }

    private var progress: Double {
        guard viewModel.currentTimerDuration > 0 else { return 0 }
        return 1 - Double(viewModel.timeRemaining) / Double(viewModel.currentTimerDuration)
    }

    private var clock: String {
        String(format: "%d:%02d", viewModel.timeRemaining / 60, viewModel.timeRemaining % 60)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(clock)
                .font(.bri(30))
                .em(-0.02, size: 30)
                .monospacedDigit()
                .foregroundStyle(p.hgrad)
                .frame(minWidth: 64, alignment: .leading)
                .contentTransition(.numericText())

            VStack(alignment: .leading, spacing: 0) {
                UpperLabel(text: "Descanso", p: p)
                    .font(.fig(11, .bold))
                Text(viewModel.timerLabel)
                    .font(.fig(13, .medium))
                    .foregroundColor(p.ink)
                    .lineLimit(1)
                    .padding(.top, 2)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(p.soft)
                        Capsule().fill(p.hgrad)
                            .frame(width: geo.size.width * progress)
                            .animation(.linear(duration: 1), value: progress)
                    }
                }
                .frame(height: 4)
                .padding(.top, 8)
            }

            Button { viewModel.extendTimer(by: 30) } label: {
                Text("+30 s")
                    .font(.fig(12, .bold))
                    .foregroundColor(p.ink)
                    .padding(.horizontal, 10)
                    .frame(height: 36)
                    .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                HapticManager.shared.timerStopped()
                viewModel.stopTimer()
            } label: {
                Text("Parar")
                    .font(.fig(13, .bold))
                    .foregroundColor(p.ink)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Capsule().fill(p.soft))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 18)
        .padding(.trailing, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 21, style: .continuous).fill(Pulso.navBar(isDark: p.dark)))
        )
        .padding(1.5)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(p.hgrad))
        .shadow(color: p.glow1, radius: 17, y: 14)
    }
}

// MARK: - Selector de foto

/// Botón que abre la fototeca y devuelve los datos de la imagen elegida.
struct PhotoPickerButton<Label: View>: View {
    @Binding var imageData: Data?
    @ViewBuilder var label: Label
    @State private var item: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $item, matching: .images) { label }
            .buttonStyle(.plain)
            .onChange(of: item) { _, newItem in
                Task {
                    guard let data = try? await newItem?.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    // Se guarda reducida: la foto va a UserDefaults.
                    let resized = image.resizedForStorage(maxSide: 900)
                    await MainActor.run { imageData = resized.jpegData(compressionQuality: 0.8) }
                }
            }
    }
}

extension UIImage {
    func resizedForStorage(maxSide: CGFloat) -> UIImage {
        let scale = min(1, maxSide / max(size.width, size.height))
        guard scale < 1 else { return self }
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: target).image { _ in draw(in: CGRect(origin: .zero, size: target)) }
    }
}
