//
//  SettingsTabView.swift
//  FitnessApp
//
//  Pestaña Configuración del rediseño «Pulso»: perfil, apariencia, ajustes
//  de entrenamiento, música y avisos y el tutorial. Añade lo que la app ya
//  tenía y el prototipo no dibuja: Coach IA y exportar los datos.
//

import SwiftUI
import UniformTypeIdentifiers
import AppIntents
import Combine

struct SettingsTabView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager

    /// Arranca el tutorial de siete pasos (lo pinta ContentView).
    var onStartTutorial: () -> Void = {}

    @AppStorage("keepScreenOn", store: AppDefaults.store) private var keepScreenOn = false
    @AppStorage("autoFocusMode", store: AppDefaults.store) private var autoFocusMode = true
    @AppStorage("hapticsEnabled", store: AppDefaults.store) private var hapticsEnabled = true
    @AppStorage("voiceCues", store: AppDefaults.store) private var voiceCues = true
    @ObservedObject private var spotify = SpotifyManager.shared
    @ObservedObject private var health = HealthManager.shared

    @State private var showingProfile = false
    @State private var showingNotifications = false
    @State private var showingCoach = false
    @State private var showingTrainingProfile = false
    @State private var showingExperiments = false
    @State private var showingNutrition = false
    @State private var showingFriends = false
    @State private var showingAbout = false
    @State private var calendarSync = SystemCalendar.enabled
    @State private var importingBackup = false
    @State private var pendingRestore: URL? = nil
    @State private var restoreError: String? = nil
    @State private var confirmReset = false

    private var p: Palette { themeManager.p }
    private static let restPresets = [30, 60, 90, 120, 180]

    var body: some View {
        ZStack(alignment: .top) {
            PulsoBackground(p: p)
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(title: "Configuración", p: p)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        profileRow
                        section("Apariencia")
                        appearanceCard
                        section("Entrenamiento")
                        trainingCard
                        section("Música y avisos")
                        musicCard
                        section("iPhone y Apple Watch")
                        iphoneCard
                        section("Coach y datos")
                        extrasCard
                        tutorialCard.padding(.top, 20)
                        Button { showingAbout = true } label: {
                            navRow(icon: "info.circle", title: "Acerca de ChamaFit", sub: String(localized: "Versión \(AboutView.version) · privacidad, créditos y ayuda"))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .pulsoCard(p, radius: 22)
                        .padding(.top, 12)
                        .accessibilityIdentifier("settings.about")
                        Text("ChamaFit · rediseño «Pulso»")
                            .font(.fig(11, .medium))
                            .foregroundColor(p.mute)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 22)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 120)
                }
                .padding(.top, 10)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileSheet()
                .environmentObject(userManager)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsSheet()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingTrainingProfile) {
            TrainingProfileSheet()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView().environmentObject(themeManager)
        }
        .sheet(isPresented: $showingFriends) {
            FriendsView()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
                .environmentObject(userManager)
        }
        .sheet(isPresented: $showingNutrition) {
            NutritionSettingsSheet()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingExperiments) {
            ExperimentsView()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingCoach) {
            CoachAIView()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
    }

    private func section(_ title: String) -> some View {
        UpperLabel(text: title, p: p, spacing: 0.08)
            .padding(.horizontal, 6)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    // MARK: - Perfil

    private var profileBits: String {
        var bits: [String] = []
        if !userManager.userAge.isEmpty { bits.append(String(localized: "\(userManager.userAge) años")) }
        if !userManager.userHeight.isEmpty { bits.append(String(localized: "\(userManager.userHeight) cm")) }
        if let kg = Double(userManager.userWeight.replacingOccurrences(of: ",", with: ".")), kg > 0 {
            bits.append(Units.format(kg))
        }
        return bits.isEmpty ? "Añade edad, altura y peso" : bits.joined(separator: " · ")
    }

    private var profileRow: some View {
        Button { showingProfile = true } label: {
            HStack(spacing: 14) {
                ProfileAvatar(size: 54, fontSize: 18, p: p)
                VStack(alignment: .leading, spacing: 3) {
                    Text(userManager.userName.isEmpty ? "Tu perfil" : userManager.userName)
                        .font(.fig(17, .bold)).foregroundColor(p.ink).lineLimit(1)
                    Text((profileBits).loc).font(.fig(13, .medium)).foregroundColor(p.mute)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(p.mute)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .pulsoCard(p, radius: 22)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Apariencia

    private var unitIndex: Binding<Int> {
        Binding(get: { Units.weight == .kg ? 0 : 1 },
                set: {
                    Units.weight = $0 == 0 ? .kg : .lb
                    viewModel.objectWillChange.send()
                    viewModel.publishSummary()
                    PhoneConnectivity.shared.sendTodayContext()
                })
    }

    private var themeIndex: Binding<Int> {
        Binding(get: { themeManager.isDarkMode ? 0 : 1 },
                set: { themeManager.isDarkMode = ($0 == 0) })
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                IconTile(symbol: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill", p: p)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Modo").font(.fig(15, .semibold)).foregroundColor(p.ink)
                    Text("Cambia entre claro y oscuro").font(.fig(12, .medium)).foregroundColor(p.mute)
                }
                Spacer(minLength: 8)
                PulsoSegmented(options: ["Oscuro", "Claro"], selection: themeIndex, onCard: false, p: p)
            }

            Rectangle().fill(p.line).frame(height: 1).padding(.vertical, 14)

            Text("Color de la app").font(.fig(15, .semibold)).foregroundColor(p.ink)
            Text("Elige el degradado principal").font(.fig(12, .medium)).foregroundColor(p.mute).padding(.top, 2)
            HStack {
                ForEach(AccentColor.selectable) { accent in
                    let on = themeManager.selectedAccentColor == accent
                    Button { themeManager.selectedAccentColor = accent } label: {
                        Circle()
                            .fill(accent.gradient(isDark: themeManager.isDarkMode))
                            .padding(3)
                            .frame(width: 40, height: 40)
                            .overlay(Circle().strokeBorder(on ? p.ink : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accent.displayName)
                    if accent != AccentColor.selectable.last { Spacer(minLength: 0) }
                }
            }
            .padding(.horizontal, 2)
            .padding(.top, 14)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .pulsoCard(p, radius: 22)
    }

    // MARK: - Entrenamiento

    private var trainingCard: some View {
        VStack(spacing: 0) {
            Button { showingTrainingProfile = true } label: {
                navRow(icon: "person.text.rectangle", title: "Tu perfil de entreno",
                       sub: viewModel.trainingProfile.completed
                           ? "\(viewModel.trainingProfile.goal.label) · \(viewModel.trainingProfile.level.label) · \(viewModel.activeEquipment.name)"
                           : "Objetivo, nivel, material y preferencias")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.trainingProfile")
            .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }
            HStack(spacing: 12) {
                IconTile(symbol: "scalemass", p: p)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unidad de peso").font(.fig(15, .semibold)).foregroundColor(p.ink)
                    Text("Tus datos no cambian: solo cómo se ven").font(.fig(12, .medium)).foregroundColor(p.mute)
                }
                Spacer(minLength: 8)
                PulsoSegmented(options: ["kg", "lb"], selection: unitIndex, onCard: false, p: p)
                    .frame(width: 110)
                    .accessibilityIdentifier("settings.unit")
            }
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }
            toggleRow(icon: "timer", title: "Timer de descanso", sub: "Arranca solo al marcar una serie",
                      isOn: Binding(get: { themeManager.isTimerEnabled },
                                    set: { themeManager.isTimerEnabled = $0; viewModel.updateTimerEnabledState($0) }),
                      divider: true)
            HStack(spacing: 12) {
                IconTile(symbol: "target", p: p)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sesiones por semana").font(.fig(15, .semibold)).foregroundColor(p.ink)
                    Text("Tu objetivo: el anillo de Inicio").font(.fig(12, .medium)).foregroundColor(p.mute)
                }
                Spacer(minLength: 8)
                HStack(spacing: 10) {
                    Button { viewModel.weeklySessionGoal -= 1 } label: { Image(systemName: "minus") }
                        .accessibilityIdentifier("goal.week.minus")
                    Text("\(viewModel.weeklySessionGoal)").font(.bri(18)).foregroundColor(p.ink).frame(minWidth: 18)
                        .accessibilityIdentifier("goal.week.value")
                    Button { viewModel.weeklySessionGoal += 1 } label: { Image(systemName: "plus") }
                        .accessibilityIdentifier("goal.week.plus")
                }
                .font(.system(size: 14, weight: .bold)).foregroundColor(p.acc)
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }
            toggleRow(icon: "sun.max.fill", title: "Mantener pantalla encendida",
                      sub: "Evita que se apague durante el entreno", isOn: $keepScreenOn, divider: true)
            toggleRow(icon: "moon.zzz.fill", title: "Modo de enfoque automático",
                      sub: "Silencia avisos mientras entrenas", isOn: $autoFocusMode, divider: true)
            toggleRow(icon: "waveform", title: "Voz en los descansos",
                      sub: "Cuenta los últimos segundos y dice lo siguiente (baja la música)",
                      isOn: $voiceCues, divider: true)
            toggleRow(icon: "iphone.radiowaves.left.and.right", title: "Vibración",
                      sub: "Al marcar series, acabar el descanso y batir marcas", isOn: $hapticsEnabled, divider: true)
            HStack(spacing: 12) {
                IconTile(symbol: "hourglass", p: p)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Descanso por defecto").font(.fig(15, .semibold)).foregroundColor(p.ink)
                    Text("Para los ejercicios nuevos").font(.fig(12, .medium)).foregroundColor(p.mute)
                }
                Spacer(minLength: 8)
            }
            .padding(.top, 12)
            PulsoSegmented(options: Self.restPresets.map { WorkoutViewModel.restText($0) },
                           selection: Binding(
                               get: {
                                   // Un valor fuera de los presets (copia restaurada) marca el más cercano.
                                   let v = viewModel.defaultRestDuration
                                   return Self.restPresets.indices.min { abs(Self.restPresets[$0] - v) < abs(Self.restPresets[$1] - v) } ?? 3
                               },
                               set: { viewModel.defaultRestDuration = Self.restPresets[$0] }),
                           onCard: false, p: p)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .pulsoCard(p, radius: 22)
    }

    private func toggleRow(icon: String, title: String, sub: String, isOn: Binding<Bool>, divider: Bool) -> some View {
        HStack(spacing: 12) {
            IconTile(symbol: icon, p: p)
            VStack(alignment: .leading, spacing: 2) {
                Text((title).loc).font(.fig(15, .semibold)).foregroundColor(p.ink)
                Text((sub).loc).font(.fig(12, .medium)).foregroundColor(p.mute)
            }
            Spacer(minLength: 8)
            PulsoToggle(isOn: isOn, p: p)
                .accessibilityIdentifier("toggle.\(title)")
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if divider { Rectangle().fill(p.line).frame(height: 1) }
        }
    }

    // MARK: - Música y avisos

    /// Abre Spotify; si no está instalada, su ficha de la App Store.
    private func openSpotify() {
        guard let app = URL(string: "spotify://"),
              let store = URL(string: "https://apps.apple.com/app/id324684580") else { return }
        UIApplication.shared.open(app, options: [:]) { opened in
            if !opened { UIApplication.shared.open(store) }
        }
    }

    private var musicCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                IconTile(symbol: "music.note", p: p)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spotify").font(.fig(15, .semibold)).foregroundColor(p.ink)
                    Text(spotify.isConnected ? "Conectado a tu cuenta de Spotify"
                         : spotify.hasSession ? "Sesión guardada · sin conexión ahora"
                         : "Controla tu música durante el entrenamiento")
                        .font(.fig(12, .medium)).foregroundColor(p.mute)
                }
                Spacer(minLength: 8)
                if spotify.hasSession {
                    Button { spotify.disconnect(forget: true) } label: {
                        Text("Desconectar")
                            .font(.fig(12, .semibold)).foregroundColor(p.danger)
                            .padding(.horizontal, 12).frame(height: 34)
                            .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { SpotifyManager.isConfigured ? spotify.connect() : openSpotify() } label: {
                        Text(SpotifyManager.isConfigured ? "Conectar" : "Abrir")
                            .font(.fig(12, .bold)).foregroundColor(p.onacc)
                            .padding(.horizontal, 14).frame(height: 34)
                            .background(Capsule().fill(p.hgrad))
                    }
                    .buttonStyle(.plain)
                }
            }
            if let err = spotify.lastError {
                Text((err).loc).font(.fig(12, .medium)).foregroundColor(p.danger).padding(.top, 8)
            }
            if spotify.isConnected {
                HStack(spacing: 10) {
                    Group {
                        if let img = spotify.artwork {
                            Image(uiImage: img).resizable().scaledToFill()
                        } else {
                            Rectangle().fill(p.grad)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(spotify.trackTitle.isEmpty ? "Nada sonando" : spotify.trackTitle)
                            .font(.fig(13, .bold)).foregroundColor(p.ink).lineLimit(1)
                        Text((spotify.trackArtist).loc).font(.fig(12, .medium)).foregroundColor(p.mute).lineLimit(1)
                    }
                    Spacer()
                    Button { spotify.togglePlayPause() } label: {
                        Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(p.acc)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(p.card))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
                .padding(.top, 12)
                HStack(spacing: 6) {
                    ForEach([("Píldora", SpotifyManager.Presentation.compact), ("Pestaña", .minimized), ("Oculto", .hidden)], id: \.1) { item in
                        let on = spotify.presentation == item.1
                        Button { spotify.setPresentation(item.1) } label: {
                            Text((item.0).loc).font(.fig(12, on ? .bold : .semibold))
                                .foregroundColor(on ? p.onacc : p.mute)
                                .frame(maxWidth: .infinity).frame(height: 30)
                                .background(Capsule().fill(on ? AnyShapeStyle(p.hgrad) : AnyShapeStyle(p.soft)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
            }

            Rectangle().fill(p.line).frame(height: 1).padding(.vertical, 14)

            Button { showingNotifications = true } label: {
                HStack(spacing: 12) {
                    IconTile(symbol: "bell.fill", p: p)
                        .overlay(alignment: .topTrailing) {
                            if viewModel.unreadNotifications > 0 {
                                Text("\(viewModel.unreadNotifications)")
                                    .font(.fig(10, .bold)).foregroundColor(p.onacc)
                                    .padding(.horizontal, 4)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .background(Capsule().fill(p.grad))
                                    .offset(x: 3, y: -3)
                            }
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notificaciones").font(.fig(15, .semibold)).foregroundColor(p.ink)
                        Text(viewModel.unreadNotifications > 0 ? "\(viewModel.unreadNotifications) sin leer" : "Todas leídas")
                            .font(.fig(12, .medium)).foregroundColor(p.mute)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(p.mute)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .pulsoCard(p, radius: 22)
    }

    // MARK: - Coach IA y datos (de la app, fuera del prototipo)

    private var extrasCard: some View {
        VStack(spacing: 0) {
            Button { showingFriends = true } label: {
                navRow(icon: "person.2.fill", title: "Amigos y retos", sub: "Por iCloud · solo se comparten resúmenes")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.friends")
            .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }
            Button { showingNutrition = true } label: {
                navRow(icon: "fork.knife", title: "Nutrición",
                       sub: Nutrition.shared.connected ? "Conectado a Dieta · agua y registro rápido" : "Conecta Dieta, objetivo de agua")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.nutrition")
            .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }
            Button { showingExperiments = true } label: {
                navRow(icon: "flask.fill", title: "Experimentos", sub: "¿Descansar más te hace más fuerte? Pruébalo en ti")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.experiments")
            .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }
            Button { showingCoach = true } label: {
                navRow(icon: "sparkles", title: "Coach IA", sub: "Pregunta por tu rutina, técnica o progresión")
            }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }

            ShareLink(item: CSVFile(make: { [viewModel] in viewModel.exportCSV() }),
                      preview: SharePreview("Entrenamientos ChamaFit (CSV)")) {
                navRow(icon: "tablecells", title: "Exportar entrenamientos", sub: "Una fila por serie, en CSV para Excel o Numbers")
            }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }

            ShareLink(item: BackupFile(make: { [viewModel] in try viewModel.backupData() }),
                      preview: SharePreview("Copia de seguridad de ChamaFit")) {
                navRow(icon: "square.and.arrow.up", title: "Copia de seguridad", sub: backupSub)
            }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }

            Button { importingBackup = true } label: {
                navRow(icon: "square.and.arrow.down", title: "Restaurar copia", sub: "Fusiona con lo tuyo o sustituye todo")
            }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }

            if viewModel.undoRestoreFile() != nil {
                Button {
                    do { try viewModel.undoLastRestore(); userManager.reloadProfile() }
                    catch { restoreError = error.localizedDescription }
                } label: {
                    navRow(icon: "arrow.uturn.backward.circle", title: "Deshacer la última restauración",
                           sub: "Vuelve a como estaba antes (disponible 7 días)")
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }
            }

            Button { confirmReset = true } label: {
                navRow(icon: "trash", title: "Borrar todos los datos", sub: "Ejercicios, rutina, historial, peso y notas", tint: p.danger)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .pulsoCard(p, radius: 22)
        .fileImporter(isPresented: $importingBackup, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result else { return }
            pendingRestore = url
        }
        .confirmationDialog("¿Restaurar esta copia?", isPresented: Binding(get: { pendingRestore != nil },
                                                                         set: { if !$0 { pendingRestore = nil } }),
                            titleVisibility: .visible) {
            Button("Fusionar con lo mío") { restore(.merge) }
            Button("Sustituir todo por la copia", role: .destructive) { restore(.replace) }
        } message: {
            Text("Fusionar añade lo que no tengas y, si algo choca, se queda lo tuyo. Sustituir cambia todo por la copia. En los dos casos se guarda antes una copia de lo actual para poder deshacer.")
        }
        .confirmationDialog("¿Borrar todos los datos?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Borrar ejercicios, rutina e historial", role: .destructive) {
                viewModel.resetAllData()
                HapticManager.shared.destructiveAction()
            }
        } message: {
            Text("Se borran los ejercicios, la rutina de cada día, el historial, el peso y las notas. El perfil y los ajustes se quedan. No se puede deshacer.")
        }
        .alert("No se pudo restaurar", isPresented: Binding(get: { restoreError != nil },
                                                             set: { if !$0 { restoreError = nil } })) {
            Button("Vale", role: .cancel) {}
        } message: {
            Text(restoreError ?? "")
        }
    }

    private func restore(_ mode: WorkoutViewModel.RestoreMode) {
        guard let url = pendingRestore else { return }
        pendingRestore = nil
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            _ = try WorkoutViewModel.decodeBackup(data)       // antes de tocar nada, que sea una copia válida
            viewModel.saveUndoCopy()
            try viewModel.restore(from: data, mode: mode)
            userManager.reloadProfile()
        } catch {
            restoreError = error.localizedDescription
        }
    }

    private func navRow(icon: String, title: String, sub: String, tint: Color? = nil) -> some View {
        HStack(spacing: 12) {
            IconTile(symbol: icon, p: p)
            VStack(alignment: .leading, spacing: 2) {
                Text((title).loc).font(.fig(15, .semibold)).foregroundColor(tint ?? p.ink)
                Text((sub).loc).font(.fig(12, .medium)).foregroundColor(p.mute)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(p.mute)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    /// "Todo en un fichero · automática cada semana (última: 3 sep)".
    private var backupSub: String {
        let base = "Todo en un fichero. Además, copia automática semanal en Archivos › ChamaFit"
        guard let last = AutoBackup.lastDate else { return base }
        let f = DateFormatter(); f.locale = AppLanguage.locale; f.dateFormat = "d MMM"
        return base + String(localized: " (última: \(f.string(from: last)))")
    }

    // MARK: - iPhone y Apple Watch

    private var iphoneCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if health.isAvailable {
                HStack(spacing: 12) {
                    IconTile(symbol: "heart.text.square.fill", p: p)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Salud").font(.fig(15, .semibold)).foregroundColor(p.ink)
                        Text(health.connected ? "Sueño, pulsaciones, pasos y peso · entrenos guardados"
                                              : "Conecta para ver tu recuperación y guardar entrenos")
                            .font(.fig(12, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    if health.connected {
                        PulsoToggle(isOn: Binding(get: { health.saveWorkouts }, set: { health.saveWorkouts = $0 }), p: p)
                            .accessibilityIdentifier("toggle.Guardar en Salud")
                    } else {
                        Button { Task { await health.requestAccess() } } label: {
                            Text("Conectar").font(.fig(12, .bold)).foregroundColor(p.onacc)
                                .padding(.horizontal, 12).frame(height: 32).background(Capsule().fill(p.hgrad))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Rectangle().fill(p.line).frame(height: 1)
            }
            HStack(spacing: 12) {
                IconTile(symbol: "calendar.badge.plus", p: p)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calendario del iPhone").font(.fig(15, .semibold)).foregroundColor(p.ink)
                    Text("Tus próximas dos semanas de sesiones en un calendario «ChamaFit», y las hechas con su resumen")
                        .font(.fig(12, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                PulsoToggle(isOn: Binding(get: { calendarSync }, set: { on in
                    Task {
                        if on {
                            guard await SystemCalendar.requestAccess() else { calendarSync = false; return }
                            SystemCalendar.enabled = true
                            calendarSync = true
                            SystemCalendar.sync(viewModel)
                        } else {
                            SystemCalendar.enabled = false
                            calendarSync = false
                            SystemCalendar.removeAll()
                        }
                    }
                }), p: p)
                .accessibilityIdentifier("toggle.calendar")
            }
            Rectangle().fill(p.line).frame(height: 1)
            guideRow("button.horizontal.top.press", "Botón de Acción",
                     "Ajustes › Botón de Acción › Atajo › ChamaFit › «Marcar serie». Marca la serie con el móvil bloqueado.")
            guideRow("mic.fill", "Siri",
                     "«Oye Siri, marca una serie en ChamaFit», «¿Qué me toca hoy en ChamaFit?», «Empieza el descanso en ChamaFit».")
            guideRow("switch.2", "Centro de control",
                     "Mantén pulsado el Centro de control › Añadir un control › ChamaFit: «Marcar serie» y «Descanso».")
            guideRow("lock.iphone", "Pantalla bloqueada y reloj",
                     "Widgets de ChamaFit en la pantalla bloqueada y complicación en la esfera del Apple Watch.")
            guideRow("moon.circle.fill", "Modo Gimnasio",
                     "En Atajos › Automatización: al activar tu modo de concentración, «Empezar entreno» de ChamaFit.")
            SiriTipView(intent: MarkSetIntent())
            Button {
                if let url = URL(string: "shortcuts://") { UIApplication.shared.open(url) }
            } label: {
                Label("Abrir Atajos", systemImage: "square.2.layers.3d.fill").font(.fig(14, .bold))
                    .foregroundColor(p.onacc).frame(maxWidth: .infinity).frame(height: 44)
                    .background(Capsule().fill(p.hgrad))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .pulsoCard(p, radius: 22)
    }

    private func guideRow(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconTile(symbol: icon, p: p)
            VStack(alignment: .leading, spacing: 2) {
                Text((title).loc).font(.fig(15, .semibold)).foregroundColor(p.ink)
                Text((text).loc).font(.fig(12, .medium)).lineSpacing(2).foregroundColor(p.mute)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Tutorial

    private var tutorialCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("¿Nuevo en ChamaFit?")
                .font(.bri(18)).em(-0.02, size: 18).foregroundColor(p.ink)
            Text("Un recorrido de un minuto: crear un ejercicio, verlo en el calendario y marcar series.")
                .font(.fig(13, .medium)).lineSpacing(4).foregroundColor(p.mute)
                .padding(.top, 6)
            PrimaryButton(title: "Ver tutorial y empezar", icon: "play.fill", height: 46, fontSize: 14, p: p) {
                onStartTutorial()
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 23, style: .continuous).fill(p.sheet))
        .padding(1.5)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(p.grad))
        .shadow(color: p.glow1, radius: 17, y: 14)
    }
}

// MARK: - Avatar

/// Foto de perfil o, si no hay, las iniciales sobre el degradado.
struct ProfileAvatar: View {
    @EnvironmentObject var userManager: UserManager
    var size: CGFloat
    var fontSize: CGFloat
    let p: Palette

    private var initials: String {
        let parts = userManager.userName.split(separator: " ").prefix(2)
        let s = parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
        return s.isEmpty ? "CF" : s
    }

    var body: some View {
        Group {
            if let data = userManager.profileImageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Text((initials).loc)
                    .font(.bri(fontSize))
                    .foregroundColor(p.onacc)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(p.grad)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(color: p.glow1, radius: size * 0.2, y: size * 0.15)
    }
}

// MARK: - Hoja de perfil

struct ProfileSheet: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var age = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var photo: Data? = nil

    private var p: Palette { themeManager.p }
    private var valid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private var bmi: (value: Double, category: String)? {
        guard let h = Double(height.replacingOccurrences(of: ",", with: ".")), h > 0,
              let w = Units.parse(weight), w > 0 else { return nil }
        let m = h > 3 ? h / 100 : h
        let v = w / (m * m)
        let cat: String
        switch v {
        case ..<18.5: cat = "Bajo peso"
        case 18.5..<25: cat = "Peso normal"
        case 25..<30: cat = "Sobrepeso"
        default: cat = "Obesidad"
        }
        return (v, cat)
    }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                Text("Tu perfil").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    PhotoPickerButton(imageData: $photo) {
                        VStack(spacing: 10) {
                            Group {
                                if let photo, let ui = UIImage(data: photo) {
                                    Image(uiImage: ui).resizable().scaledToFill()
                                        .frame(width: 96, height: 96).clipShape(Circle())
                                        .shadow(color: p.glow1, radius: 20, y: 16)
                                } else {
                                    ProfileAvatar(size: 96, fontSize: 32, p: p)
                                }
                            }
                            Text("Toca para cambiar la foto").font(.fig(12, .medium)).foregroundColor(p.mute)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    UpperLabel(text: "Nombre", p: p).padding(.top, 18).padding(.bottom, 6)
                    PulsoField(placeholder: "Tu nombre", text: $name, p: p)

                    HStack(spacing: 8) {
                        numberField("Edad", "años", $age, .numberPad)
                        numberField("Altura", "cm", $height, .numberPad)
                        numberField("Peso", Units.symbol, $weight, .decimalPad)
                    }
                    .padding(.top, 14)

                    if let bmi {
                        VStack(spacing: 0) {
                            UpperLabel(text: "Índice de masa corporal", p: p)
                            GradientText(text: AppLanguage.decimal(String(format: "%.1f", bmi.value)),
                                         font: .bri(34), p: p)
                                .padding(.top, 8)
                            Text((bmi.category).loc).font(.fig(13, .semibold)).foregroundColor(p.mute).padding(.top, 6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(p.line, lineWidth: 1))
                        .padding(.top, 16)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 10)
            }
            .scrollDismissesKeyboard(.interactively)
        } footer: {
            SheetFooter(p: p) {
                PrimaryButton(title: "Guardar", height: 50, enabled: valid, p: p) {
                    // El peso se escribe en la unidad elegida y se guarda en kg.
                    let stored = Double(userManager.userWeight.replacingOccurrences(of: ",", with: "."))
                    let kgText: String
                    if let stored, weight == Units.number(stored) { kgText = userManager.userWeight }
                    else if let kg = Units.parse(weight) { kgText = Units.plain((kg * 10).rounded() / 10) }
                    else { kgText = "" }
                    userManager.saveUserProfile(name: name, age: age, height: height, weight: kgText, imageData: photo)
                    HapticManager.shared.success()
                    dismiss()
                }
            }
        }
        .onAppear {
            name = userManager.userName
            age = userManager.userAge
            height = userManager.userHeight
            weight = Double(userManager.userWeight.replacingOccurrences(of: ",", with: ".")).map { Units.number($0) } ?? userManager.userWeight
            photo = userManager.profileImageData
        }
    }

    private func numberField(_ label: String, _ placeholder: String, _ text: Binding<String>, _ kb: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            UpperLabel(text: label, p: p)
            PulsoField(placeholder: placeholder, text: text, keyboard: kb, p: p)
        }
    }
}

// MARK: - Hoja de notificaciones

struct NotificationsSheet: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    private var p: Palette { themeManager.p }

    var body: some View {
        PulsoSheet(p: p) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notificaciones").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                    Text("\(viewModel.unreadNotifications > 0 ? "\(viewModel.unreadNotifications) sin leer" : "Todas leídas") · \(viewModel.notifications.count) en total")
                        .font(.fig(12, .medium)).foregroundColor(p.mute)
                }
                Spacer()
                PulsoToggle(isOn: $viewModel.notificationsEnabled, p: p)
                CloseCircle(p: p) { dismiss() }.padding(.leading, 10)
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)

            RemindersCard(p: p)
                .padding(.horizontal, 22)
                .padding(.top, 14)

            if !viewModel.notifications.isEmpty {
                HStack(spacing: 8) {
                    if viewModel.unreadNotifications > 0 {
                        chipButton("Marcar todas como leídas", color: p.acc, filled: true) {
                            viewModel.markAllNotificationsRead()
                        }
                    }
                    chipButton("Eliminar todas", color: p.danger, filled: false) { confirmClear = true }
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    if viewModel.notifications.isEmpty {
                        VStack(spacing: 0) {
                            IconTile(symbol: "bell.fill", size: 56, radius: 18, p: p)
                            Text("No hay notificaciones").font(.fig(16, .bold)).foregroundColor(p.ink).padding(.top, 14)
                            Text("Los avisos de descanso, récords y recordatorios aparecerán aquí.")
                                .font(.fig(13, .medium)).lineSpacing(3).foregroundColor(p.mute)
                                .multilineTextAlignment(.center).padding(.top, 6)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 36)
                    } else {
                        ForEach(viewModel.notifications) { n in row(n) }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .confirmationDialog("¿Eliminar todas las notificaciones?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Eliminar todas", role: .destructive) { viewModel.clearNotifications() }
        }
    }

    private func chipButton(_ title: String, color: Color, filled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text((title).loc).font(.fig(12, .semibold)).foregroundColor(color)
                .padding(.horizontal, 14).frame(height: 34)
                .background(Capsule().fill(filled ? p.soft : .clear))
                .overlay(Capsule().strokeBorder(p.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func icon(_ kind: AppNotification.Kind) -> String {
        switch kind {
        case .workoutReminder: return "alarm.fill"
        case .restTimer: return "timer"
        case .achievement: return "trophy.fill"
        case .general: return "bell.fill"
        }
    }

    private func ago(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 60 { return "ahora" }
        if s < 3600 { return String(localized: "hace \(s / 60) min") }
        if s < 86_400 { return String(localized: "hace \(s / 3600) h") }
        return String(localized: "hace \(s / 86_400) d")
    }

    private func row(_ n: AppNotification) -> some View {
        Button { viewModel.markNotificationRead(n.id) } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon(n.kind))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(n.read ? p.acc : p.onacc)
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(n.read ? AnyShapeStyle(p.soft) : AnyShapeStyle(p.grad)))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text((n.title).loc).font(.fig(14, n.read ? .semibold : .bold)).foregroundColor(p.ink)
                        Spacer(minLength: 8)
                        Text((ago(n.date)).loc).font(.fig(11, .medium)).foregroundColor(p.mute)
                    }
                    Text((n.message).loc).font(.fig(13, .medium)).lineSpacing(3).foregroundColor(p.mute)
                        .multilineTextAlignment(.leading)
                }
                if !n.read {
                    Circle().fill(p.acc).frame(width: 8, height: 8)
                        .shadow(color: p.acc, radius: 4)
                        .padding(.top, 6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(n.read ? .clear : p.soft))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(n.read ? p.line : p.acc, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(n.read)
    }
}
