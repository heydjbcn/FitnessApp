//
//  AppFonts.swift
//  FitnessApp
//
//  Sistema de fuentes moderno para la aplicación
//

import SwiftUI

struct AppFonts {
    // MARK: - Fuentes principales
    
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let subheadline = Font.system(size: 15, weight: .semibold, design: .rounded)
    
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 17, weight: .medium, design: .rounded)
    static let bodyBold = Font.system(size: 17, weight: .bold, design: .rounded)
    
    static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
    static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
    
    // MARK: - Fuentes especiales para números y métricas
    
    static let metric = Font.system(size: 24, weight: .bold, design: .rounded)
    static let bigMetric = Font.system(size: 32, weight: .bold, design: .rounded)
    static let smallMetric = Font.system(size: 18, weight: .semibold, design: .rounded)
    
    // MARK: - Fuentes para botones
    
    static let button = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let smallButton = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let largeButton = Font.system(size: 19, weight: .semibold, design: .rounded)
    
    // MARK: - Fuentes para navegación
    
    static let navigationTitle = Font.system(size: 20, weight: .bold, design: .rounded)
    static let tabBar = Font.system(size: 10, weight: .medium, design: .rounded)
    
    // MARK: - Fuentes para tarjetas y componentes
    
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let cardSubtitle = Font.system(size: 14, weight: .medium, design: .rounded)
    static let cardBody = Font.system(size: 15, weight: .regular, design: .rounded)
    
    // Para compatibilidad con código existente
    static let subtitle = title3
}
