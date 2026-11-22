import Combine
import Foundation
#if os(iOS)
import UIKit
#endif

/// De klok van de training: houdt bij welk segment loopt, hoeveel er nog over
/// is en wanneer welk signaal klinkt of tikt.
///
/// Overgenomen uit V1, met twee toevoegingen: de signalen gaan via `CueSink`
/// (piepjes op de iPhone, haptiek op de Watch) en start/pauze/instellingen
/// gaan via `SyncLink` over en weer.
///
/// De kern blijft: **tijd komt uit absolute `Date`-deadlines, nooit uit
/// opgetelde tikken.** Loopt de app achter — onderbreking, scherm uit — dan
/// haalt hij de gemiste segmenten in één keer in en slaat de gemiste signalen
/// over (meer dan 1,5 s achterstand).
@MainActor
final class WorkoutEngine: ObservableObject {
    @Published var workout: Workout {
        didSet {
            guard workout != oldValue else { return }
            Storage.save(workout)
            rewind()
            sendSettings()
        }
    }

    @Published private(set) var saved: [SavedWorkout]
    @Published private(set) var isRunning = false
    @Published private(set) var isFinished = false
    @Published private(set) var hasStarted = false
    /// Hele seconden, voor het cijfer.
    @Published private(set) var remaining = 0
    @Published private(set) var elapsed = 0
    @Published private(set) var index = 0
    /// Voortgang binnen het lopende segment, 0…1 — voor de ring.
    @Published private(set) var segmentFraction: Double = 0

    @Published var isSoundOn: Bool {
        didSet {
            guard isSoundOn != oldValue else { return }
            Storage.saveSound(isSoundOn)
            for sink in sinks { sink.isEnabled = isSoundOn }
            sendSettings()
        }
    }

    private var sinks: [CueSink] = []
    private var segments: [Segment] = []
    private var deadline: Date?
    private var remainingExact: Double = 0
    private var elapsedBefore = 0
    private var lastCountdownCue: Int?
    private var timer: DispatchSourceTimer?
    private var link: SyncLink?
    private var isApplyingRemote = false

    init() {
        let stored = Storage.loadWorkout()
        workout = stored
        saved = Storage.loadSaved()
        isSoundOn = Storage.loadSound()
        segments = stored.segments
        remaining = segments.first?.duration ?? 0
        remainingExact = Double(remaining)
    }

    // MARK: - Opbouw

    /// Voegt een afnemer van de signalen toe (iPhone: `AudioCoach`,
    /// Watch: `WatchHaptics`).
    func add(sink: CueSink) {
        sink.isEnabled = isSoundOn
        sinks.append(sink)
    }

    /// Koppelt de tegenhanger. Mag ontbreken: zonder koppeling werkt de app
    /// precies zo, alleen alleen.
    func connect(_ link: SyncLink) {
        self.link = link
        link.onReceive = { [weak self] payload in
            self?.apply(payload)
        }
        link.activate()
    }

    // MARK: - Afgeleide waarden voor het scherm

    var current: Segment? { segments.indices.contains(index) ? segments[index] : nil }
    var program: [Segment] { segments }
    var total: Int { workout.totalDuration }
    var totalRemaining: Int { max(0, total - elapsed) }
    var progress: Double { total > 0 ? min(1, Double(elapsed) / Double(total)) : 0 }

    var phase: Phase? { hasStarted && !isFinished ? current?.phase : nil }

    /// Het ene label onder het cijfer.
    var headline: String {
        if isFinished { return String(localized: "Done") }
        guard hasStarted else { return "Rondo" }
        return current?.phase.label ?? "Rondo"
    }

    var shortHeadline: String {
        if isFinished { return String(localized: "Done") }
        guard hasStarted else { return "Rondo" }
        return current?.phase.shortLabel ?? "Rondo"
    }

    /// Vóór de start en na afloop staat het totaal er; onderweg de resttijd
    /// van het lopende interval.
    var clock: String { Workout.clock(hasStarted && !isFinished ? remaining : total) }

    /// De regel onder het cijfer, zoals in de webversie.
    var subtitle: String {
        let count = workout.rounds
        let rounds = count == 1 ? String(localized: "1 round") : String(localized: "\(count) rounds")
        if isFinished { return String(localized: "\(rounds) completed") }
        guard hasStarted else {
            return workout.exercises > 1 ? "\(rounds) × \(workout.exercises)" : rounds
        }
        let round = current?.round ?? 1
        let left = Workout.clock(totalRemaining)
        return String(localized: "Round \(round)/\(count) · \(left) left")
    }

    // MARK: - Bediening

    func toggle() { isRunning ? pause() : start() }

    func start() { beginRun(announce: true) }

    func pause() {
        guard isRunning else { return }
        haltClock()
        send(.pause(index: index, remaining: remainingExact))
    }

    /// Klok stil, sessie los, scherm weer vrij. Mag altijd aangeroepen worden.
    private func haltClock() {
        stopTimer()
        if isRunning { isRunning = false }
        deadline = nil
        releaseSinks()
        setWakeLock(false)
    }

    /// Terug naar het begin, op verzoek van de gebruiker.
    func reset() {
        rewind()
        send(.reset)
    }

    // MARK: - Opgeslagen trainingen

    func saveCurrent() {
        let now = Date()
        let entry = SavedWorkout(name: SavedWorkout.displayName(for: now), workout: workout, savedAt: now)
        saved = ([entry] + saved.filter { $0.workout != workout }).prefix(12).map { $0 }
        Storage.saveSaved(saved)
    }

    func load(_ entry: SavedWorkout) { workout = entry.workout }

    func delete(_ entry: SavedWorkout) {
        saved.removeAll { $0.id == entry.id }
        Storage.saveSaved(saved)
    }

    // MARK: - Synchronisatie

    private func sendSettings() {
        send(.settings(workout: workout, soundOn: isSoundOn))
    }

    private func send(_ payload: SyncPayload) {
        guard !isApplyingRemote else { return }
        link?.send(payload)
    }

    /// Een bericht van de tegenhanger. Stuurt zelf niets terug, anders kaatsen
    /// de twee apps elkaars commando's heen en weer.
    func apply(_ payload: SyncPayload) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        switch payload {
        case let .settings(remote, soundOn):
            if remote != workout { workout = remote }
            if soundOn != isSoundOn { isSoundOn = soundOn }
        case let .run(remoteIndex, remainingThere, sentAt):
            let travel = max(0, min(5, Date().timeIntervalSince(sentAt)))
            seek(to: remoteIndex, remaining: remainingThere - travel)
            beginRun(announce: false)
        case let .pause(remoteIndex, remainingThere):
            seek(to: remoteIndex, remaining: remainingThere)
        case .reset:
            rewind()
        case .finished:
            finish(quiet: true)
        }
    }

    /// Zet de klok op een bepaald segment. Buiten bereik betekent: klaar.
    private func seek(to newIndex: Int, remaining newRemaining: Double) {
        guard !segments.isEmpty else { return }
        guard segments.indices.contains(newIndex) else {
            finish(quiet: true)
            return
        }
        haltClock()
        index = newIndex
        hasStarted = true
        isFinished = false
        elapsedBefore = segments.prefix(newIndex).reduce(0) { $0 + $1.duration }
        let duration = Double(segments[newIndex].duration)
        remainingExact = min(duration, max(0.5, newRemaining))
        remaining = Int(ceil(remainingExact))
        lastCountdownCue = nil
        update(left: remainingExact)
    }

    // MARK: - Klok

    private func beginRun(announce: Bool) {
        if isFinished { rewind() }
        guard !segments.isEmpty, !isRunning else { return }

        let fresh = !hasStarted
        isRunning = true
        hasStarted = true
        lastCountdownCue = nil
        if remainingExact <= 0 { remainingExact = Double(current?.duration ?? 0) }
        deadline = Date().addingTimeInterval(remainingExact)

        for sink in sinks { sink.beginSession() }
        if fresh, let phase = current?.phase { play(Cue.forPhase(phase)) }

        setWakeLock(true)
        startTimer()
        if announce {
            send(.run(index: index, remaining: remainingExact, sentAt: Date()))
        }
    }

    /// Terug naar het begin zonder iets te verzenden.
    private func rewind() {
        haltClock()
        isFinished = false
        hasStarted = false

        segments = workout.segments
        index = 0
        elapsedBefore = 0
        elapsed = 0
        remaining = segments.first?.duration ?? 0
        remainingExact = Double(remaining)
        segmentFraction = 0
        lastCountdownCue = nil
    }

    private func startTimer() {
        stopTimer()
        let source = DispatchSource.makeTimerSource(queue: .main)
        source.schedule(deadline: .now(), repeating: .milliseconds(50), leeway: .milliseconds(10))
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.tick() }
        }
        source.resume()
        timer = source
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        guard isRunning, let target = deadline else { return }
        var left = target.timeIntervalSinceNow

        // Aftellen: 3-2-1 vlak voor het einde van een segment.
        let whole = Int(ceil(left))
        if whole > 0, whole <= 3, lastCountdownCue != whole {
            lastCountdownCue = whole
            play(.tick)
        }

        while left <= 0 {
            // Was de app onderbroken, dan slaan we de gemiste signalen over.
            let quiet = left < -1.5
            guard advance(overshoot: -left, quiet: quiet) else { return }
            guard let next = deadline else { return }
            left = next.timeIntervalSinceNow
        }

        update(left: left)
    }

    private func update(left: Double) {
        let clamped = max(0, left)
        remainingExact = clamped
        let whole = Int(ceil(clamped))
        if whole != remaining { remaining = whole }

        guard let segment = current else { return }
        let done = Double(segment.duration) - clamped
        let fraction = segment.duration > 0 ? min(1, max(0, done / Double(segment.duration))) : 1
        // Afgerond op 1/300, zodat de ring vloeiend reist zonder het scherm
        // twintig keer per seconde te hertekenen.
        let quantised = (fraction * 300).rounded() / 300
        if quantised != segmentFraction { segmentFraction = quantised }

        let newElapsed = elapsedBefore + (segment.duration - whole)
        if newElapsed != elapsed { elapsed = max(0, min(total, newElapsed)) }
    }

    /// Zet door naar het volgende segment. Geeft `false` als de training klaar is.
    @discardableResult
    private func advance(overshoot: Double, quiet: Bool) -> Bool {
        guard let finished = current else { return false }
        elapsedBefore += finished.duration
        index += 1
        lastCountdownCue = nil

        guard let next = current else {
            finish(quiet: quiet)
            return false
        }

        deadline = Date().addingTimeInterval(Double(next.duration) - overshoot)
        remainingExact = Double(next.duration) - overshoot
        remaining = next.duration
        segmentFraction = 0
        if !quiet { play(Cue.forPhase(next.phase)) }
        return true
    }

    private func finish(quiet: Bool) {
        stopTimer()
        isRunning = false
        deadline = nil
        isFinished = true
        hasStarted = true
        index = max(0, segments.count - 1)
        remaining = 0
        remainingExact = 0
        elapsed = total
        segmentFraction = 1
        setWakeLock(false)

        if quiet {
            releaseSinks()
        } else {
            play(.done)
            // De slotklank moet uitklinken voordat de audiosessie dichtgaat;
            // meteen afsluiten kapt de laatste toon af.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                MainActor.assumeIsolated {
                    guard let self, !self.isRunning else { return }
                    self.releaseSinks()
                }
            }
        }
        send(.finished)
    }

    private func releaseSinks() {
        for sink in sinks { sink.endSession() }
    }

    private func play(_ cue: Cue) {
        for sink in sinks { sink.play(cue) }
    }

    /// Scherm aan houden terwijl er getraind wordt. Op de Watch doet
    /// `WKExtendedRuntimeSession` dit werk, zie `ExtendedRuntime`.
    private func setWakeLock(_ on: Bool) {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = on
        #endif
    }
}
