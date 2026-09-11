//
//  FriendsView.swift
//  ChamaFit
//
//  Amigos (por código) y retos con marcador. Solo se comparten resúmenes.
//

import SwiftUI

struct FriendsView: View {
    /// Reto que llega por enlace.
    var joinId: String? = nil

    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var social = Social.shared

    @State private var code = ""
    @State private var newTitle = "Reto de septiembre"
    @State private var newMetric = ChallengeMetric.sessions
    @State private var newDays = 14
    @State private var creating = false

    private var p: Palette { themeManager.p }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "iCloud", p: p)
                    Text("Amigos y retos").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                if social.busy { ProgressView() }
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if !Social.available {
                        Text("Amigos y retos van por iCloud y aún no están activados en esta versión de la app. Cuando lo estén, aquí verás tu código y el de tus amigos.")
                            .font(.fig(13, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("friends.unavailable")
                    }
                    if let e = social.problem { Text((e).loc).font(.fig(12, .medium)).foregroundColor(p.danger) }
                    me
                    friends
                    challenges
                    privacy
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
            .refreshable { await social.refresh(viewModel, name: userManager.userName) }
        }
        .task {
            if let joinId { _ = await social.join(challengeId: joinId) }
            await social.refresh(viewModel, name: userManager.userName)
        }
    }

    private var me: some View {
        VStack(alignment: .leading, spacing: 8) {
            UpperLabel(text: "Tu código", p: p)
            HStack {
                Text((social.myCode).loc).font(.bri(30)).tracking(4).foregroundStyle(p.hgrad)
                    .accessibilityIdentifier("friends.code")
                Spacer()
                ShareLink(item: String(localized: "Añádeme en ChamaFit con el código \(social.myCode)")) {
                    Label("Compartir", systemImage: "square.and.arrow.up").font(.fig(13, .semibold))
                }
            }
        }
        .padding(14).pulsoCard(p, radius: 20)
    }

    private var friends: some View {
        VStack(alignment: .leading, spacing: 8) {
            UpperLabel(text: "Amigos", p: p)
            HStack(spacing: 8) {
                PulsoField(placeholder: "Código de tu amigo", text: $code, p: p)
                    .textInputAutocapitalization(.characters).autocorrectionDisabled()
                    .accessibilityIdentifier("friends.input")
                PrimaryButton(title: "Añadir", height: 48, enabled: code.count >= 6, p: p) {
                    Task { if await social.addFriend(code: code) { code = "" } }
                }
                .frame(width: 100)
            }
            if social.friends.isEmpty {
                Text("Aún no has añadido a nadie.").font(.fig(13, .medium)).foregroundColor(p.mute)
            }
            ForEach(social.friends) { f in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text((f.name).loc).font(.fig(15, .bold)).foregroundColor(p.ink)
                        Text((friendLine(f)).loc).font(.fig(12, .medium)).foregroundColor(p.mute)
                        if let r = f.records, !r.isEmpty { Text("🏆 " + r.joined(separator: " · ")).font(.fig(12, .medium)).foregroundColor(p.acc) }
                    }
                    Spacer()
                    Button { social.removeFriend(f.id) } label: { Image(systemName: "person.badge.minus") }.foregroundColor(p.mute)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
            }
        }
    }

    private func friendLine(_ f: FriendSummary) -> String {
        var parts: [String] = []
        if let s = f.weekSessions { parts.append(String(localized: "\(s) sesiones")) }
        if let s = f.weekSets { parts.append(String(localized: "\(s) series")) }
        if let v = f.weekVolume { parts.append(Units.tonnage(v)) }
        if let r = f.streak { parts.append(String(localized: "racha \(r)")) }
        return parts.isEmpty ? "No comparte cifras" : "Esta semana: " + parts.joined(separator: " · ")
    }

    private var challenges: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                UpperLabel(text: "Retos", p: p)
                Spacer()
                Button(creating ? "Cancelar" : "Nuevo reto") { creating.toggle() }.font(.fig(13, .semibold)).foregroundColor(p.acc)
                    .accessibilityIdentifier("challenge.new")
            }
            if creating {
                VStack(alignment: .leading, spacing: 8) {
                    PulsoField(placeholder: "Nombre del reto", text: $newTitle, p: p)
                    FlowLayout(spacing: 6) {
                        ForEach(ChallengeMetric.allCases) { m in
                            TagChip(text: m.label, selected: newMetric == m, p: p) { newMetric = m }
                        }
                    }
                    Stepper("Dura \(newDays) días", value: $newDays, in: 3...90).font(.fig(14, .semibold))
                    PrimaryButton(title: "Crear e invitar", icon: "flag.checkered", height: 46, p: p) {
                        Task {
                            if await social.createChallenge(title: newTitle, metric: newMetric, days: newDays) != nil {
                                creating = false
                                await social.refresh(viewModel, name: userManager.userName)
                            }
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
            }
            ForEach(social.challenges) { c in challengeCard(c) }
        }
    }

    private func challengeCard(_ c: Challenge) -> some View {
        let board = social.boards[c.id] ?? []
        let mine = viewModel.challengeScore(c.metric, from: c.start, to: c.end)
        let f = DateFormatter(); f.dateFormat = "d MMM"; f.locale = AppLanguage.locale
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text((c.title).loc).font(.fig(15, .bold)).foregroundColor(p.ink)
                Spacer()
                ShareLink(item: c.link, message: Text("Únete a mi reto «\(c.title)» en ChamaFit")) { Image(systemName: "person.badge.plus") }
            }
            Text("\(c.metric.label) · del \(f.string(from: c.start)) al \(f.string(from: c.end))\(Date() > c.end ? " · terminado" : "")")
                .font(.fig(12, .medium)).foregroundColor(p.mute)
            if board.isEmpty {
                Text("Tú: \(scoreText(mine, c.metric))").font(.fig(13, .semibold)).foregroundColor(p.ink)
            }
            ForEach(Array(board.enumerated()), id: \.element.id) { i, s in
                HStack {
                    Text("\(i + 1).").font(.bri(15)).foregroundColor(i == 0 ? p.acc : p.mute).frame(width: 26, alignment: .leading)
                    Text(s.profileId == social.myId ? "Tú" : s.name).font(.fig(14, s.profileId == social.myId ? .bold : .semibold)).foregroundColor(p.ink)
                    Spacer()
                    Text(scoreText(s.score, c.metric)).font(.fig(13, .bold)).foregroundColor(p.ink)
                }
            }
            Button("Salir del reto") { social.leave(c.id) }.font(.fig(12, .semibold)).foregroundColor(p.danger)
        }
        .padding(12)
        .pulsoCard(p, radius: 18)
    }

    private func scoreText(_ v: Double, _ m: ChallengeMetric) -> String {
        switch m {
        case .volume: return Units.tonnage(v)
        case .streak: return String(localized: "\(Int(v)) días")
        case .sessions: return String(localized: "\(Int(v)) sesiones")
        case .sets: return String(localized: "\(Int(v)) series")
        }
    }

    private var privacy: some View {
        VStack(alignment: .leading, spacing: 6) {
            UpperLabel(text: "Qué compartes", p: p)
            Toggle("Sesiones y series de la semana", isOn: Binding(get: { social.prefs.sessions }, set: { var x = social.prefs; x.sessions = $0; social.prefs = x }))
            Toggle("Tonelaje", isOn: Binding(get: { social.prefs.volume }, set: { var x = social.prefs; x.volume = $0; social.prefs = x }))
            Toggle("Racha", isOn: Binding(get: { social.prefs.streak }, set: { var x = social.prefs; x.streak = $0; social.prefs = x }))
            Toggle("Mis tres mejores récords", isOn: Binding(get: { social.prefs.records }, set: { var x = social.prefs; x.records = $0; social.prefs = x }))
            Text("Tu historial, notas y peso nunca salen del iPhone. En los retos solo se publica tu marcador.")
                .font(.fig(12, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
        }
        .font(.fig(14, .semibold)).tint(p.acc)
    }
}
