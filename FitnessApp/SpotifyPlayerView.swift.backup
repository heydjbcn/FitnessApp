//
//  SpotifyPlayerView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 24/7/25.
//

import SwiftUI

struct SpotifyPlayerView: View {
    @ObservedObject private var spotifyManager = SpotifyManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var playerState: PlayerState = .compact
    
    enum PlayerState {
        case minimized   // Solo pestaña visible
        case compact     // Reproductor compacto
        case expanded    // Reproductor expandido
    }
    
    var body: some View {
        Group {
            if spotifyManager.isConnected {
                playerContent
                    .onAppear {
                        print("🎵 SpotifyPlayerView: Reproductor aparece - Conectado: \(spotifyManager.isConnected)")
                        print("🎵 SpotifyPlayerView: Canción actual: \(spotifyManager.currentTrackName)")
                    }
            } else {
                // Para debug: mostrar un indicador cuando no está conectado
                EmptyView()
                    .onAppear {
                        print("🎵 SpotifyPlayerView: NO se muestra reproductor - Conectado: \(spotifyManager.isConnected)")
                    }
            }
        }
        .onChange(of: spotifyManager.isConnected) { _, newValue in
            print("🎵 SpotifyPlayerView: Estado de conexión cambió a: \(newValue)")
        }
    }
    
    private var playerContent: some View {
        VStack(spacing: 0) {
            switch playerState {
            case .minimized:
                minimizedTab
                    .transition(.move(edge: .top).combined(with: .opacity))
                
            case .compact:
                VStack {
                    Spacer()
                    compactPlayer
                        .padding(.bottom, 90) // Justo encima de la TabBar
                        .padding(.horizontal, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                
            case .expanded:
                VStack {
                    Spacer()
                    expandedPlayer
                        .padding(.bottom, 90) // Justo encima de la TabBar
                        .padding(.horizontal, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: playerState)
    }
    
    // MARK: - Pestaña Minimizada (Arriba a la derecha, más pequeña)
    private var minimizedTab: some View {
        VStack {
            HStack {
                Spacer() // Empuja la pestaña hacia la derecha
                
                Button(action: {
                    HapticManager.shared.buttonTapped()
                    withAnimation {
                        playerState = .compact
                    }
                }) {
                    VStack(spacing: 4) { // Menos espacio entre elementos
                        // Icono pequeño de Spotify
                        Image(systemName: "music.note")
                            .font(.system(size: 12)) // Más pequeño
                            .foregroundColor(.green)
                            .frame(width: 16, height: 16) // Más pequeño
                            .background(Color.green.opacity(0.3))
                            .clipShape(Circle())
                        
                        // Texto vertical más pequeño
                        Text("Spotify")
                            .font(.system(size: 8, weight: .bold)) // Más pequeño
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            .rotationEffect(.degrees(-90))
                            .frame(height: 35) // Más pequeño
                        
                        // Indicador de estado más pequeño
                        Circle()
                            .fill(spotifyManager.isPlaying ? .green : .gray)
                            .frame(width: 4, height: 4) // Más pequeño
                        
                        // Flecha para expandir (apunta hacia abajo)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8)) // Más pequeño
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 8) // Menos padding
                    .padding(.vertical, 12) // Menos padding
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12)) // Esquinas más pequeñas
                    .shadow(color: .black.opacity(0.15), radius: 4, x: -2, y: 0) // Sombra más pequeña
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 10) // Posicionar arriba
            .padding(.trailing, 16) // Margen derecho
            
            Spacer() // Empuja todo hacia arriba
        }
    }
    
    // MARK: - Reproductor Compacto
    private var compactPlayer: some View {
        HStack(spacing: 12) {
            // Carátula del álbum
            Image(systemName: "music.note")
                .font(.title3)
                .frame(width: 48, height: 48)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    HapticManager.shared.buttonTapped()
                    withAnimation {
                        playerState = .expanded
                    }
                }
            
            // Info de la canción
            VStack(alignment: .leading, spacing: 2) {
                Text(spotifyManager.currentTrackName)
                    .font(.caption.bold())
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    .lineLimit(1)
                
                Text(spotifyManager.currentArtistName)
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture {
                HapticManager.shared.buttonTapped()
                withAnimation {
                    playerState = .expanded
                }
            }
            
            // Controles básicos
            HStack(spacing: 16) {
                Button(action: {
                    HapticManager.shared.buttonTapped()
                    spotifyManager.skipPrevious()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                Button(action: {
                    HapticManager.shared.buttonTapped()
                    spotifyManager.togglePlayPause()
                }) {
                    Image(systemName: spotifyManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                
                Button(action: {
                    HapticManager.shared.buttonTapped()
                    spotifyManager.skipNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                // Botón cerrar
                Button(action: {
                    HapticManager.shared.buttonTapped()
                    withAnimation {
                        playerState = .minimized
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
    }
    
    // MARK: - Reproductor Expandido
    private var expandedPlayer: some View {
        VStack(spacing: 16) {
            // Barra superior con botones
            HStack {
                Button(action: {
                    HapticManager.shared.buttonTapped()
                    withAnimation {
                        playerState = .compact
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("Reproduciendo")
                    .font(.caption.bold())
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                
                Spacer()
                
                // Botón cerrar (minimizar completamente)
                Button(action: {
                    HapticManager.shared.buttonTapped()
                    withAnimation {
                        playerState = .minimized
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            
            // Información de la canción
            VStack(spacing: 12) {
                // Carátula grande
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .frame(width: 120, height: 120)
                    .background(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                // Info de la canción
                VStack(spacing: 4) {
                    Text(spotifyManager.currentTrackName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(spotifyManager.currentArtistName)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        .lineLimit(1)
                }
                .padding(.horizontal)
            }
            
            // Controles grandes
            HStack(spacing: 40) {
                Button(action: {
                    HapticManager.shared.buttonTapped()
                    spotifyManager.skipPrevious()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
                
                Button(action: {
                    HapticManager.shared.buttonTapped()
                    spotifyManager.togglePlayPause()
                }) {
                    Image(systemName: spotifyManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                }
                
                Button(action: {
                    HapticManager.shared.buttonTapped()
                    spotifyManager.skipNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                }
            }
            
            // Estado
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text(spotifyManager.isPlaying ? "Reproduciendo" : "Pausado")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: -5)
    }
}
