import SwiftUI

/// De cirkelpartituur — het handschrift van Rondo.
///
/// Eén boog per interval, booglengte in verhouding tot de duur. Arbeidsbogen
/// zijn dik, rustbogen dun, dus je leest het ritme van de training voordat
/// je begint.
///
/// De ring tekent precies wat de webversie tekent (`web/app.js`), met dezelfde
/// maten: komende bogen op volle dikte maar zacht, gelopen bogen als
/// ingetogen streepjes, en de lopende boog in het accent van de fase, die
/// zich vult terwijl de klok loopt. Alle uiteinden zijn rond.
///
/// Eén accent tegelijk: alleen de lopende boog draagt kleur. De rest staat in
/// de tekstkleur, zodat er nooit een tweede accent in beeld is.
struct RondoDial: View, Animatable {
    /// Het hele programma, in volgorde.
    var segments: [Segment]
    /// Index van de lopende boog in `segments`.
    var index: Int
    /// Voortgang binnen de lopende boog, 0…1.
    var fraction: Double
    var isFinished: Bool
    var hasStarted: Bool
    /// Het accent van de huidige fase, als componenten zodat de kleurwissel
    /// kan kruisvervagen in plaats van springen.
    var accent: RondoAccent
    /// Kleur van de gelopen en komende bogen: de tekstkleur.
    var ink: Color
    /// Straal als deel van de zijde. De webversie tekent op 132/320 en laat
    /// zo ruimte rond de ring; `nil` vult het vlak (de Watch).
    var radiusFraction: CGFloat?
    /// Schaalt alle lijndiktes — de Watch wil iets steviger lijnen dan de iPhone.
    var weight: CGFloat

    init(segments: [Segment],
         index: Int,
         fraction: Double,
         isFinished: Bool,
         hasStarted: Bool,
         accent: RondoAccent,
         ink: Color,
         radiusFraction: CGFloat? = nil,
         weight: CGFloat = 1) {
        self.segments = segments
        self.index = index
        self.fraction = fraction
        self.isFinished = isFinished
        self.hasStarted = hasStarted
        self.accent = accent
        self.ink = ink
        self.radiusFraction = radiusFraction
        self.weight = weight
    }

    /// De fasewissel reist: SwiftUI interpoleert de accentcomponenten en
    /// hertekent de ring per frame.
    var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get { AnimatablePair(accent.red, AnimatablePair(accent.green, accent.blue)) }
        set {
            accent = RondoAccent(red: newValue.first,
                                 green: newValue.second.first,
                                 blue: newValue.second.second)
        }
    }

    var body: some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: false) { context, size in
            draw(in: &context, size: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    // MARK: - Maten van de webversie

    /// De webversie tekent in een vlak van 320 met straal 132. Alle maten
    /// hieronder zijn in die eenheden en schalen mee met de straal.
    private static let webRadius: CGFloat = 132
    /// Ruimte tussen de bogen, in graden.
    private static let gap = 1.4

    /// Arbeid dik, rust dun, pauze ertussenin — de dikte draagt het ritme.
    private static func webWidth(for phase: Phase) -> CGFloat {
        switch phase {
        case .work: return 12
        case .rest: return 5
        case .reset: return 7
        }
    }

    // MARK: - Tekenen

    private enum ArcState {
        case done, running, upcoming
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let side = min(size.width, size.height)
        guard side > 24 else { return }

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let thickest = Self.webWidth(for: .work) * weight
        // Zonder vaste verhouding vult de ring het vlak: de dikste boog raakt
        // dan precies de rand.
        let radius = radiusFraction.map { side * $0 }
            ?? side / 2 / (1 + thickest / 2 / Self.webRadius)
        guard radius > 4 else { return }
        let unit = radius / Self.webRadius

        let total = segments.reduce(0.0) { $0 + Double(max(0, $1.duration)) }
        guard total > 0 else {
            // Leeg programma: één zachte cirkel, zodat de ring er al staat.
            stroke(&context, center: center, radius: radius, from: -90, to: 270,
                   color: ink.opacity(0.15), width: Self.webWidth(for: .rest) * unit * weight)
            return
        }

        // De lopende boog komt als laatste, bovenop de rest.
        var running: (from: Double, to: Double, width: CGFloat)?

        var cursor = 0.0
        for (i, segment) in segments.enumerated() {
            let duration = Double(max(0, segment.duration))
            let from = cursor / total * 360
            cursor += duration
            let to = cursor / total * 360
            guard to - from > 0.01 else { continue }

            let pad = min(Self.gap / 2, (to - from) / 4)
            let a0 = from + pad - 90
            let a1 = to - pad - 90
            let width = Self.webWidth(for: segment.phase) * unit * weight

            let state: ArcState
            if !hasStarted {
                state = .upcoming
            } else if isFinished || i < index {
                state = .done
            } else if i == index {
                state = .running
            } else {
                state = .upcoming
            }

            switch state {
            case .done:
                // Gelopen: ingetogen streepjes, zodat je ziet wat je gehad hebt.
                stroke(&context, center: center, radius: radius, from: a0, to: a1,
                       color: ink.opacity(0.26), width: width, dash: [1.5 * unit, 5 * unit])
            case .upcoming:
                // Volle dikte, zacht: het ritme van de training is al leesbaar.
                stroke(&context, center: center, radius: radius, from: a0, to: a1,
                       color: ink.opacity(0.15), width: width)
            case .running:
                running = (a0, a1, width)
            }
        }

        if let running {
            let pen = accent.color
            // Het nog te gaan deel blijft zichtbaar, het afgelegde deel is
            // vol: zo reist de voortgang langs de ring.
            stroke(&context, center: center, radius: radius, from: running.from, to: running.to,
                   color: pen.opacity(0.22), width: running.width)
            let done = min(1, max(0, fraction))
            let tip = running.from + (running.to - running.from) * done
            if tip - running.from > 0.01 {
                stroke(&context, center: center, radius: radius, from: running.from, to: tip,
                       color: pen, width: running.width)
            }
        }
    }

    private func stroke(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat,
                        from a0: Double, to a1: Double, color: Color, width: CGFloat,
                        dash: [CGFloat] = []) {
        var path = Path()
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(a0), endAngle: .degrees(a1), clockwise: false)
        context.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash))
    }
}

#if DEBUG
#Preview("Dial") {
    let palette = RondoPalette(.dark)
    return ZStack {
        palette.bg.ignoresSafeArea()
        RondoDial(segments: Workout().segments,
                  index: 5,
                  fraction: 0.45,
                  isFinished: false,
                  hasStarted: true,
                  accent: palette.accent(for: .rest),
                  ink: palette.fg,
                  radiusFraction: 132.0 / 320.0)
            .padding(24)
    }
}
#endif
