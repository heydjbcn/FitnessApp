//
//  PulsoComponents.swift
//  FitnessApp
//
//  Piezas visuales del rediseño «Pulso». Todo lo que se repite en más de una
//  pantalla vive aquí para que el look salga de un sitio y no de 40 copias.
//

import SwiftUI

// MARK: - Tarjeta de cristal

/// El contenedor base del diseño: superficie translúcida, borde de un pelo y
/// sombra suave. Sustituye al viejo `CardStyle`.
struct GlassCard<Content: View>: View {
    var isDark: Bool
    var radius: CGFloat = Pulso.Radius.card
    var padding: CGFloat = Pulso.Space.card
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Pulso.card(isDark: isDark))
                    .background(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(isDark ? 0.5 : 0))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Pulso.line(isDark: isDark), lineWidth: 1)
            )
            .shadow(color: Pulso.cardShadow(isDark: isDark), radius: 14, x: 0, y: 8)
    }
}

// MARK: - Texto con degradado

/// Titular pintado con el degradado del acento, como los "Hombro y core"
/// del prototipo.
struct GradientText: View {
    let text: String
    let font: Font
    let accent: AccentColor
    let isDark: Bool

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(accent.gradient(isDark: isDark))
    }
}

// MARK: - Barra de progreso

struct PulsoProgressBar: View {
    var value: Double            // 0…1
    var accent: AccentColor
    var isDark: Bool
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Pulso.soft(isDark: isDark))
                Capsule()
                    .fill(accent.gradient(isDark: isDark))
                    .frame(width: max(0, min(1, value)) * geo.size.width)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Métrica en tarjeta pequeña

/// Las tres cifras de la cabecera de Inicio: Series, Tonelaje, Quedan.
struct StatTile: View {
    let label: String
    let value: String
    var unit: String? = nil
    let isDark: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(Pulso.mute(isDark: isDark))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppFonts.metric)
                    .foregroundColor(Pulso.ink(isDark: isDark))
                if let unit {
                    Text(unit)
                        .font(AppFonts.caption)
                        .foregroundColor(Pulso.mute(isDark: isDark))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: Pulso.Radius.chip, style: .continuous)
                .fill(Pulso.soft(isDark: isDark))
        )
    }
}

// MARK: - Chip de día

/// Cada día de la tira semanal: seleccionado se rellena con el degradado,
/// hecho muestra un check, y si no, el número de ejercicios.
struct DayChip: View {
    let day: WorkoutDay
    let isSelected: Bool
    let isDone: Bool
    let count: Int
    let accent: AccentColor
    let isDark: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(day.shortLabel)
                    .font(AppFonts.label)
                    .foregroundColor(foreground)
                if isDone && !isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(accent.accent(isDark: isDark))
                } else {
                    Text("\(count)")
                        .font(AppFonts.subtitle)
                        .foregroundColor(foreground)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: Pulso.Radius.chip, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Pulso.line(isDark: isDark), lineWidth: 1)
            )
            .shadow(color: isSelected ? Pulso.glow(accent, isDark: isDark) : .clear,
                    radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        isSelected ? accent.onAccent(isDark: isDark) : Pulso.ink(isDark: isDark)
    }

    @ViewBuilder private var background: some View {
        let shape = RoundedRectangle(cornerRadius: Pulso.Radius.chip, style: .continuous)
        if isSelected {
            shape.fill(accent.gradient(isDark: isDark))
        } else {
            shape.fill(Pulso.card(isDark: isDark))
        }
    }
}

// MARK: - Píldora

/// Etiqueta redonda: la racha, el estado "Hecho"/"En curso", los badges.
struct PulsoPill: View {
    let text: String
    var icon: String? = nil
    var filled: Bool = false
    var accent: AccentColor
    var isDark: Bool

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
            }
            Text(text).font(AppFonts.label)
        }
        .foregroundColor(filled ? accent.onAccent(isDark: isDark) : accent.accent(isDark: isDark))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Group {
                if filled {
                    Capsule().fill(accent.gradient(isDark: isDark))
                } else {
                    Capsule().fill(accent.accent(isDark: isDark).opacity(isDark ? 0.16 : 0.12))
                }
            }
        )
    }
}

// MARK: - Bolita de serie

/// El control con el que se marca cada serie completada.
struct SetDot: View {
    let isDone: Bool
    let accent: AccentColor
    let isDark: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isDone ? AnyShapeStyle(accent.gradient(isDark: isDark))
                                 : AnyShapeStyle(Pulso.soft(isDark: isDark)))
                    .frame(width: 40, height: 40)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(accent.onAccent(isDark: isDark))
                }
            }
            .shadow(color: isDone ? Pulso.glow(accent, isDark: isDark) : .clear, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDone)
    }
}

// MARK: - Cabecera de sección

/// "Ejercicios ————— + Añadir"
struct SectionHeader: View {
    let title: String
    var actionLabel: String? = nil
    var accent: AccentColor
    var isDark: Bool
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(AppFonts.title)
                .foregroundColor(Pulso.ink(isDark: isDark))
            Spacer()
            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(accent.accent(isDark: isDark))
                }
            }
        }
    }
}

// MARK: - Botón principal

/// Botón ancho relleno con el degradado del acento.
struct PulsoPrimaryButton: View {
    let title: String
    var icon: String? = nil
    let accent: AccentColor
    let isDark: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).font(AppFonts.subtitle)
            }
            .foregroundColor(accent.onAccent(isDark: isDark))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule().fill(accent.gradient(isDark: isDark))
            )
            .shadow(color: Pulso.glow(accent, isDark: isDark), radius: 16, y: 6)
        }
        .buttonStyle(.plain)
    }
}

/// Botón secundario: mismo tamaño, solo contorno.
struct PulsoSecondaryButton: View {
    let title: String
    var icon: String? = nil
    let accent: AccentColor
    let isDark: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).font(AppFonts.subtitle)
            }
            .foregroundColor(Pulso.ink(isDark: isDark))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Capsule().fill(Pulso.card(isDark: isDark)))
            .overlay(Capsule().strokeBorder(Pulso.line(isDark: isDark), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Estado vacío

struct PulsoEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let isDark: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .light))
                .foregroundColor(Pulso.mute(isDark: isDark))
            Text(title)
                .font(AppFonts.subtitle)
                .foregroundColor(Pulso.ink(isDark: isDark))
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(Pulso.mute(isDark: isDark))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
    }
}
