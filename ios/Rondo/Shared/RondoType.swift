import CoreText
import Foundation
import SwiftUI

/// Archivo, variabel, met de breedte-as als verschil tussen de twee stemmen.
///
/// De variabele TTF zit in de bundel (`Fonts/Archivo-Variable.ttf`, OFL) en
/// wordt via `UIAppFonts` geregistreerd. SwiftUI kan geen variatie-assen
/// zetten, dus de assen gaan via CoreText en het resultaat komt als
/// `Font(CTFont)` terug. Staat Archivo er niet, dan valt alles terug op het
/// systeemfont — de app blijft dan werken, alleen smaller van stem.
enum RondoType {
    /// Cijfers: wdth 85, gewicht 600, tabular-nums.
    static func numerals(_ size: CGFloat) -> Font {
        if let font = archivo(size: size, weight: 600, width: 85) {
            return font.monospacedDigit()
        }
        return Font.system(size: size, weight: .semibold).monospacedDigit()
    }

    /// Labels: wdth 100, gewicht 700, hoofdletters (de view doet de caps).
    static func label(_ size: CGFloat) -> Font {
        if let font = archivo(size: size, weight: 700, width: 100) {
            return font
        }
        return Font.system(size: size, weight: .bold)
    }

    /// Lopende tekst: gewicht 400.
    static func body(_ size: CGFloat, weight: CGFloat = 400) -> Font {
        if let font = archivo(size: size, weight: weight, width: 100) {
            return font
        }
        return Font.system(size: size, weight: weight >= 600 ? .semibold : .regular)
    }

    /// Letterafstand uit de huisstijl, in punten bij een gegeven corpsgrootte.
    static func numeralTracking(_ size: CGFloat) -> CGFloat { -0.02 * size }
    static func labelTracking(_ size: CGFloat) -> CGFloat { 0.14 * size }

    /// Is Archivo beschikbaar? Gebruikt door de README-controle en de tests.
    static var hasArchivo: Bool { descriptor != nil }

    // MARK: - CoreText

    private static let wghtAxis = NSNumber(value: 0x77676874 as UInt32) as CFNumber
    private static let wdthAxis = NSNumber(value: 0x77647468 as UInt32) as CFNumber

    private static let descriptor: CTFontDescriptor? = {
        for name in ["Archivo", "Archivo-SemiBold", "Archivo-Regular", "ArchivoRoman-Regular"] {
            let candidate = CTFontCreateWithName(name as CFString, 16, nil)
            let family = CTFontCopyFamilyName(candidate) as String
            if family.lowercased().contains("archivo") {
                return CTFontCopyFontDescriptor(candidate)
            }
        }
        return nil
    }()

    private static func archivo(size: CGFloat, weight: CGFloat, width: CGFloat) -> Font? {
        guard let base = descriptor else { return nil }
        let withWeight = CTFontDescriptorCreateCopyWithVariation(base, wghtAxis, weight)
        let withWidth = CTFontDescriptorCreateCopyWithVariation(withWeight, wdthAxis, width)
        let font = CTFontCreateWithFontDescriptor(withWidth, size, nil)
        return Font(font)
    }
}

extension Text {
    /// Cijfers zoals in de huisstijl: groot, smal, zwaar, met vaste cijferbreedte.
    func rondoNumerals(_ size: CGFloat) -> some View {
        self.font(RondoType.numerals(size))
            .tracking(RondoType.numeralTracking(size))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    /// Labels: klein, hoofdletters, ruim gespatieerd.
    func rondoLabel(_ size: CGFloat) -> some View {
        self.font(RondoType.label(size))
            .tracking(RondoType.labelTracking(size))
            .textCase(.uppercase)
            .lineLimit(1)
    }
}
