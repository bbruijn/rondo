import SwiftUI

/// De cirkelpartituur — het handschrift van Rondo.
///
/// Eén boog per interval, booglengte in verhouding tot de duur. Werkbogen
/// zijn dik, rustbogen dun, dus je leest het ritme van de training voordat
/// je begint. Afgelopen bogen doven naar 20 %, de lopende boog is vol en iets
/// dikker, komende bogen zijn haarlijnen (die hun dikteverhouding houden,
/// anders verdwijnt het ritme vóór de start).
///
/// Eén accent tegelijk: alle bogen staan in de kleur van de huidige fase,
/// het verschil zit in dikte en dekking. De komende bogen staan in bot, zodat
/// er nooit een tweede accent in beeld is.
struct RondoDial: View, Animatable {
    /// Het hele programma, in volgorde.
    var segments: [Segment]
    /// Index van de lopende boog in `segments`.
    var index: Int
    /// Voortgang binnen de lopende boog, 0…1.
    var fraction: Double
    var isRunning: Bool
    var isFinished: Bool
    var hasStarted: Bool
    /// Het accent van de huidige fase, als componenten zodat de kleurwissel
    /// kan kruisvervagen in plaats van springen.
    var accent: RondoAccent
    /// Kleur van de komende bogen (bot).
    var track: Color
    /// Schaalt alle lijndiktes — de Watch wil iets steviger lijnen dan de iPhone.
    var weight: CGFloat
    /// Ruimte tussen de bogen, in graden.
    var gap: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Expliciete init: met een `private` eigenschap in de struct is de
    /// gesynthetiseerde memberwise-init niet buiten dit bestand te gebruiken,
    /// en de ring wordt juist vanuit beide apps opgebouwd.
    init(segments: [Segment],
         index: Int,
         fraction: Double,
         isRunning: Bool,
         isFinished: Bool,
         hasStarted: Bool,
         accent: RondoAccent,
         track: Color = RondoTheme.bone,
         weight: CGFloat = 1,
         gap: Double = 1.1) {
        self.segments = segments
        self.index = index
        self.fraction = fraction
        self.isRunning = isRunning
        self.isFinished = isFinished
        self.hasStarted = hasStarted
        self.accent = accent
        self.track = track
        self.weight = weight
        self.gap = gap
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
        content
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        if isRunning && !reduceMotion {
            // De lopende boog ademt: 2 s cyclus, zodat je ziet dat hij loopt.
            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { timeline in
                canvas(breath: Self.breath(at: timeline.date))
            }
        } else {
            canvas(breath: 0)
        }
    }

    private func canvas(breath: Double) -> some View {
        Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: false) { context, size in
            draw(in: &context, size: size, breath: breath)
        }
    }

    // MARK: - Tekenen

    private func draw(in context: inout GraphicsContext, size: CGSize, breath: Double) {
        let side = min(size.width, size.height)
        guard side > 24 else { return }

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let thickest = lineWidth(for: .work, state: .running, breath: 1, side: side)
        let radius = (side - thickest) / 2 - side * 0.01
        guard radius > 4 else { return }

        let pen = accent.color
        let total = segments.reduce(0.0) { $0 + Double(max(0, $1.duration)) }
        guard total > 0 else {
            // Leeg programma: één haarlijn als cirkel, zodat de ring er al staat.
            var ring = Path()
            ring.addArc(center: center, radius: radius,
                        startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
            context.stroke(ring, with: .color(track.opacity(0.22)),
                           style: StrokeStyle(lineWidth: max(1, side * 0.01), lineCap: .butt))
            return
        }

        var cursor = 0.0
        for (i, segment) in segments.enumerated() {
            let duration = Double(max(0, segment.duration))
            let span = duration / total * 360
            let start = -90 + cursor / total * 360
            cursor += duration

            let state: ArcState
            if !hasStarted || isFinished {
                state = isFinished ? .done : .upcoming
            } else if i < index {
                state = .done
            } else if i == index {
                state = .running
            } else {
                state = .upcoming
            }

            // Houd korte intervallen zichtbaar: nooit smaller dan 0,7°.
            let inset = span > gap * 2.2 ? gap / 2 : 0
            let a0 = start + inset
            let a1 = max(a0 + 0.7, start + span - inset)

            let width = lineWidth(for: segment.phase, state: state, breath: breath, side: side)

            switch state {
            case .done:
                stroke(&context, center: center, radius: radius, from: a0, to: a1,
                       color: pen.opacity(0.2), width: width)
            case .upcoming:
                stroke(&context, center: center, radius: radius, from: a0, to: a1,
                       color: track.opacity(0.26), width: width)
            case .running:
                let clamped = min(1, max(0, fraction))
                let tip = a0 + (a1 - a0) * clamped
                // Het nog te gaan deel van de lopende boog blijft zichtbaar,
                // het afgelegde deel is vol: zo reist de voortgang langs de ring.
                stroke(&context, center: center, radius: radius, from: a0, to: a1,
                       color: pen.opacity(0.34), width: width)
                if tip > a0 + 0.05 {
                    stroke(&context, center: center, radius: radius, from: a0, to: tip,
                           color: pen, width: width)
                }
                marker(&context, center: center, radius: radius, angle: tip, width: width)
            }
        }
    }

    private enum ArcState {
        case done, running, upcoming
    }

    private func lineWidth(for phase: Phase, state: ArcState, breath: Double, side: CGFloat) -> CGFloat {
        // Werk dik, rust dun, reset ertussenin — de dikte draagt het ritme.
        let base: CGFloat
        switch phase {
        case .work: base = 0.085
        case .rest: base = 0.032
        case .reset: base = 0.055
        }
        switch state {
        case .running:
            // Iets dikker dan de rest, plus de ademhaling.
            return side * base * weight * (1.16 + 0.07 * CGFloat(breath))
        case .done:
            return side * base * weight
        case .upcoming:
            // Haarlijnen, maar werk blijft dikker dan rust.
            let hair = max(1.2, side * 0.013) * weight
            return hair * (phase == .work ? 1 : phase == .reset ? 0.75 : 0.5)
        }
    }

    private func stroke(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat,
                        from a0: Double, to a1: Double, color: Color, width: CGFloat) {
        var path = Path()
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(a0), endAngle: .degrees(a1), clockwise: false)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .butt))
    }

    /// Het kopje op de kop van de voortgang — bot, nooit een tweede accent.
    private func marker(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat,
                        angle: Double, width: CGFloat) {
        let radians = angle * .pi / 180
        let inner = radius - width / 2
        let outer = radius + width / 2
        var path = Path()
        path.move(to: CGPoint(x: center.x + CGFloat(cos(radians)) * inner,
                              y: center.y + CGFloat(sin(radians)) * inner))
        path.addLine(to: CGPoint(x: center.x + CGFloat(cos(radians)) * outer,
                                 y: center.y + CGFloat(sin(radians)) * outer))
        context.stroke(path, with: .color(RondoTheme.bone),
                       style: StrokeStyle(lineWidth: max(1, width * 0.12), lineCap: .butt))
    }

    /// 0…1 en terug in twee seconden.
    private static func breath(at date: Date) -> Double {
        let t = date.timeIntervalSinceReferenceDate
        return 0.5 + 0.5 * sin(t * .pi)
    }
}

#if DEBUG
#Preview("Dial") {
    ZStack {
        RondoTheme.ink.ignoresSafeArea()
        RondoDial(segments: Workout().segments,
                  index: 5,
                  fraction: 0.45,
                  isRunning: false,
                  isFinished: false,
                  hasStarted: true,
                  accent: RondoTheme.accentParts(for: .rest))
            .padding(24)
    }
}
#endif
