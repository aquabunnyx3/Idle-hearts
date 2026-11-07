import Foundation
import Observation
import SwiftUI

struct DialogueLine: Equatable {
    var speaker: CharacterID
    var text: String
    var mood: Mood
    var id = UUID()
}

struct TapResult {
    var amount: Double
    var isCritical: Bool
    var gainedDrama: Bool
}

struct OfflineReport: Identifiable {
    let id = UUID()
    let seconds: TimeInterval
    let loveNotes: Double
    let chemistry: Double
}

struct CompletionReport: Identifiable {
    let id = UUID()
    let dateIndex: Int
    let title: String
    let location: String
    let partners: (CharacterID, CharacterID)
    let loveNotes: Double
    let gems: Int
    let drama: Int
    let newRate: Double
    let line: DialogueLine
}

struct DramaReport: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let symbol: String
    let chemistry: Double
    let gems: Int
}

enum Booster: String, CaseIterable, Identifiable {
    case spark, rush, drama
    var id: String { rawValue }
}

@Observable
final class GameState {
    // MARK: Persistent state
    var chemistry: Double = 0
    var lifetimeChemistry: Double = 0
    var loveNotes: Double = 0
    var lifetimeLoveNotes: Double = 0
    var drama: Int = 0
    var heartGems: Int = 10
    var dateIndex: Int = 0
    var dateProgress: Double = 0
    var totalTaps: Int = 0
    var upgradeLevels: [UpgradeID: Int] = [:]
    var employeeLevels: [CharacterID: Int] = [:]
    var departmentLevels: [DepartmentID: Int] = [:]
    var affection: [CharacterID: Int] = [:]
    var journal: [JournalEntry] = []
    var sparkEndsAt: Date = .distantPast
    var sparkReadyAt: Date = .distantPast
    var rushEndsAt: Date = .distantPast
    var rushReadyAt: Date = .distantPast
    var soundEnabled = true { didSet { SoundManager.shared.enabled = soundEnabled } }
    var hapticsEnabled = true { didSet { Haptics.enabled = hapticsEnabled } }
    var hasSeenIntro = false
    var lastActive = Date()

    // MARK: Transient
    var now = Date()
    var dialogue: DialogueLine
    var welcomeBack: OfflineReport?
    var completion: CompletionReport?
    var dramaReport: DramaReport?
    var toast: String?
    /// Bumped whenever a character on the date should visibly react.
    var reactionCounter = 0
    var reactingCharacter: CharacterID?

    let isDemo: Bool
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var lastTick = Date()
    @ObservationIgnored private var saveAccumulator: TimeInterval = 0
    @ObservationIgnored private var idleLineAccumulator: TimeInterval = 0
    @ObservationIgnored private var tapsUntilLine = 12
    @ObservationIgnored private var spokenThresholds: Set<Int> = []

    // MARK: - Init / persistence

    init(demo: Bool = false) {
        isDemo = demo
        let first = Dates.template(for: 0)
        dialogue = DialogueLine(speaker: first.commentator,
                                text: "Welcome to Idle Hearts! Tap the big heart to build chemistry between our first couple.",
                                mood: .happy)
        if demo {
            seedDemo()
        } else if let save = SaveManager.load() {
            apply(save)
            computeOfflineEarnings(since: save.lastActive)
            dialogue = introLine()
        }
        Haptics.enabled = hapticsEnabled
        SoundManager.shared.enabled = soundEnabled
    }

    func apply(_ s: SaveData) {
        chemistry = s.chemistry
        lifetimeChemistry = s.lifetimeChemistry
        loveNotes = s.loveNotes
        lifetimeLoveNotes = s.lifetimeLoveNotes
        drama = s.drama
        heartGems = s.heartGems
        dateIndex = s.dateIndex
        dateProgress = s.dateProgress
        totalTaps = s.totalTaps
        upgradeLevels = Dictionary(uniqueKeysWithValues: s.upgradeLevels.compactMap { k, v in UpgradeID(rawValue: k).map { ($0, v) } })
        employeeLevels = Dictionary(uniqueKeysWithValues: s.employeeLevels.compactMap { k, v in CharacterID(rawValue: k).map { ($0, v) } })
        departmentLevels = Dictionary(uniqueKeysWithValues: s.departmentLevels.compactMap { k, v in DepartmentID(rawValue: k).map { ($0, v) } })
        affection = Dictionary(uniqueKeysWithValues: s.affection.compactMap { k, v in CharacterID(rawValue: k).map { ($0, v) } })
        journal = s.journal
        sparkEndsAt = s.sparkEndsAt
        sparkReadyAt = s.sparkReadyAt
        rushEndsAt = s.rushEndsAt
        rushReadyAt = s.rushReadyAt
        soundEnabled = s.soundEnabled
        hapticsEnabled = s.hapticsEnabled
        hasSeenIntro = s.hasSeenIntro
        lastActive = s.lastActive
    }

    func snapshot() -> SaveData {
        var s = SaveData()
        s.chemistry = chemistry
        s.lifetimeChemistry = lifetimeChemistry
        s.loveNotes = loveNotes
        s.lifetimeLoveNotes = lifetimeLoveNotes
        s.drama = drama
        s.heartGems = heartGems
        s.dateIndex = dateIndex
        s.dateProgress = dateProgress
        s.totalTaps = totalTaps
        s.upgradeLevels = Dictionary(uniqueKeysWithValues: upgradeLevels.map { ($0.key.rawValue, $0.value) })
        s.employeeLevels = Dictionary(uniqueKeysWithValues: employeeLevels.map { ($0.key.rawValue, $0.value) })
        s.departmentLevels = Dictionary(uniqueKeysWithValues: departmentLevels.map { ($0.key.rawValue, $0.value) })
        s.affection = Dictionary(uniqueKeysWithValues: affection.map { ($0.key.rawValue, $0.value) })
        s.journal = Array(journal.prefix(80))
        s.sparkEndsAt = sparkEndsAt
        s.sparkReadyAt = sparkReadyAt
        s.rushEndsAt = rushEndsAt
        s.rushReadyAt = rushReadyAt
        s.soundEnabled = soundEnabled
        s.hapticsEnabled = hapticsEnabled
        s.hasSeenIntro = hasSeenIntro
        s.lastActive = Date()
        return s
    }

    func save() {
        guard !isDemo else { return }
        lastActive = Date()
        SaveManager.save(snapshot())
    }

    func resetProgress() {
        SaveManager.erase()
        apply(SaveData())
        welcomeBack = nil; completion = nil; dramaReport = nil
        spokenThresholds = []
        dialogue = DialogueLine(speaker: currentTemplate.commentator,
                                text: "Fresh start! Tap the heart to get the sparks flying.", mood: .happy)
        save()
    }

    // MARK: - Lifecycle

    func start() {
        guard timer == nil else { return }
        lastTick = Date()
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func didEnterBackground() {
        stop()
        save()
    }

    func willEnterForeground() {
        guard timer == nil else { return }
        if !isDemo { computeOfflineEarnings(since: lastActive) }
        start()
    }

    private func tick() {
        let t = Date()
        let dt = min(t.timeIntervalSince(lastTick), 1.0)
        lastTick = t
        now = t

        let chem = chemistryPerSecond * dt
        // Demo mode (screenshots) keeps the date bar frozen so captures are stable.
        if chem > 0 { addChemistry(chem, advancesDate: !isDemo) }
        let notes = loveNotesPerSecond * dt
        if notes > 0 { loveNotes += notes; lifetimeLoveNotes += notes }

        idleLineAccumulator += dt
        if idleLineAccumulator > 14, completion == nil {
            idleLineAccumulator = 0
            say(banterLine())
        }

        saveAccumulator += dt
        if saveAccumulator > 10 {
            saveAccumulator = 0
            save()
        }
    }

    // MARK: - Derived values

    func level(_ u: UpgradeID) -> Int { upgradeLevels[u] ?? 0 }
    func level(_ d: DepartmentID) -> Int { departmentLevels[d] ?? 0 }
    func level(_ c: CharacterID) -> Int { employeeLevels[c] ?? 0 }
    func affectionLevel(_ c: CharacterID) -> Int { affection[c] ?? 1 }

    var currentTemplate: DateTemplate { Dates.template(for: dateIndex) }
    var dateRequirement: Double { Self.requirement(for: dateIndex) }
    var dateFraction: Double { min(dateProgress / dateRequirement, 1) }
    var isDateReady: Bool { dateProgress >= dateRequirement }

    static func requirement(for index: Int) -> Double { 100 * pow(3.2, Double(index)) }
    static func coupleRate(for index: Int) -> Double { 0.4 * pow(2.4, Double(index)) }

    func loveNotesReward(for index: Int) -> Double {
        50 * pow(3.0, Double(index)) * (1 + 0.15 * Double(level(.clientServices)))
    }
    func gemsReward(for index: Int) -> Int { 2 + index / 3 }

    var sparkActive: Bool { now < sparkEndsAt }
    var rushActive: Bool { now < rushEndsAt }

    var baseTap: Double {
        let l = Double(level(.tapPower))
        return (1 + l) * pow(2, Double(level(.tapPower) / 10))
    }
    var tapMultiplier: Double { (sparkActive ? 2 : 1) * (rushActive ? 5 : 1) }
    var tapValue: Double { (baseTap + chemistryPerSecond * 0.03) * tapMultiplier }
    var critChance: Double { min(0.05 + 0.01 * Double(level(.critChance)), 0.30) }
    let critMultiplier = 10.0

    func employeeRate(_ c: CharacterID, level l: Int? = nil) -> Double {
        let lvl = l ?? level(c)
        guard lvl > 0 else { return 0 }
        return c.info.baseRate * Double(lvl) * pow(2, Double(lvl / 10))
    }

    var rawChemistryPerSecond: Double { CharacterID.allCases.reduce(0) { $0 + employeeRate($1) } }
    var chemistryPerSecond: Double { rawChemistryPerSecond * (1 + 0.10 * Double(level(.marketing))) }

    /// Each completed date leaves a happy couple who send Love Notes forever.
    var couplesRate: Double {
        guard dateIndex > 0 else { return 0 }
        return 0.4 * (pow(2.4, Double(dateIndex)) - 1) / 1.4
    }
    var loveNotesPerSecond: Double {
        couplesRate * (1 + 0.25 * Double(level(.passiveIncome))) * (1 + 0.10 * Double(level(.operations)))
    }
    var offlineCapHours: Double { 2 + Double(level(.offlineEarnings)) }

    // MARK: - Costs

    func cost(_ u: UpgradeID) -> Double { u.baseCost * pow(u.growth, Double(level(u))) }
    func cost(_ d: DepartmentID) -> Double { d.baseCost * pow(1.8, Double(level(d))) }
    func hireCost(_ c: CharacterID) -> Double { c.info.hireCost * pow(1.15, Double(level(c))) }

    func isMaxed(_ u: UpgradeID) -> Bool { u.maxLevel.map { level(u) >= $0 } ?? false }

    func balance(_ c: Currency) -> Double {
        switch c {
        case .chemistry: return chemistry
        case .loveNotes: return loveNotes
        case .gems: return Double(heartGems)
        }
    }

    func canAfford(_ amount: Double, _ c: Currency) -> Bool { balance(c) >= amount }

    private func spend(_ amount: Double, _ c: Currency) -> Bool {
        guard canAfford(amount, c) else {
            Haptics.error()
            return false
        }
        switch c {
        case .chemistry: chemistry -= amount
        case .loveNotes: loveNotes -= amount
        case .gems: heartGems -= Int(amount)
        }
        return true
    }

    // MARK: - Actions

    @discardableResult
    func tap() -> TapResult {
        totalTaps += 1
        idleLineAccumulator = 0
        let crit = Double.random(in: 0..<1) < critChance
        let amount = tapValue * (crit ? critMultiplier : 1)
        addChemistry(amount)
        var gotDrama = false
        if Double.random(in: 0..<1) < 0.015 {
            drama += 1
            gotDrama = true
        }

        if crit {
            Haptics.heavy()
            SoundManager.shared.play(.crit)
            if Bool.random() { say(critLine(), react: true) }
        } else {
            Haptics.tap()
            SoundManager.shared.play(.tap)
        }

        tapsUntilLine -= 1
        if tapsUntilLine <= 0 {
            tapsUntilLine = Int.random(in: 16...28)
            say(banterLine(), react: true)
        }
        if !hasSeenIntro && totalTaps >= 5 { hasSeenIntro = true }
        return TapResult(amount: amount, isCritical: crit, gainedDrama: gotDrama)
    }

    private func addChemistry(_ amount: Double, advancesDate: Bool = true) {
        chemistry += amount
        lifetimeChemistry += amount
        guard completion == nil, advancesDate else { return }
        let before = dateFraction
        dateProgress = min(dateProgress + amount, dateRequirement)
        let after = dateFraction
        for threshold in [50] where before < Double(threshold) / 100 && after >= Double(threshold) / 100 {
            if !spokenThresholds.contains(threshold) {
                spokenThresholds.insert(threshold)
                let c = currentTemplate.commentator.info
                say(DialogueLine(speaker: c.id, text: c.progressLines.randomElement()!, mood: .happy), react: true)
            }
        }
        if isDateReady { completeDate() }
    }

    private func completeDate() {
        guard completion == nil else { return }
        let index = dateIndex
        let template = currentTemplate
        let notes = loveNotesReward(for: index)
        let gems = gemsReward(for: index)
        let dramaGain = 2
        let commentator = template.commentator.info
        let line = DialogueLine(speaker: commentator.id, text: commentator.completeLines.randomElement()!, mood: .happy)
        completion = CompletionReport(
            dateIndex: index, title: Dates.title(for: index), location: template.location,
            partners: template.partners, loveNotes: notes, gems: gems, drama: dramaGain,
            newRate: Self.coupleRate(for: index) * (1 + 0.25 * Double(level(.passiveIncome))) * (1 + 0.10 * Double(level(.operations))),
            line: line)
        Haptics.success()
        SoundManager.shared.play(.complete)
    }

    /// Called from the "Next Date" button on the completion card.
    func collectCompletion() {
        guard let report = completion else { return }
        loveNotes += report.loveNotes
        lifetimeLoveNotes += report.loveNotes
        heartGems += report.gems
        drama += report.drama
        var leveled: [CharacterID] = []
        for c in [report.partners.0, report.partners.1] {
            affection[c] = affectionLevel(c) + 1
            leveled.append(c)
        }
        journal.insert(JournalEntry(kind: .date, title: report.title,
                                    detail: "\(report.partners.0.info.firstName) & \(report.partners.1.info.firstName) hit it off at \(report.location).",
                                    timestamp: Date(), characters: [report.partners.0, report.partners.1]), at: 0)
        dateIndex += 1
        dateProgress = 0
        spokenThresholds = []
        completion = nil
        let next = currentTemplate
        say(DialogueLine(speaker: next.commentator,
                         text: "Next up: \(Dates.title(for: dateIndex)) at \(next.location). \(next.partners.0.info.firstName) and \(next.partners.1.info.firstName)… this should be interesting.",
                         mood: .happy))
        toast = "\(leveled.map { $0.info.firstName }.joined(separator: " & ")) grew closer · new story unlocked"
        SoundManager.shared.play(.purchase)
        save()
    }

    func buy(_ u: UpgradeID) {
        guard !isMaxed(u), spend(cost(u), u.currency) else { return }
        upgradeLevels[u] = level(u) + 1
        purchased()
    }

    func buy(_ d: DepartmentID) {
        guard spend(cost(d), .loveNotes) else { return }
        departmentLevels[d] = level(d) + 1
        purchased()
    }

    func hire(_ c: CharacterID) {
        guard spend(hireCost(c), .loveNotes) else { return }
        let first = level(c) == 0
        employeeLevels[c] = level(c) + 1
        purchased()
        if first {
            say(DialogueLine(speaker: c, text: hireLine(c), mood: .happy))
            journal.insert(JournalEntry(kind: .story, title: "\(c.info.firstName) joined the agency",
                                        detail: "\(c.info.name) is now your \(c.info.agencyTitle).",
                                        timestamp: Date(), characters: [c]), at: 0)
        }
    }

    private func purchased() {
        Haptics.medium()
        SoundManager.shared.play(.purchase)
    }

    // MARK: Boosters

    func readyAt(_ b: Booster) -> Date {
        switch b {
        case .spark: return sparkReadyAt
        case .rush: return rushReadyAt
        case .drama: return .distantPast
        }
    }
    func endsAt(_ b: Booster) -> Date {
        switch b {
        case .spark: return sparkEndsAt
        case .rush: return rushEndsAt
        case .drama: return .distantPast
        }
    }
    func isActive(_ b: Booster) -> Bool { now < endsAt(b) }
    func isReady(_ b: Booster) -> Bool {
        b == .drama ? drama >= dramaCost : now >= readyAt(b)
    }
    let dramaCost = 3
    let rechargeGemCost = 5

    func activate(_ b: Booster) {
        let t = Date()
        switch b {
        case .spark:
            guard t >= sparkReadyAt else { return }
            sparkEndsAt = t.addingTimeInterval(30)
            sparkReadyAt = t.addingTimeInterval(90)
            say(DialogueLine(speaker: .riley, text: "Spark mode! Every tap counts double for 30 seconds.", mood: .happy), react: false)
        case .rush:
            guard t >= rushReadyAt else { return }
            rushEndsAt = t.addingTimeInterval(10)
            rushReadyAt = t.addingTimeInterval(180)
            say(DialogueLine(speaker: .lola, text: "CHEMISTRY RUSH! Tap like your love life depends on it!", mood: .happy), react: false)
        case .drama:
            causeDrama()
            return
        }
        now = t
        Haptics.medium()
        SoundManager.shared.play(.boost)
    }

    func recharge(_ b: Booster) {
        guard b != .drama, !isReady(b), spend(Double(rechargeGemCost), .gems) else { return }
        switch b {
        case .spark: sparkReadyAt = .distantPast
        case .rush: rushReadyAt = .distantPast
        case .drama: break
        }
        Haptics.medium()
    }

    private func causeDrama() {
        guard drama >= dramaCost, completion == nil else {
            Haptics.error()
            return
        }
        drama -= dramaCost
        let template = currentTemplate
        let event = Drama.events.randomElement()!
        let text = event.text
            .replacingOccurrences(of: "{A}", with: template.partners.0.info.firstName)
            .replacingOccurrences(of: "{B}", with: template.partners.1.info.firstName)
        let reward = max(dateRequirement * 0.18, chemistryPerSecond * 60, tapValue * 30)
        let gems = Double.random(in: 0..<1) < 0.35 ? 1 : 0
        heartGems += gems
        dramaReport = DramaReport(title: event.title, text: text, symbol: event.symbol, chemistry: reward, gems: gems)
        journal.insert(JournalEntry(kind: .drama, title: event.title, detail: text, timestamp: Date(),
                                    characters: [template.partners.0, template.partners.1]), at: 0)
        Haptics.heavy()
        SoundManager.shared.play(.drama)
    }

    func collectDrama() {
        guard let r = dramaReport else { return }
        dramaReport = nil
        addChemistry(r.chemistry)
        reactionCounter += 1
        reactingCharacter = currentTemplate.partners.0
    }

    // MARK: Offline

    private func computeOfflineEarnings(since date: Date) {
        let elapsed = Date().timeIntervalSince(date)
        lastActive = Date()
        guard elapsed > 60 else { return }
        let capped = min(elapsed, offlineCapHours * 3600)
        let notes = loveNotesPerSecond * capped
        let chem = chemistryPerSecond * capped * 0.5
        guard notes + chem >= 1 else { return }
        welcomeBack = OfflineReport(seconds: capped, loveNotes: notes, chemistry: chem)
    }

    func collectOffline(doubled: Bool) {
        guard let r = welcomeBack else { return }
        if doubled {
            guard spend(10, .gems) else { return }
        }
        let m: Double = doubled ? 2 : 1
        loveNotes += r.loveNotes * m
        lifetimeLoveNotes += r.loveNotes * m
        welcomeBack = nil
        addChemistry(r.chemistry * m)
        Haptics.success()
        SoundManager.shared.play(.purchase)
        save()
    }

    // MARK: Dialogue

    func say(_ line: DialogueLine, react: Bool = false) {
        dialogue = line
        if react {
            reactingCharacter = line.speaker
            reactionCounter += 1
        }
    }

    private func banterLine() -> DialogueLine {
        let t = currentTemplate
        let speaker = Int.random(in: 0..<4) == 0 ? (Bool.random() ? t.partners.0 : t.partners.1) : t.commentator
        let pool = speaker.info.banter
        var text = pool.randomElement()!
        if text == dialogue.text, let alt = pool.randomElement() { text = alt }
        return DialogueLine(speaker: speaker, text: text, mood: Bool.random() ? .neutral : .happy)
    }

    private func critLine() -> DialogueLine {
        let c = currentTemplate.commentator.info
        return DialogueLine(speaker: c.id, text: c.critLines.randomElement()!, mood: .happy)
    }

    private func introLine() -> DialogueLine {
        let c = currentTemplate.commentator.info
        return DialogueLine(speaker: c.id, text: "Welcome back! \(Dates.title(for: dateIndex)) is still going. Let's get those sparks flying.", mood: .happy)
    }

    private func hireLine(_ c: CharacterID) -> String {
        switch c {
        case .jamie: return "I'm here! Only a little late. I brought donuts as an apology."
        case .riley: return "Your clients are in good hands. Mine, specifically."
        case .lola: return "Officially on payroll! I'm still going to gossip, just professionally now."
        case .adrian: return "Partners again. Try not to make it weird."
        case .vincent: return "I don't usually work for anyone. Consider yourself the exception."
        }
    }

    // MARK: - Demo data (screenshots / previews)

    private func seedDemo() {
        chemistry = 12_480
        lifetimeChemistry = 980_000
        loveNotes = 3_204
        lifetimeLoveNotes = 120_000
        drama = 18
        heartGems = 47
        dateIndex = 0
        dateProgress = Self.requirement(for: 0) * 0.62
        employeeLevels = [.jamie: 8, .riley: 6, .lola: 3, .adrian: 1]
        upgradeLevels = [.tapPower: 6, .critChance: 3, .passiveIncome: 2, .offlineEarnings: 3]
        departmentLevels = [.marketing: 2, .operations: 1, .clientServices: 1]
        affection = [.lola: 4, .adrian: 3, .riley: 2, .jamie: 3, .vincent: 2]
        totalTaps = 4_820
        hasSeenIntro = true
        let t = Date()
        journal = [
            JournalEntry(kind: .drama, title: "Sudden Rain", detail: "It started pouring. Riley offered Jamie a jacket. Cinematic.", timestamp: t.addingTimeInterval(-600), characters: [.riley, .jamie]),
            JournalEntry(kind: .story, title: "Lola joined the agency", detail: "Lola Monroe is now your Social Strategist.", timestamp: t.addingTimeInterval(-3600), characters: [.lola]),
            JournalEntry(kind: .story, title: "Riley joined the agency", detail: "Riley Hart is now your Dating Coach.", timestamp: t.addingTimeInterval(-7200), characters: [.riley]),
        ]
        dialogue = DialogueLine(speaker: .lola, text: "Okay… they're either flirting or arguing. Honestly, both work.", mood: .happy)
    }

    func applyDemoOverlay(_ name: String) {
        switch name {
        case "welcome":
            welcomeBack = OfflineReport(seconds: 8 * 3600, loveNotes: 28_800, chemistry: 4_200)
        case "complete":
            dateProgress = dateRequirement
            completeDate()
        case "drama":
            causeDrama()
        default: break
        }
    }
}
