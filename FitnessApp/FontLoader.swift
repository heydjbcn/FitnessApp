//
//  FontLoader.swift
//  FitnessApp
//
//  Registra las fuentes personalizadas (Bricolage Grotesque / Figtree) en
//  tiempo de ejecución, sin depender de UIAppFonts en el Info.plist
//  (el proyecto usa GENERATE_INFOPLIST_FILE = YES).
//

import CoreText
import Foundation

enum FontLoader {
    private static let fontNames = [
        // Titulares del rediseño «Pulso»
        "BricolageGrotesque-Bold",
        "BricolageGrotesque-ExtraBold",
        // Texto
        "Figtree-Regular",
        "Figtree-Medium",
        "Figtree-SemiBold",
        "Figtree-Bold"
    ]

    private static var didRegister = false

    static func registerFonts() {
        guard !didRegister else { return }
        didRegister = true
        for name in fontNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                print("FontLoader: no se encontró \(name).ttf en el bundle")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                print("FontLoader: fallo registrando \(name): \(String(describing: error))")
            }
        }
    }
}
