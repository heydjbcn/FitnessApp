//
//  SpotifyPlayerViews.swift
//  ChamaFit
//
//  El reproductor de Spotify del prototipo: píldora compacta sobre la barra
//  de pestañas, hoja expandida con la portada grande y pestaña minimizada al
//  borde derecho.
//

import SwiftUI

// MARK: - Píldora compacta

struct SpotifyPill: View {
    @ObservedObject var spotify: SpotifyManager
    let p: Palette

    var body: some View {
        HStack(spacing: 12) {
            Button { spotify.expanded = true } label: { artwork(size: 44, radius: 12) }
                .buttonStyle(.plain)
            Button { spotify.expanded = true } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(spotify.trackTitle.isEmpty ? "Nada sonando" : spotify.trackTitle)
                        .font(.fig(13, .bold)).foregroundColor(p.ink).lineLimit(1)
                    Text((spotify.trackArtist.isEmpty ? "Spotify" : String(localized: "\(spotify.trackArtist) · Spotify")).loc)
                        .font(.fig(12, .medium)).foregroundColor(p.mute).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            HStack(spacing: 4) {
                control("backward.end.fill", size: 34) { spotify.previous() }
                Button { spotify.togglePlayPause() } label: {
                    Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(p.ink)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(p.soft))
                }
                .buttonStyle(.plain)
                control("forward.end.fill", size: 34) { spotify.next() }
                Button { spotify.setPresentation(.minimized) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(p.mute)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .padding(.leading, 2)
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Pulso.navBar(isDark: p.dark)))
        )
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(p.line, lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 15, y: 10)
    }

    private func control(_ symbol: String, size: CGFloat, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(p.ink)
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func artwork(size: CGFloat, radius: CGFloat) -> some View {
        if let img = spotify.artwork {
            Image(uiImage: img).resizable().scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            Image(systemName: "music.note")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(p.onacc)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(p.grad))
        }
    }
}

// MARK: - Pestaña minimizada (borde derecho)

struct SpotifyMiniTab: View {
    @ObservedObject var spotify: SpotifyManager
    let p: Palette

    var body: some View {
        Button { spotify.setPresentation(.compact) } label: {
            VStack(spacing: 8) {
                Image(systemName: "music.note")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(p.ink)
                Circle()
                    .fill(spotify.isPlaying ? p.acc : p.mute)
                    .frame(width: 6, height: 6)
                    .shadow(color: spotify.isPlaying ? p.acc : .clear, radius: 4)
            }
            .padding(.vertical, 10)
            .padding(.leading, 12)
            .padding(.trailing, 10)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 14).fill(Pulso.navBar(isDark: p.dark)))
            )
            .overlay(UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 14).strokeBorder(p.line, lineWidth: 1))
            .shadow(color: .black.opacity(0.2), radius: 12, y: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hoja expandida

struct SpotifyExpandedSheet: View {
    @ObservedObject var spotify: SpotifyManager
    let p: Palette
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PulsoSheet(p: p) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(RadialGradient(colors: [p.glow1, .clear], center: .center, startRadius: 0, endRadius: 130))
                    .frame(width: 260, height: 260)
                    .offset(x: 60, y: -80)
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    HStack {
                        CloseCircle(p: p) { dismiss() }
                        Spacer()
                        UpperLabel(text: "Reproduciendo · Spotify", p: p, spacing: 0.08)
                        Spacer()
                        Button { spotify.setPresentation(.minimized); dismiss() } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(p.ink)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(p.soft))
                                .overlay(Circle().strokeBorder(p.line, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)

                    Group {
                        if let img = spotify.artwork {
                            Image(uiImage: img).resizable().scaledToFill()
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 64, weight: .semibold))
                                .foregroundColor(p.onacc)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(p.grad)
                        }
                    }
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: p.glow1, radius: 25, y: 20)
                    .padding(.top, 26)

                    Text(spotify.trackTitle.isEmpty ? "Nada sonando" : spotify.trackTitle)
                        .font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 22)
                    Text(spotify.trackArtist.isEmpty ? "Dale a reproducir en Spotify" : spotify.trackArtist)
                        .font(.fig(14, .medium)).foregroundColor(p.mute)
                        .padding(.top, 4)

                    HStack(spacing: 28) {
                        big("backward.end.fill", 48, fill: false) { spotify.previous() }
                        big(spotify.isPlaying ? "pause.fill" : "play.fill", 72, fill: true) { spotify.togglePlayPause() }
                        big("forward.end.fill", 48, fill: false) { spotify.next() }
                    }
                    .padding(.top, 26)

                    if !spotify.isConnected {
                        Text(spotify.lastError ?? "Spotify no está conectado.")
                            .font(.fig(12, .medium)).foregroundColor(p.danger)
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)
                        SoftButton(title: "Conectar de nuevo", height: 42, p: p) { spotify.connect() }
                            .padding(.horizontal, 60)
                            .padding(.top, 8)
                    }
                }
                .padding(.bottom, 44)
            }
        }
        .presentationDetents([.height(560)])
    }

    private func big(_ symbol: String, _ size: CGFloat, fill: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundColor(fill ? p.onacc : p.ink)
                .frame(width: size, height: size)
                .background(Circle().fill(fill ? AnyShapeStyle(p.grad) : AnyShapeStyle(Color.clear)))
                .shadow(color: fill ? p.glow1 : .clear, radius: 15, y: 12)
        }
        .buttonStyle(.plain)
    }
}
