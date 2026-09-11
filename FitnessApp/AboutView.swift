//
//  AboutView.swift
//  ChamaFit
//
//  Acerca de: versión y novedades, qué datos van a dónde, créditos y
//  licencias, preguntas frecuentes y enviar comentarios.
//

import SwiftUI
import UIKit

struct AboutView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var openFAQ: Int? = nil

    private var p: Palette { themeManager.p }

    static var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(v) (\(b))"
    }

    /// Modelo del iPhone ("iPhone17,1") para los comentarios.
    static var deviceModel: String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    static let whatsNew: [(String, String)] = [
        ("person.text.rectangle", "Tu perfil de entreno: objetivo, nivel, días, material y preferencias."),
        ("calendar.badge.clock", "Semana fija, semana flexible o secuencia A/B/C sin días fijos."),
        ("chart.line.uptrend.xyaxis", "Programas de 8 a 12 semanas con progresión y descargas."),
        ("arrow.triangle.2.circlepath", "Circuitos, AMRAP y EMOM en el modo entreno."),
        ("scalemass", "Kilos o libras, y tipo de carga: por mancuerna, por lado, asistido o lastre."),
        ("books.vertical.fill", "83 ejercicios con vídeo, errores habituales, variantes y alternativas con tu material."),
        ("clock", "«Tengo hasta las…», «Hoy me cuesta» y «Está ocupada»."),
        ("flask.fill", "Experimentos: compara dos formas de entrenar y mira si la diferencia es real."),
        ("mic.fill", "Apunta series hablando: «80 kilos por 8»."),
        ("figure.highintensity.intervaltraining", "Intervalos HIIT y rutinas de movilidad por tiempo."),
        ("fork.knife", "Comida de hoy con tu app Dieta, agua y escáner de códigos de barras."),
        ("person.2.fill", "Amigos y retos por iCloud."),
        ("calendar.badge.plus", "Tus sesiones en el Calendario del iPhone."),
    ]

    static let privacy: [(String, String, String)] = [
        ("iphone", "En tu iPhone", "Rutinas, historial, notas, peso, perfil, agua, experimentos y copias. No hay cuenta ni servidor de ChamaFit."),
        ("apple.intelligence", "Apple Intelligence", "El coach gratis y las rutinas con IA del iPhone funcionan sin salir del teléfono."),
        ("sparkles", "Anthropic (Claude)", "Solo si usas el coach con tu propia clave: se envía un resumen de tu rutina y semana, y tus datos de Salud solo si lo activas."),
        ("heart.fill", "Salud de Apple", "Si lo permites: se leen sueño, pulso, pasos y peso; se guardan entrenos, peso y agua."),
        ("icloud.fill", "iCloud", "Amigos y retos: solo tu nombre, tu código y el resumen que elijas compartir."),
        ("fork.knife", "Tu servidor de Dieta", "Si lo conectas: el menú, lo que marcas como comido y tu peso."),
        ("barcode.viewfinder", "Open Food Facts", "Al escanear sin Dieta: solo el código de barras."),
        ("mic.fill", "Voz", "Se reconoce en el iPhone si el idioma lo permite; si no, Apple la procesa. El audio no se guarda."),
        ("play.rectangle.fill", "YouTube y Spotify", "Los vídeos se abren en YouTube; la música, si conectas Spotify."),
    ]

    static let faq: [(String, String)] = [
        ("¿Pierdo algo si borro la app?", "Sí, todo vive en el iPhone. Haz una copia en Ajustes › Coach y datos › Copia de seguridad; además se guarda una semanal en Archivos › ChamaFit."),
        ("¿Por qué no me sube el peso sugerido?", "Sube cuando completas todas las repeticiones sin ir al fallo. Con la recuperación en rojo, o en semana de descarga, se mantiene o baja a propósito."),
        ("¿Qué es la semana flexible?", "Tus sesiones de la semana, el día que puedas. Lo que no hagas queda pendiente hasta el domingo y Inicio te propone la primera."),
        ("¿Cómo cambio a libras?", "Ajustes › Entrenamiento › Unidad de peso. Tus datos no cambian: solo cómo se ven."),
        ("¿Por qué no veo el menú de Dieta?", "Necesitas Tailscale activo en el iPhone y conectar tu cuenta en Ajustes › Nutrición."),
        ("La voz no me entiende", "Habla cerca del iPhone y di peso y repeticiones: «80 kilos por 8». En catalán puede necesitar conexión."),
    ]

    var body: some View {
        PulsoSheet(p: p) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    UpperLabel(text: String(localized: "Versión \(Self.version)"), p: p)
                    Text("Acerca de ChamaFit").font(.bri(22)).em(-0.02, size: 22).foregroundColor(p.ink)
                }
                Spacer()
                CloseCircle(p: p) { dismiss() }
            }
            .padding(.horizontal, 22).padding(.top, 22)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    section("Novedades") {
                        ForEach(Array(Self.whatsNew.enumerated()), id: \.offset) { _, n in row(n.0, nil, n.1) }
                    }
                    section("Tus datos, dónde van") {
                        ForEach(Array(Self.privacy.enumerated()), id: \.offset) { _, n in row(n.0, n.1, n.2) }
                    }
                    .accessibilityIdentifier("about.privacy")
                    section("Preguntas frecuentes") {
                        ForEach(Array(Self.faq.enumerated()), id: \.offset) { i, q in
                            VStack(alignment: .leading, spacing: 6) {
                                Button { withAnimation { openFAQ = openFAQ == i ? nil : i } } label: {
                                    HStack {
                                        Text((q.0).loc).font(.fig(14, .semibold)).foregroundColor(p.ink).multilineTextAlignment(.leading)
                                        Spacer()
                                        Image(systemName: openFAQ == i ? "chevron.up" : "chevron.down").foregroundColor(p.mute)
                                    }
                                }
                                .buttonStyle(.plain)
                                if openFAQ == i {
                                    Text((q.1).loc).font(.fig(13, .medium)).foregroundColor(p.mute).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    section("Créditos y licencias") {
                        Text("Ilustraciones de técnica: wger.de (licencias Creative Commons). Autores: \(Self.photoAuthors). Licencias: \(Self.photoLicenses).")
                            .font(.fig(13, .medium)).foregroundColor(p.ink).fixedSize(horizontal: false, vertical: true)
                        Text("Tipografías Bricolage Grotesque y Figtree, con licencia SIL Open Font License 1.1.")
                            .font(.fig(13, .medium)).foregroundColor(p.ink)
                        Text("Datos de productos: Open Food Facts (ODbL). Vídeos de técnica: sus autores en YouTube.")
                            .font(.fig(13, .medium)).foregroundColor(p.ink)
                        Button("Ver las licencias CC BY-SA y OFL") {
                            openURL(URL(string: "https://creativecommons.org/licenses/by-sa/4.0/deed.es")!)
                        }
                        .font(.fig(13, .semibold)).foregroundColor(p.acc)
                    }
                    .accessibilityIdentifier("about.credits")
                    section("¿Algo va mal o echas algo en falta?") {
                        Text("Cuéntalo con tus palabras. El mensaje ya lleva la versión y el modelo de iPhone.")
                            .font(.fig(13, .medium)).foregroundColor(p.mute)
                        feedbackButton
                    }
                }
                .padding(.horizontal, 22).padding(.vertical, 16)
            }
        }
    }

    static var photoAuthors: String {
        Array(Set(TechniquePhotos.byName.values.map(\.author))).sorted().joined(separator: ", ")
    }

    static var photoLicenses: String {
        Array(Set(TechniquePhotos.byName.values.map(\.license))).sorted().joined(separator: ", ")
    }

    static var feedbackBody: String {
        String(localized: "\n\n—\nChamaFit \(version) · \(deviceModel) · iOS \(UIDevice.current.systemVersion) · \(Locale.current.identifier)")
    }

    /// Correo si la app lleva dirección de soporte (clave SupportEmail); si no, compartir.
    @ViewBuilder private var feedbackButton: some View {
        if let email = Bundle.main.object(forInfoDictionaryKey: "SupportEmail") as? String, !email.isEmpty,
           let url = URL(string: "mailto:\(email)?subject=\("Comentarios ChamaFit".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(Self.feedbackBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            PrimaryButton(title: "Enviar comentarios", icon: "envelope.fill", height: 46, p: p) { openURL(url) }
                .accessibilityIdentifier("about.feedback")
        } else {
            ShareLink(item: "Comentarios sobre ChamaFit:" + Self.feedbackBody) {
                Label("Enviar comentarios", systemImage: "square.and.arrow.up")
                    .font(.fig(14, .bold)).foregroundColor(p.onacc)
                    .frame(maxWidth: .infinity).frame(height: 46)
                    .background(Capsule().fill(p.hgrad))
            }
            .accessibilityIdentifier("about.feedback")
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            UpperLabel(text: title, p: p)
            content()
        }
    }

    private func row(_ icon: String, _ title: String?, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundColor(p.acc).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                if let title { Text((title).loc).font(.fig(14, .bold)).foregroundColor(p.ink) }
                Text((text).loc).font(.fig(13, .medium)).foregroundColor(title == nil ? p.ink : p.mute)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
