import SwiftUI

/// De kleuren uit BRAND.md. Twee stemmen (puls en diep) plus amber, op inkt
/// of op papier.
///
/// Regel uit de huisstijl: nooit meer dan één accentkleur tegelijk op het
/// scherm — de fase bepaalt welke. De ring onderscheidt arbeid van rust dus
/// met *dikte*, niet met kleur.
enum RondoTheme {
    static let ink = Color(hex: 0x101217)
    static let inkRaised = Color(hex: 0x191C23)
    static let bone = Color(hex: 0xF2EFE8)
    static let paperRaised = Color(hex: 0xE6E2D9)

    static let puls = Color(hex: 0xFF2E63)
    static let diep = Color(hex: 0x00C2A8)
    static let amber = Color(hex: 0xFFB443)
}

/// De kleuren voor één modus, met dezelfde namen en waarden als de
/// CSS-variabelen van de webversie (`web/styles.css`). De iPhone volgt de
/// lichte of donkere modus van het toestel; de Watch is altijd inkt.
struct RondoPalette {
    let isPaper: Bool

    init(_ scheme: ColorScheme) {
        isPaper = scheme == .light
    }

    /// Achtergrond: inkt, of bot op papier.
    var bg: Color { isPaper ? RondoTheme.bone : RondoTheme.ink }
    /// Tekst en de rustende ring.
    var fg: Color { isPaper ? RondoTheme.ink : RondoTheme.bone }
    /// Een ingedrukte chip of knop. Vlakken dragen nooit een accent.
    var raised: Color { isPaper ? RondoTheme.paperRaised : RondoTheme.inkRaised }
    /// Haarlijnen: randen van chips en knoppen.
    var hair: Color { fg.opacity(isPaper ? 0.16 : 0.18) }
    /// Gedempte tekst: labels en bijschriften.
    var mute: Color { fg.opacity(isPaper ? 0.6 : 0.55) }

    /// Het accent van de huidige fase, als losse componenten zodat de ring de
    /// kleurwissel kan kruisvervagen. Zonder fase (nog niet gestart, of klaar)
    /// is er geen accent: label en ring staan in de tekstkleur. Op papier zijn
    /// de accenten een tint dieper, zodat ze op bot leesbaar blijven.
    func accent(for phase: Phase?) -> RondoAccent {
        switch phase {
        case .work: return RondoAccent(hex: isPaper ? 0xE31B50 : 0xFF2E63)
        case .rest: return RondoAccent(hex: isPaper ? 0x00897B : 0x00C2A8)
        case .reset: return RondoAccent(hex: isPaper ? 0xA86A00 : 0xFFB443)
        case nil: return RondoAccent(hex: isPaper ? 0x101217 : 0xF2EFE8)
        }
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
