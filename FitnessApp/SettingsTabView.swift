//
//  SettingsTabView.swift
//  FitnessApp
//
//  Pestaña Configuración del rediseño «Pulso»: perfil, apariencia, ajustes
//  de entrenamiento, música y avisos y el tutorial. Añade lo que la app ya
//  tenía y el prototipo no dibuja: Coach IA y exportar los datos.
//

import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager

    /// Arranca el tutorial de siete pasos (lo pinta ContentView).
    var onStartTutorial: () -> Void = {}

    @AppStorage("keepScreenOn") private var keepScreenOn = false
    @AppStorage("autoFocusMode") private var autoFocusMode = true

    @State private var showingProfile = false
    @State private var showingNotifications = false
    @State private var showingCoach = false

    private var p: Palette { themeManager.p }

    var body: some View {
        ZStack(alignment: .top) {
            p.bg.ignoresSafeArea()
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
                        section("Coach y datos")
                        extrasCard
                        tutorialCard.padding(.top, 20)
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
        if !userManager.userAge.isEmpty { bits.append("\(userManager.userAge) años") }
        if !userManager.userHeight.isEmpty { bits.append("\(userManager.userHeight) cm") }
        if !userManager.userWeight.isEmpty { bits.append("\(userManager.userWeight) kg") }
        return bits.isEmpty ? "Añade edad, altura y peso" : bits.joined(separator: " · ")
    }

    private var profileRow: some View {
        Button { showingProfile = true } label: {
            HStack(spacing: 14) {
                ProfileAvatar(size: 54, fontSize: 18, p: p)
                VStack(alignment: .leading, spacing: 3) {
                    Text(userManager.userName.isEmpty ? "Tu perfil" : userManager.userName)
                        .font(.fig(17, .bold)).foregroundColor(p.ink).lineLimit(1)
                    Text(profileBits).font(.fig(13, .medium)).foregroundColor(p.mute)
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
            toggleRow(icon: "timer", title: "Timer de descanso", sub: "Arranca solo al marcar una serie",
                      isOn: Binding(get: { themeManager.isTimerEnabled },
                                    set: { themeManager.isTimerEnabled = $0; viewModel.updateTimerEnabledState($0) }),
                      divider: true)
            toggleRow(icon: "sun.max.fill", title: "Mantener pantalla encendida",
                      sub: "Evita que se apague durante el entreno", isOn: $keepScreenOn, divider: true)
            toggleRow(icon: "moon.zzz.fill", title: "Modo de enfoque automático",
                      sub: "Silencia avisos mientras entrenas", isOn: $autoFocusMode, divider: false)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .pulsoCard(p, radius: 22)
    }

    private func toggleRow(icon: String, title: String, sub: String, isOn: Binding<Bool>, divider: Bool) -> some View {
        HStack(spacing: 12) {
            IconTile(symbol: icon, p: p)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.fig(15, .semibold)).foregroundColor(p.ink)
                Text(sub).font(.fig(12, .medium)).foregroundColor(p.mute)
            }
            Spacer(minLength: 8)
            PulsoToggle(isOn: isOn, p: p)
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
                    Text("Controla tu música durante el entrenamiento").font(.fig(12, .medium)).foregroundColor(p.mute)
                }
                Spacer(minLength: 8)
                Button(action: openSpotify) {
                    Text("Abrir")
                        .font(.fig(12, .bold)).foregroundColor(p.onacc)
                        .padding(.horizontal, 14).frame(height: 34)
                        .background(Capsule().fill(p.hgrad))
                }
                .buttonStyle(.plain)
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
            Button { showingCoach = true } label: {
                navRow(icon: "sparkles", title: "Coach IA", sub: "Pregunta por tu rutina, técnica o progresión")
            }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Rectangle().fill(p.line).frame(height: 1) }

            ShareLink(item: viewModel.exportCSV(), preview: SharePreview("Entrenamientos ChamaFit (CSV)")) {
                navRow(icon: "square.and.arrow.up", title: "Exportar datos", sub: "Todo tu historial en CSV para abrir en Excel")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .pulsoCard(p, radius: 22)
    }

    private func navRow(icon: String, title: String, sub: String) -> some View {
        HStack(spacing: 12) {
            IconTile(symbol: icon, p: p)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.fig(15, .semibold)).foregroundColor(p.ink)
                Text(sub).font(.fig(12, .medium)).foregroundColor(p.mute)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(p.mute)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
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
                Text(initials)
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
              let w = Double(weight.replacingOccurrences(of: ",", with: ".")), w > 0 else { return nil }
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
                        numberField("Peso", "kg", $weight, .decimalPad)
                    }
                    .padding(.top, 14)

                    if let bmi {
                        VStack(spacing: 0) {
                            UpperLabel(text: "Índice de masa corporal", p: p)
                            GradientText(text: String(format: "%.1f", bmi.value).replacingOccurrences(of: ".", with: ","),
                                         font: .bri(34), p: p)
                                .padding(.top, 8)
                            Text(bmi.category).font(.fig(13, .semibold)).foregroundColor(p.mute).padding(.top, 6)
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
                    userManager.saveUserProfile(name: name, age: age, height: height, weight: weight, imageData: photo)
                    HapticManager.shared.success()
                    dismiss()
                }
            }
        }
        .onAppear {
            name = userManager.userName
            age = userManager.userAge
            height = userManager.userHeight
            weight = userManager.userWeight
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
            Text(title).font(.fig(12, .semibold)).foregroundColor(color)
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
        if s < 3600 { return "hace \(s / 60) min" }
        if s < 86_400 { return "hace \(s / 3600) h" }
        return "hace \(s / 86_400) d"
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
                        Text(n.title).font(.fig(14, n.read ? .semibold : .bold)).foregroundColor(p.ink)
                        Spacer(minLength: 8)
                        Text(ago(n.date)).font(.fig(11, .medium)).foregroundColor(p.mute)
                    }
                    Text(n.message).font(.fig(13, .medium)).lineSpacing(3).foregroundColor(p.mute)
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
