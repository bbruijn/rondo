#if os(watchOS)
import Combine
import Foundation
import WatchKit

/// Houdt de app draaiend als het scherm dimt.
///
/// `WKExtendedRuntimeSession` is het enige wat op watchOS een timer laat
/// doorlopen zonder een `HKWorkoutSession` (en dus zonder HealthKit-rechten te
/// vragen voor iets wat geen workout-registratie is). De sessie vereist in de
/// Info.plist `WKBackgroundModes` met `mindfulness`; zonder die sleutel start
/// hij niet. Lukt het starten niet, dan loopt de timer gewoon door zolang het
/// scherm aan staat — de app blijft bruikbaar, alleen minder betrouwbaar met
/// de arm omlaag.
final class ExtendedRuntime: NSObject, ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var lastProblem: String?

    private var session: WKExtendedRuntimeSession?

    func start() {
        MainActor.assumeIsolated {
            if let existing = session, existing.state == .running || existing.state == .scheduled {
                return
            }
            let fresh = WKExtendedRuntimeSession()
            fresh.delegate = self
            session = fresh
            fresh.start()
        }
    }

    func stop() {
        MainActor.assumeIsolated {
            if let existing = session, existing.state == .running {
                existing.invalidate()
            }
            session = nil
            isActive = false
        }
    }
}

extension ExtendedRuntime: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        isActive = true
        lastProblem = nil
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // Verloopt na ongeveer een uur; de klok zelf rekent met echte tijd,
        // dus hij loopt niet weg, hij wordt alleen minder vaak bijgewerkt.
        isActive = false
    }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: Error?) {
        isActive = false
        session = nil
        if let error {
            lastProblem = error.localizedDescription
        }
    }
}
#endif
