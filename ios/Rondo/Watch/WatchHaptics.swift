#if os(watchOS)
import Foundation
import WatchKit

/// Op de arm telt de tik zwaarder dan het piepje: elke fasewissel en elke
/// seconde van het aftellen 3-2-1 is te voelen.
///
/// De haptiek staat los van de geluidsschakelaar — "geluid uit" op de iPhone
/// mag je arm niet stil zetten.
final class WatchHaptics: CueSink {
    var isEnabled: Bool {
        get { true }
        set { }
    }

    func beginSession() {}
    func endSession() {}

    func play(_ cue: Cue) {
        switch cue {
        case .tick:
            tap(.click)
        case .work:
            // Twee tikken: begin van werk moet opvallen tijdens inspanning.
            tap(.start)
            tap(.start, after: 0.22)
        case .rest:
            tap(.stop)
        case .reset:
            tap(.notification)
        case .done:
            tap(.success)
            tap(.success, after: 0.3)
        }
    }

    /// `WKInterfaceDevice` hoort op de hoofdthread aangeroepen te worden; de
    /// engine doet dat al, en `assumeIsolated` maakt dat ook voor de compiler
    /// waar zonder deze klasse zelf te isoleren.
    private func tap(_ type: WKHapticType, after delay: TimeInterval = 0) {
        guard delay > 0 else {
            MainActor.assumeIsolated {
                WKInterfaceDevice.current().play(type)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            MainActor.assumeIsolated {
                WKInterfaceDevice.current().play(type)
            }
        }
    }
}
#endif
