//
//  SoundEngine.swift
//  FarkleForge
//
//  Plays the synthesized effects from Synth.swift. Buffers are rendered once on a
//  background queue at launch and cached; playback goes through a small pool of
//  player nodes so overlapping sounds (fast typing, a farkle over a bank) don't cut
//  each other off.
//

import AVFoundation
import UIKit

final class SoundEngine {
    static let shared = SoundEngine()

    static let enabledKey = "soundEnabled"

    private let engine = AVAudioEngine()
    private let format: AVAudioFormat
    private var players: [AVAudioPlayerNode] = []
    private var busy: [Bool] = []
    private var nextPlayer = 0
    private var cache: [SoundEffect: AVAudioPCMBuffer] = [:]
    private let queue = DispatchQueue(label: "com.farkleforge.sound", qos: .userInitiated)
    private var isConfigured = false
    private var farkleBag: [Int] = []
    private var lastPlayed: [SoundEffect: CFTimeInterval] = [:]

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 1)!
    }

    /// Call once at launch: configures the session and renders the fixed sounds so
    /// the first key tap is instant.
    func prepare() {
        queue.async { [self] in
            configureIfNeeded()
            var effects: [SoundEffect] = (0...9).map { .key($0) }
            effects += [.keyPair("00"), .keyPair("50"), .clear, .nope, .undo, .coin, .crown,
                        .finalRound, .bubbleGrab, .bubbleBump, .tick, .select, .start,
                        .fanfare, .confetti, .logo]
            effects += (0..<SoundEffect.farkleVariantCount).map { .farkle($0) }
            effects += AnimalVoice.allCases.map { .voice($0) }
            for effect in effects where cache[effect] == nil {
                cache[effect] = makeBuffer(Synth.render(effect))
            }
        }
    }

    /// Plays an effect. `minInterval` rate-limits repeats of the same sound (e.g.
    /// bubbles bumping into each other several times a second).
    func play(_ effect: SoundEffect, volume: Float = 1, minInterval: CFTimeInterval = 0) {
        guard isEnabled else { return }
        queue.async { [self] in
            if minInterval > 0 {
                let now = CACurrentMediaTime()
                if let last = lastPlayed[effect], now - last < minInterval { return }
                lastPlayed[effect] = now
            }
            configureIfNeeded()
            guard let buffer = buffer(for: effect) else { return }
            startEngineIfNeeded()
            guard engine.isRunning else { return }

            let index = claimPlayer()
            let player = players[index]
            player.volume = volume
            player.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak self] in
                self?.queue.async { self?.busy[index] = false }
            }
            if !player.isPlaying { player.play() }
        }
    }

    /// Farkle sounds rotate through a shuffled bag, so you hear every one before
    /// any repeats and never get the same joke twice in a row.
    func playFarkle() {
        queue.async { [self] in
            if farkleBag.isEmpty {
                farkleBag = Array(0..<SoundEffect.farkleVariantCount).shuffled()
            }
            let variant = farkleBag.removeFirst()
            DispatchQueue.main.async { self.play(.farkle(variant)) }
        }
    }

    // MARK: - Private

    private func buffer(for effect: SoundEffect) -> AVAudioPCMBuffer? {
        if let cached = cache[effect] { return cached }
        let buffer = makeBuffer(Synth.render(effect))
        // The bank fill varies per score, so it isn't worth caching.
        if case .fill = effect { return buffer }
        cache[effect] = buffer
        return buffer
    }

    private func makeBuffer(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            channel.update(from: source.baseAddress!, count: samples.count)
        }
        return buffer
    }

    private func claimPlayer() -> Int {
        // Prefer an idle node; if all are busy, steal the next one round-robin.
        let count = players.count
        for offset in 0..<count {
            let index = (nextPlayer + offset) % count
            if !busy[index] {
                nextPlayer = (index + 1) % count
                busy[index] = true
                return index
            }
        }
        let index = nextPlayer
        nextPlayer = (nextPlayer + 1) % count
        return index
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        // Ambient: respects the silent switch and mixes with whatever music is
        // playing at the table.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])

        for _ in 0..<8 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
            busy.append(false)
        }
        engine.mainMixerNode.outputVolume = 0.9
        engine.prepare()

        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil
        ) { [weak self] _ in
            // Route changed (headphones, AirPods...). The engine stops itself; restart lazily.
            self?.queue.async { self?.busy = self?.busy.map { _ in false } ?? [] }
        }
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            #if DEBUG
            print("Sound engine failed to start: \(error.localizedDescription)")
            #endif
        }
    }
}

/// Haptics are part of the feel: every sound has a physical counterpart.
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()

    static func tap() { light.impactOccurred(intensity: 0.6) }
    static func soft(_ intensity: CGFloat = 0.7) { soft.impactOccurred(intensity: intensity) }
    static func rigid(_ intensity: CGFloat = 0.8) { rigid.impactOccurred(intensity: intensity) }
    static func success() { notification.notificationOccurred(.success) }
    static func warning() { notification.notificationOccurred(.warning) }

    /// A thud followed by two quick aftershocks, timed to the screen shake.
    static func farkle() {
        heavy.impactOccurred(intensity: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) { rigid.impactOccurred(intensity: 0.7) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { rigid.impactOccurred(intensity: 0.4) }
    }

    /// Little ticks that climb with the progress bar as it sweeps.
    static func fill(steps: Int, duration: Double) {
        for i in 0..<steps {
            let x = Double(i) / Double(max(steps - 1, 1))
            let delay = duration * (1 - cbrt(1 - x * 0.999)) * 0.9
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                light.impactOccurred(intensity: 0.3 + 0.5 * x)
            }
        }
    }
}
