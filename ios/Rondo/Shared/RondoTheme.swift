import SwiftUI

/// De kleuren uit BRAND.md. Twee stemmen (puls en diep) plus amber, op inkt.
///
/// Regel uit de huisstijl: nooit meer dan één accentkleur tegelijk op het
/// scherm — de fase bepaalt welke. De ring onderscheidt werk van rust dus met
/// *dikte*, niet met kleur.
enum RondoTheme {
    static let ink = Color(hex: 0x101217)
    static let inkRaised = Color(hex: 0x191C23)
    static let bone = Color(hex: 0xF2EFE8)

    static let puls = Color(hex: 0xFF2E63)
    static let diep = Color(hex: 0x00C2A8)
    static let amber = Color(hex: 0xFFB443)

    /// Op papier (lichte modus) gaan puls en diep een tint dieper.
    static let pulsPaper = Color(hex: 0xE31B50)
    static let diepPaper = Color(hex: 0x00897B)

    /// Het accent van de huidige fase. Zonder fase (nog niet gestart, of
    /// klaar) is puls de rustende stem: de ring staat er al, in de kleur
    /// waarmee de training begint.
    static func accent(for phase: Phase?, scheme: ColorScheme = .dark) -> Color {
        let paper = scheme == .light
        switch phase {
        case .work: return paper ? pulsPaper : puls
        case .rest: return paper ? diepPaper : diep
        case .reset: return amber
        case nil: return paper ? pulsPaper : puls
        }
    }

    /// Vlakken dragen nooit een accent — alleen inkt.
    static func surface(for scheme: ColorScheme = .dark) -> Color {
        scheme == .light ? bone : ink
    }

    static func raised(for scheme: ColorScheme = .dark) -> Color {
        scheme == .light ? Color(hex: 0xE6E2D9) : inkRaised
    }

    static func text(for scheme: ColorScheme = .dark) -> Color {
        scheme == .light ? ink : bone
    }
}

/// Een accent als losse componenten, zodat `RondoDial` de kleurwissel in
/// 400 ms kan interpoleren — een `Canvas` interpoleert zijn invoer niet zelf,
/// dus de ring zou anders springen, en de huisstijl zegt: verandering reist.
struct RondoAccent: Equatable {
    var red: Double
    var green: Double
    var blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }
}

extension RondoTheme {
    static func accentParts(for phase: Phase?, scheme: ColorScheme = .dark) -> RondoAccent {
        let paper = scheme == .light
        switch phase {
        case .work: return RondoAccent(hex: paper ? 0xE31B50 : 0xFF2E63)
        case .rest: return RondoAccent(hex: paper ? 0x00897B : 0x00C2A8)
        case .reset: return RondoAccent(hex: 0xFFB443)
        case nil: return RondoAccent(hex: paper ? 0xE31B50 : 0xFF2E63)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
