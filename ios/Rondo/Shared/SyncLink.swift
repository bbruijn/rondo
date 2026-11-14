import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// Wat er over de lucht gaat tussen telefoon en Watch.
enum SyncPayload {
    /// Instellingen en de geluidsschakelaar. Laatste stand wint.
    case settings(workout: Workout, soundOn: Bool)
    /// Start of hervat op dit segment, met de resttijd op het moment van
    /// verzenden; de ontvanger trekt de reistijd eraf.
    case run(index: Int, remaining: Double, sentAt: Date)
    case pause(index: Int, remaining: Double)
    case reset
    case finished

    /// Commando's zijn alleen zinnig als ze meteen aankomen; instellingen
    /// mogen in de wachtrij.
    var isCommand: Bool {
        switch self {
        case .settings: return false
        case .run, .pause, .reset, .finished: return true
        }
    }
}

/// `WatchConnectivity`, met opzet onopvallend: lukt het niet, dan gebeurt er
/// niets en blijft elke app los bruikbaar. Er wordt nooit op de tegenhanger
/// gewacht en een mislukte verzending is geen fout voor de gebruiker.
final class SyncLink: NSObject, ObservableObject {
    static let shared = SyncLink()

    /// Wordt altijd op de hoofdthread aangeroepen.
    var onReceive: (@MainActor (SyncPayload) -> Void)?

    @Published private(set) var isReachable = false
    @Published private(set) var isAvailable = false

    override init() {
        super.init()
    }

    func activate() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        #endif
    }

    func send(_ payload: SyncPayload) {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let message = Self.encode(payload)

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: { _ in
                // Stil: de andere kant is niet nodig om zelf te kunnen trainen.
            })
            return
        }
        guard !payload.isCommand else { return }
        // Niet bereikbaar: alleen de laatste instellingen achterlaten, zodat
        // de tegenhanger bij het volgende opstarten bij is.
        try? session.updateApplicationContext(message)
        #endif
    }

    // MARK: - Codering

    private static let kindKey = "kind"
    private static let workoutKey = "workout"
    private static let soundKey = "sound"
    private static let indexKey = "index"
    private static let remainingKey = "remaining"
    private static let sentAtKey = "sentAt"

    static func encode(_ payload: SyncPayload) -> [String: Any] {
        switch payload {
        case let .settings(workout, soundOn):
            var dict: [String: Any] = [kindKey: "settings", soundKey: soundOn]
            if let data = try? JSONEncoder().encode(workout) {
                dict[workoutKey] = data
            }
            return dict
        case let .run(index, remaining, sentAt):
            return [kindKey: "run", indexKey: index, remainingKey: remaining,
                    sentAtKey: sentAt.timeIntervalSince1970]
        case let .pause(index, remaining):
            return [kindKey: "pause", indexKey: index, remainingKey: remaining]
        case .reset:
            return [kindKey: "reset"]
        case .finished:
            return [kindKey: "finished"]
        }
    }

    static func decode(_ dict: [String: Any]) -> SyncPayload? {
        guard let kind = dict[kindKey] as? String else { return nil }
        switch kind {
        case "settings":
            let sound = dict[soundKey] as? Bool ?? true
            guard let data = dict[workoutKey] as? Data,
                  let workout = try? JSONDecoder().decode(Workout.self, from: data) else { return nil }
            return .settings(workout: workout, soundOn: sound)
        case "run":
            guard let index = dict[indexKey] as? Int,
                  let remaining = dict[remainingKey] as? Double else { return nil }
            let sentAt = (dict[sentAtKey] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
            return .run(index: index, remaining: remaining, sentAt: sentAt)
        case "pause":
            guard let index = dict[indexKey] as? Int,
                  let remaining = dict[remainingKey] as? Double else { return nil }
            return .pause(index: index, remaining: remaining)
        case "reset":
            return .reset
        case "finished":
            return .finished
        default:
            return nil
        }
    }

    // MARK: - Aflevering op de hoofdthread

    private func deliver(_ dict: [String: Any]) {
        guard let payload = Self.decode(dict) else { return }
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                self.onReceive?(payload)
            }
        }
    }

    private func refreshState() {
        #if canImport(WatchConnectivity)
        let session = WCSession.default
        let reachable = session.isReachable
        #if os(iOS)
        let available = session.isPaired && session.isWatchAppInstalled
        #else
        let available = session.isCompanionAppInstalled
        #endif
        DispatchQueue.main.async {
            if self.isReachable != reachable { self.isReachable = reachable }
            if self.isAvailable != available { self.isAvailable = available }
        }
        #endif
    }
}

#if canImport(WatchConnectivity)
extension SyncLink: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        refreshState()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        refreshState()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        deliver(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        deliver(message)
        replyHandler([:])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        deliver(userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        deliver(applicationContext)
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        refreshState()
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Na een wisseling van Watch moet de sessie opnieuw worden geactiveerd.
        WCSession.default.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        refreshState()
    }
    #endif
}
#endif
