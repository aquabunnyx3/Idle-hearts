import AVFoundation
import UIKit

// MARK: - Haptics

enum Haptics {
    static var enabled = true
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
    private static let notify = UINotificationFeedbackGenerator()
    private static var lastTap = Date.distantPast

    static func tap() {
        guard enabled else { return }
        // Rapid tapping shouldn't turn into a constant buzz.
        let t = Date()
        guard t.timeIntervalSince(lastTap) > 0.05 else { return }
        lastTap = t
        soft.impactOccurred(intensity: 0.7)
    }
    static func medium() { if enabled { mediumGen.impactOccurred() } }
    static func heavy() { if enabled { heavyGen.impactOccurred() } }
    static func select() { if enabled { light.impactOccurred(intensity: 0.5) } }
    static func success() { if enabled { notify.notificationOccurred(.success) } }
    static func error() { if enabled { notify.notificationOccurred(.warning) } }
}

// MARK: - Sound

/// Tiny synthesiser so the game ships with crisp, royalty-free sound effects
/// and no audio files. Uses the ambient session category so it respects the
/// silent switch and mixes with the player's own music.
final class SoundManager {
    static let shared = SoundManager()

    enum Effect: CaseIterable { case tap, crit, complete, purchase, boost, drama }

    var enabled = true
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private var buffers: [Effect: [AVAudioPCMBuffer]] = [:]
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var started = false

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        for _ in 0..<6 {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: engine.mainMixerNode, format: format)
            players.append(p)
        }
        engine.mainMixerNode.outputVolume = 0.55
        buildBuffers()
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] _ in
            self?.started = false
        }
    }

    private func ensureStarted() -> Bool {
        if started && engine.isRunning { return true }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            players.forEach { $0.play() }
            started = true
        } catch {
            started = false
        }
        return started
    }

    func play(_ effect: Effect) {
        guard enabled, let variants = buffers[effect], let buffer = variants.randomElement(), ensureStarted() else { return }
        let p = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        p.scheduleBuffer(buffer, at: nil, options: [.interrupts])
        if !p.isPlaying { p.play() }
    }

    // MARK: Synthesis

    private struct Note { var freq: Double; var start: Double; var length: Double; var gain: Double }

    private func buildBuffers() {
        // A soft "bloop": slightly detuned so rapid taps don't sound robotic.
        buffers[.tap] = [0.0, 2.0, 4.0, 5.0, 7.0].map { semis in
            render([Note(freq: 880 * pow(2, semis / 12), start: 0, length: 0.09, gain: 0.35)], glide: -0.25)
        }
        buffers[.crit] = [render([
            Note(freq: 1318.5, start: 0, length: 0.12, gain: 0.3),
            Note(freq: 1975.5, start: 0.05, length: 0.18, gain: 0.25),
        ], glide: 0)]
        buffers[.complete] = [render([
            Note(freq: 659.3, start: 0.00, length: 0.25, gain: 0.3),
            Note(freq: 830.6, start: 0.10, length: 0.25, gain: 0.3),
            Note(freq: 987.8, start: 0.20, length: 0.30, gain: 0.3),
            Note(freq: 1318.5, start: 0.32, length: 0.55, gain: 0.32),
        ], glide: 0)]
        buffers[.purchase] = [render([
            Note(freq: 1046.5, start: 0, length: 0.08, gain: 0.25),
            Note(freq: 1568.0, start: 0.06, length: 0.14, gain: 0.25),
        ], glide: 0)]
        buffers[.boost] = [render([
            Note(freq: 523.3, start: 0, length: 0.35, gain: 0.25),
        ], glide: 1.0)]
        buffers[.drama] = [render([
            Note(freq: 392.0, start: 0, length: 0.18, gain: 0.3),
            Note(freq: 370.0, start: 0.16, length: 0.18, gain: 0.3),
            Note(freq: 311.1, start: 0.32, length: 0.45, gain: 0.3),
        ], glide: 0)]
    }

    private func render(_ notes: [Note], glide: Double) -> AVAudioPCMBuffer {
        let sr = format.sampleRate
        let total = (notes.map { $0.start + $0.length }.max() ?? 0.1) + 0.05
        let frames = AVAudioFrameCount(total * sr)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let out = buffer.floatChannelData![0]
        for i in 0..<Int(frames) { out[i] = 0 }
        for n in notes {
            let startFrame = Int(n.start * sr)
            let len = Int(n.length * sr)
            var phase = 0.0
            for i in 0..<len {
                let t = Double(i) / Double(len)
                let f = n.freq * (1 + glide * t)
                phase += 2 * .pi * f / sr
                // Fast attack, exponential decay; a touch of 2nd harmonic for warmth.
                let env = min(1, Double(i) / (0.004 * sr)) * exp(-4.5 * t)
                let s = (sin(phase) + 0.25 * sin(2 * phase)) * env * n.gain
                let idx = startFrame + i
                if idx < Int(frames) { out[idx] += Float(s) }
            }
        }
        return buffer
    }
}

// MARK: - Number formatting

enum Fmt {
    private static let suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

    /// 950 → "950", 12_480 → "12,480", 3_204_000 → "3.20M"
    static func number(_ value: Double) -> String {
        let v = max(value, 0)
        if v < 1_000 {
            return v < 10 && v != v.rounded() ? String(format: "%.1f", v) : String(Int(v))
        }
        if v < 100_000 {
            return Int(v).formatted(.number.grouping(.automatic))
        }
        var tier = Int(log10(v) / 3)
        tier = min(tier, suffixes.count - 1)
        let scaled = v / pow(1000, Double(tier))
        let s = scaled >= 100 ? String(format: "%.0f", scaled) : scaled >= 10 ? String(format: "%.1f", scaled) : String(format: "%.2f", scaled)
        return s + suffixes[tier]
    }

    static func rate(_ value: Double) -> String {
        if value > 0 && value < 10 { return String(format: "%.1f", value) }
        return number(value)
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds.rounded(.up))
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m \(s % 60)s" }
        return "\(s / 3600)h \((s % 3600) / 60)m"
    }
}
