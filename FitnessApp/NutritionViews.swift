//
//  NutritionViews.swift
//  ChamaFit
//
//  Tarjeta de Inicio (comida de hoy y agua), la hoja del día con el menú de
//  Dieta y lo apuntado, el escáner de códigos de barras y la conexión.
//

import SwiftUI
import VisionKit
import Vision

// MARK: - Tarjeta de Inicio

struct NutritionCard: View {
    let p: Palette
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var n = Nutrition.shared
    @State private var showing = false

    var body: some View {
        let eaten = n.eaten()
        let target = n.targets()
        let water = n.water()
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                UpperLabel(text: n.connected ? "Comida de hoy · Dieta" : "Comida y agua", p: p)
                Spacer()
                Button { showing = true } label: {
                    Text("Ver").font(.fig(12, .bold)).foregroundColor(p.acc)
                }
                .accessibilityIdentifier("nutrition.open")
            }
            HStack(spacing: 10) {
                meter("Kcal", eaten.kcal, target?.kcal, "flame.fill")
                meter("Proteína", eaten.protein, target?.protein, "bolt.fill", unit: "g")
                meter("Agua", Double(water), Double(n.waterGoal), "drop.fill", unit: "ml")
            }
            if let next = n.meals().first(where: { !$0.eaten }) {
                Text("Siguiente: \(next.slotLabel) · \(next.recipe.title)").font(.fig(12, .medium)).foregroundColor(p.mute).lineLimit(1)
            }
            HStack(spacing: 8) {
                chip("+250 ml", "drop") { n.addWater(250) }.accessibilityIdentifier("nutrition.water")
                chip("Apuntar", "plus") { showing = true }.accessibilityIdentifier("nutrition.add")
            }
        }
        .padding(14)
        .pulsoCard(p, radius: 20)
        .sheet(isPresented: $showing) {
            NutritionSheet().environmentObject(viewModel).environmentObject(themeManager)
        }
    }

    private func meter(_ label: String, _ value: Double, _ goal: Double?, _ icon: String, unit: String = "") -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label.loc, systemImage: icon).font(.fig(11, .semibold)).foregroundColor(p.mute)
            Text("\(Int(value.rounded()))\(unit.isEmpty ? "" : " \(unit)")").font(.bri(17)).foregroundColor(p.ink).lineLimit(1).minimumScaleFactor(0.7)
            if let goal, goal > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(p.soft)
                        Capsule().fill(p.hgrad).frame(width: geo.size.width * CGFloat(min(1, value / goal)))
                    }
                }
                .frame(height: 5)
                Text("de \(Int(goal))").font(.fig(10, .medium)).foregroundColor(p.mute)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ t: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(t.loc, systemImage: icon).font(.fig(12, .semibold)).foregroundColor(p.ink)
                .padding(.horizontal, 12).frame(height: 32)
                .background(Capsule().fill(p.soft))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - La hoja del día

struct NutritionSheet: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var n = Nutrition.shared

    @State private var name = ""
    @State private var kcal = ""
    @State private var protein = ""
    @State private var scanning = false
    @State private var scanned: FoodProduct? = nil
    @State private var grams = "100"
    @State private var lookupMessage: String? = nil

    private var p: Palette { themeManager.p }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: WeeklyCalendarView.longDate(Date()), p: p)
                    Text("Comida de hoy").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if let e = n.lastError { Text((e).loc).font(.fig(12, .medium)).foregroundColor(p.danger) }
                    if n.connected { menu } else {
                        Text("Conecta tu app Dieta en Ajustes › Nutrición para ver aquí el menú y marcar lo que comes. El agua y lo que apuntes funcionan igual sin ella.")
                            .font(.fig(13, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
                    }
                    waterBlock
                    quickLog
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
            .refreshable { await n.refresh() }
        }
        .task { await n.refresh() }
        .sheet(isPresented: $scanning) {
            BarcodeScanner { code in
                scanning = false
                Task { await lookup(code) }
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder private var menu: some View {
        let meals = n.meals()
        let target = n.targets()
        let eaten = n.eaten()
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                UpperLabel(text: "Menú de Dieta", p: p)
                Spacer()
                if n.syncing { ProgressView().scaleEffect(0.7) }
                if let t = target {
                    Text("\(Int(eaten.kcal)) / \(Int(t.kcal)) kcal · \(Int(eaten.protein)) / \(Int(t.protein)) g")
                        .font(.fig(12, .bold)).foregroundColor(p.acc)
                }
            }
            if meals.isEmpty {
                Text(n.plan == nil ? "Dieta no tiene plan para esta semana." : "Hoy no hay platos en el plan.")
                    .font(.fig(13, .medium)).foregroundColor(p.mute)
            }
            ForEach(meals) { m in
                Button { Task { await n.setEaten(m, !m.eaten) } } label: {
                    HStack(spacing: 10) {
                        Image(systemName: m.eaten ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20)).foregroundColor(m.eaten ? p.acc : p.mute)
                        VStack(alignment: .leading, spacing: 2) {
                            Text((m.slotLabel).loc).font(.fig(11, .semibold)).foregroundColor(p.mute)
                            Text((m.recipe.title).loc).font(.fig(14, .semibold)).foregroundColor(p.ink).multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Text("\(Int(m.kcal)) kcal\n\(Int(m.protein)) g prot").font(.fig(11, .semibold)).foregroundColor(p.mute)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.soft))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("meal.\(m.slot)")
            }
        }
    }

    private var waterBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                UpperLabel(text: "Agua", p: p)
                Spacer()
                Text("\(n.water()) de \(n.waterGoal) ml").font(.fig(12, .bold)).foregroundColor(p.acc)
                    .accessibilityIdentifier("water.total")
            }
            HStack(spacing: 8) {
                ForEach([150, 250, 500], id: \.self) { ml in
                    SoftButton(title: "+\(ml)", icon: "drop.fill", height: 38, fontSize: 13, p: p) { n.addWater(ml) }
                        .accessibilityIdentifier("water.\(ml)")
                }
                SoftButton(title: "−250", height: 38, fontSize: 13, p: p) { n.addWater(-250) }
            }
        }
    }

    private var quickLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            UpperLabel(text: "Fuera del plan", p: p)
            ForEach(n.logs()) { l in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text((l.name).loc).font(.fig(14, .semibold)).foregroundColor(p.ink)
                        Text("\(Int(l.kcal)) kcal · \(Int(l.protein)) g prot\(l.grams.map { " · \(Int($0)) g" } ?? "")")
                            .font(.fig(12, .medium)).foregroundColor(p.mute)
                    }
                    Spacer()
                    Button { n.removeLog(l.id) } label: { Image(systemName: "trash") }.foregroundColor(p.danger)
                }
            }
            if let s = scanned {
                VStack(alignment: .leading, spacing: 8) {
                    Text((s.name).loc).font(.fig(15, .bold)).foregroundColor(p.ink)
                    Text("\(s.brand.map { "\($0) · " } ?? "")\(Int(s.kcal)) kcal y \(String(format: "%.1f", s.protein)) g de proteína por 100 g · \(s.source)")
                        .font(.fig(12, .medium)).foregroundColor(p.mute)
                    HStack {
                        PulsoField(placeholder: "Gramos", text: $grams, keyboard: .numberPad, p: p).frame(width: 110)
                            .accessibilityIdentifier("scan.grams")
                        PrimaryButton(title: "Apuntar", icon: "plus", height: 44, p: p) {
                            let g = Double(grams) ?? 100
                            n.addLog(FoodLog(name: s.name, kcal: s.kcal * g / 100, protein: s.protein * g / 100, grams: g, ean: s.ean))
                            scanned = nil
                        }
                        .accessibilityIdentifier("scan.add")
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
            }
            if let m = lookupMessage { Text((m).loc).font(.fig(12, .medium)).foregroundColor(p.mute) }
            PulsoField(placeholder: "Qué has comido", text: $name, p: p).accessibilityIdentifier("log.name")
            HStack(spacing: 8) {
                PulsoField(placeholder: "kcal", text: $kcal, keyboard: .numberPad, p: p).accessibilityIdentifier("log.kcal")
                PulsoField(placeholder: "Proteína (g)", text: $protein, keyboard: .numberPad, p: p).accessibilityIdentifier("log.protein")
            }
            HStack(spacing: 8) {
                SoftButton(title: "Escanear", icon: "barcode.viewfinder", height: 44, p: p) {
                    if DataScannerViewController.isSupported && DataScannerViewController.isAvailable { scanning = true }
                    else { lookupMessage = "La cámara no puede escanear en este iPhone." }
                }
                .accessibilityIdentifier("log.scan")
                PrimaryButton(title: "Apuntar", icon: "plus", height: 44,
                              enabled: !name.trimmingCharacters(in: .whitespaces).isEmpty && Double(kcal) != nil, p: p) {
                    n.addLog(FoodLog(name: name.trimmingCharacters(in: .whitespaces), kcal: Double(kcal) ?? 0,
                                     protein: Double(protein.replacingOccurrences(of: ",", with: ".")) ?? 0))
                    name = ""; kcal = ""; protein = ""
                }
                .accessibilityIdentifier("log.add")
            }
        }
    }

    private func lookup(_ code: String) async {
        lookupMessage = String(localized: "Buscando \(code)…")
        if let prod = await n.lookup(ean: code) {
            scanned = prod
            grams = "100"
            lookupMessage = nil
        } else {
            lookupMessage = String(localized: "No encuentro el código \(code). Apúntalo a mano.")
        }
    }
}

// MARK: - Escáner

struct BarcodeScanner: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce])],
                                           qualityLevel: .balanced, isHighlightingEnabled: true)
        vc.delegate = context.coordinator
        try? vc.startScanning()
        return vc
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCode: (String) -> Void
        private var done = false
        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }

        func dataScanner(_ scanner: DataScannerViewController, didAdd items: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !done else { return }
            for item in items {
                if case .barcode(let b) = item, let code = b.payloadStringValue, !code.isEmpty {
                    done = true
                    scanner.stopScanning()
                    HapticManager.shared.success()
                    onCode(code)
                    return
                }
            }
        }
    }
}

// MARK: - Ajustes › Nutrición

struct NutritionSettingsSheet: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var n = Nutrition.shared
    @State private var email = ""
    @State private var password = ""
    @State private var url = ""
    @State private var working = false

    private var p: Palette { themeManager.p }

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: "Ajustes", p: p)
                    Text("Nutrición").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    UpperLabel(text: "App Dieta", p: p)
                    if n.connected {
                        Label("Conectado a \(n.baseURL)", systemImage: "checkmark.seal.fill").font(.fig(13, .semibold)).foregroundColor(p.acc)
                        Toggle("Sincronizar el peso en los dos sentidos", isOn: Binding(get: { n.syncWeight }, set: { n.syncWeight = $0 }))
                            .font(.fig(14, .semibold)).tint(p.acc)
                        SoftButton(title: "Desconectar", height: 40, fontSize: 13, color: p.danger, p: p) { n.disconnect() }
                            .accessibilityIdentifier("dieta.disconnect")
                    } else {
                        Text("Con tu cuenta de Dieta, ChamaFit enseña el menú de hoy, sus calorías y proteína frente a tu objetivo, y sincroniza el peso. Solo funciona con Tailscale activo.")
                            .font(.fig(13, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
                        PulsoField(placeholder: DietaClient.defaultURL, text: $url, keyboard: .URL, p: p)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        PulsoField(placeholder: "Correo", text: $email, keyboard: .emailAddress, p: p)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .accessibilityIdentifier("dieta.email")
                        SecureField("Contraseña", text: $password)
                            .font(.fig(15, .semibold)).padding(.horizontal, 16).frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.soft))
                            .accessibilityIdentifier("dieta.password")
                        if let e = n.lastError { Text((e).loc).font(.fig(12, .medium)).foregroundColor(p.danger) }
                        PrimaryButton(title: working ? "Conectando…" : "Conectar", icon: "link", height: 46,
                                      enabled: !working && !email.isEmpty && !password.isEmpty, p: p) {
                            working = true
                            if !url.trimmingCharacters(in: .whitespaces).isEmpty { n.baseURL = url.trimmingCharacters(in: .whitespaces) }
                            Task {
                                if await n.connect(email: email, password: password) {
                                    password = ""
                                    await n.pullWeights(into: viewModel)
                                }
                                working = false
                            }
                        }
                        .accessibilityIdentifier("dieta.connect")
                    }
                    UpperLabel(text: "Agua", p: p).padding(.top, 8)
                    Stepper("Objetivo: \(n.waterGoal) ml", value: Binding(get: { n.waterGoal }, set: { n.waterGoal = $0 }), in: 500...6000, step: 250)
                        .font(.fig(14, .semibold))
                    if HealthManager.shared.isAvailable {
                        Toggle("Guardar el agua en Salud", isOn: Binding(get: { n.waterToHealth }, set: { on in
                            n.waterToHealth = on
                            if on { Task { await HealthManager.shared.requestAccess() } }
                        }))
                        .font(.fig(14, .semibold)).tint(p.acc)
                    }
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        }
        .onAppear { url = n.baseURL == DietaClient.defaultURL ? "" : n.baseURL }
    }
}
