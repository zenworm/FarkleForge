//
//  Synth.swift
//  FarkleForge
//
//  A tiny offline synthesizer. Every sound in the app is rendered from code into a
//  sample buffer, so there are no audio files to manage and any sound can be retuned
//  right here. The palette is "warm chiptune" to match the pixel-art animals: soft
//  pulse and triangle voices, plus a few comedy instruments reserved for farkles.
//
//  Foundation-only on purpose, so the same recipes can be rendered to .wav on a Mac
//  for auditioning without running the app.
//

import Foundation

enum SoundEffect: Hashable {
    /// Number pad digit. Each digit is a fixed note of a pentatonic scale, so typing
    /// a score always plays the same little melody ("1500" has a tune).
    case key(Int)
    /// The "00" and "50" shortcut keys: two notes in quick succession.
    case keyPair(String)
    case clear
    case nope
    case undo
    case coin
    /// The rising arpeggio that rides the progress bar; pitch tracks the bar's position.
    case fill(from: Double, to: Double)
    case crown
    case finalRound
    case farkle(Int)
    case voice(AnimalVoice)
    case bubbleGrab
    case bubbleBump
    case tick
    case select
    case start
    case fanfare
    case confetti
    case logo

    static let farkleVariantCount = 5
}

enum AnimalVoice: Hashable, CaseIterable {
    case croak, yip, squeak, chitter, purr, mystery
}

enum Synth {
    static let sampleRate = 44_100.0

    enum Wave {
        case sine, triangle, saw, noise
        case pulse(Double) // duty cycle
    }

    enum Filter {
        case lowpass(Double)
        case bandpass(Double, q: Double)
        /// Resonant lowpass whose cutoff moves over time (seconds since the voice began).
        case sweep((Double) -> Double, q: Double)
    }

    struct Envelope {
        var attack: Double = 0.003
        /// Exponential decay time constant; `.infinity` holds the level until release.
        var decay: Double = .infinity
        var release: Double = 0.01

        func level(at t: Double, length: Double) -> Double {
            let a = attack > 0 ? min(t / attack, 1) : 1
            let d = decay.isFinite ? exp(-max(t - attack, 0) / decay) : 1
            let r = release > 0 ? min(max((length - t) / release, 0), 1) : 1
            return a * d * r
        }
    }

    // MARK: - Rendering

    static func render(_ effect: SoundEffect) -> [Float] {
        switch effect {
        case .key(let digit): return key(digit)
        case .keyPair(let pair): return keyPair(pair)
        case .clear: return clear()
        case .nope: return nope()
        case .undo: return undo()
        case .coin: return coin()
        case .fill(let from, let to): return fill(from: from, to: to)
        case .crown: return crown()
        case .finalRound: return finalRound()
        case .farkle(let variant): return farkle(variant)
        case .voice(let voice): return self.voice(voice)
        case .bubbleGrab: return bubbleGrab()
        case .bubbleBump: return bubbleBump()
        case .tick: return tick()
        case .select: return select()
        case .start: return start()
        case .fanfare: return fanfare()
        case .confetti: return confetti()
        case .logo: return logo()
        }
    }

    static func hz(_ midi: Double) -> Double {
        440 * pow(2, (midi - 69) / 12)
    }

    /// G major-ish pentatonic starting at G4. Pentatonic means any sequence of digits
    /// sounds pleasant, which is the whole trick behind the musical keypad.
    static let keyScale: [Double] = [67, 69, 72, 74, 76, 79, 81, 84, 86, 88]

    static func pentatonic(_ index: Int, base: Double = 67) -> Double {
        let steps: [Double] = [0, 2, 5, 7, 9]
        let octave = Double(index / 5) * 12
        return base + octave + steps[index % 5]
    }

    /// Frequency wobble, for anything that should feel sung rather than beeped.
    static func vibrato(_ t: Double, rate: Double, depth: Double, delay: Double = 0) -> Double {
        guard t > delay else { return 1 }
        let ramp = min((t - delay) / 0.12, 1)
        return 1 + depth * ramp * sin(2 * .pi * rate * (t - delay))
    }

    // MARK: - UI

    private static func key(_ digit: Int) -> [Float] {
        let f = hz(keyScale[max(0, min(digit, 9))])
        var track = Track(duration: 0.24)
        track.pluck(at: 0, frequency: f)
        return track.finish(peak: 0.3)
    }

    private static func keyPair(_ pair: String) -> [Float] {
        let notes: [Double] = pair == "50" ? [keyScale[5], keyScale[7]] : [keyScale[0], keyScale[5]]
        var track = Track(duration: 0.3)
        track.pluck(at: 0, frequency: hz(notes[0]), gain: 0.8)
        track.pluck(at: 0.06, frequency: hz(notes[1]))
        return track.finish(peak: 0.3)
    }

    private static func clear() -> [Float] {
        var track = Track(duration: 0.18)
        track.add(at: 0, length: 0.16, wave: .triangle,
                  pitch: { t in 1100 * pow(0.22, t / 0.16) },
                  envelope: .init(attack: 0.002, decay: 0.08, release: 0.03))
        track.add(at: 0, length: 0.07, wave: .noise, pitch: { _ in 0 },
                  envelope: .init(attack: 0.001, decay: 0.02, release: 0.02),
                  gain: 0.12, filter: .bandpass(3200, q: 1.5))
        return track.finish(peak: 0.26)
    }

    private static func nope() -> [Float] {
        var track = Track(duration: 0.2)
        for (i, f) in [185.0, 165.0].enumerated() {
            track.add(at: Double(i) * 0.085, length: 0.07, wave: .pulse(0.5), pitch: { _ in f },
                      envelope: .init(attack: 0.002, decay: 0.05, release: 0.02),
                      filter: .lowpass(1300))
        }
        return track.finish(peak: 0.3)
    }

    private static func undo() -> [Float] {
        var track = Track(duration: 0.24)
        // A little tape-rewind warble: up fast, with a wobble, then settle.
        track.add(at: 0, length: 0.14, wave: .triangle,
                  pitch: { t in 320 * pow(3.4, t / 0.14) * vibrato(t, rate: 32, depth: 0.05) },
                  envelope: .init(attack: 0.004, decay: .infinity, release: 0.03))
        track.pluck(at: 0.13, frequency: hz(keyScale[3]), gain: 0.7)
        return track.finish(peak: 0.26)
    }

    private static func coin() -> [Float] {
        var track = Track(duration: 0.4)
        track.add(at: 0, length: 0.06, wave: .pulse(0.25), pitch: { _ in hz(83) },
                  envelope: .init(attack: 0.002, release: 0.01), filter: .lowpass(5000))
        track.add(at: 0.055, length: 0.32, wave: .pulse(0.25), pitch: { _ in hz(88) },
                  envelope: .init(attack: 0.002, decay: 0.11, release: 0.05), filter: .lowpass(5000))
        track.add(at: 0.055, length: 0.32, wave: .sine, pitch: { _ in hz(100) },
                  envelope: .init(attack: 0.002, decay: 0.08, release: 0.05), gain: 0.25)
        return track.finish(peak: 0.3)
    }

    /// Notes are spaced on the same ease-out curve as the progress bar, so each blip
    /// lands where the bar's tip is. Bigger banks climb further up the scale.
    /// How many notes the fill plays; haptics tick along with the same count.
    static func fillSteps(from: Double, to: Double) -> Int {
        max(3, min(12, Int((max(0, to - from) * 30).rounded()) + 3))
    }

    private static func fill(from: Double, to: Double) -> [Float] {
        let steps = fillSteps(from: from, to: to)
        let sweep = 0.6
        let startIndex = Int(max(0, min(from, 1)) * 10)
        var track = Track(duration: sweep + 0.45)
        for i in 0..<steps {
            let x = Double(i) / Double(steps - 1)
            let time = sweep * (1 - cbrt(1 - x * 0.999)) * 0.9
            let f = hz(pentatonic(min(startIndex + i, 19), base: 67))
            let isLast = i == steps - 1
            let gain = 0.55 + 0.45 * x
            track.add(at: time, length: isLast ? 0.4 : 0.1, wave: .pulse(0.5), pitch: { _ in f },
                      envelope: .init(attack: 0.002, decay: isLast ? 0.14 : 0.035, release: 0.03),
                      gain: gain * 0.6, filter: .lowpass(2600))
            track.add(at: time, length: isLast ? 0.4 : 0.1, wave: .triangle, pitch: { _ in f },
                      envelope: .init(attack: 0.002, decay: isLast ? 0.18 : 0.05, release: 0.03),
                      gain: gain * 0.7)
            if isLast {
                track.add(at: time + 0.02, length: 0.38, wave: .sine, pitch: { _ in f * 2 },
                          envelope: .init(attack: 0.01, decay: 0.16, release: 0.05), gain: 0.25)
            }
        }
        return track.finish(peak: 0.3)
    }

    private static func crown() -> [Float] {
        var track = Track(duration: 0.6)
        for (time, midi) in [(0.0, 88.0), (0.08, 95.0)] {
            let f = hz(midi)
            track.add(at: time, length: 0.5, wave: .sine, pitch: { _ in f },
                      envelope: .init(attack: 0.002, decay: 0.18, release: 0.08))
            // Inharmonic partial gives it a small-bell shimmer.
            track.add(at: time, length: 0.3, wave: .sine, pitch: { _ in f * 2.76 },
                      envelope: .init(attack: 0.001, decay: 0.05, release: 0.05), gain: 0.18)
        }
        return track.finish(peak: 0.28)
    }

    private static func finalRound() -> [Float] {
        var track = Track(duration: 1.0)
        for (i, midi) in [67.0, 72.0, 76.0].enumerated() {
            let f = hz(midi)
            track.add(at: Double(i) * 0.09, length: 0.085, wave: .pulse(0.5), pitch: { _ in f },
                      envelope: .init(attack: 0.003, release: 0.015), filter: .lowpass(3000))
        }
        for (midi, gain) in [(79.0, 1.0), (76.0, 0.45)] {
            let f = hz(midi)
            track.add(at: 0.27, length: 0.62, wave: .pulse(0.5),
                      pitch: { t in f * vibrato(t, rate: 6, depth: 0.012, delay: 0.12) },
                      envelope: .init(attack: 0.004, decay: 0.5, release: 0.12),
                      gain: gain, filter: .lowpass(3000))
        }
        return track.finish(peak: 0.36)
    }

    // MARK: - Farkles (the comedy department)

    private static func farkle(_ variant: Int) -> [Float] {
        switch variant % SoundEffect.farkleVariantCount {
        case 0: return sadTrombone()
        case 1: return slideWhistle()
        case 2: return boing()
        case 3: return raspberry()
        default: return chipGameOver()
        }
    }

    /// Wah, wah, wah, waaah. A sawtooth through a resonant filter that opens and
    /// closes per note gives it the muted-brass "wah".
    private static func sadTrombone() -> [Float] {
        var track = Track(duration: 1.35)
        let notes: [(Double, Double, Double)] = [(0, 0.21, 58), (0.23, 0.21, 57), (0.46, 0.21, 56), (0.69, 0.62, 55)]
        for (index, (time, length, midi)) in notes.enumerated() {
            let f = hz(midi)
            let isLast = index == notes.count - 1
            track.add(at: time, length: length, wave: .saw,
                      pitch: { t in
                          let scoop = 1 - 0.03 * exp(-t / 0.03)
                          return f * scoop * (isLast ? vibrato(t, rate: 5.5, depth: 0.03, delay: 0.12) : 1)
                      },
                      envelope: .init(attack: 0.02, release: isLast ? 0.2 : 0.04),
                      filter: .sweep({ t in 280 + 1500 * pow(sin(.pi * min(t / length, 1)), 0.7) }, q: 3))
        }
        return track.finish(peak: 0.5)
    }

    private static func slideWhistle() -> [Float] {
        var track = Track(duration: 0.85)
        let slide = 0.6
        track.add(at: 0, length: slide, wave: .sine,
                  pitch: { t in 1500 * pow(260 / 1500, t / slide) * vibrato(t, rate: 7, depth: 0.025) },
                  envelope: .init(attack: 0.02, release: 0.04))
        track.add(at: 0, length: slide, wave: .triangle,
                  pitch: { t in 1500 * pow(260 / 1500, t / slide) * vibrato(t, rate: 7, depth: 0.025) },
                  envelope: .init(attack: 0.02, release: 0.04), gain: 0.2)
        // ...bonk.
        track.add(at: slide, length: 0.2, wave: .sine, pitch: { t in 110 + 130 * exp(-t / 0.025) },
                  envelope: .init(attack: 0.001, decay: 0.07, release: 0.03), gain: 1.1)
        track.add(at: slide, length: 0.06, wave: .noise, pitch: { _ in 0 },
                  envelope: .init(attack: 0.001, decay: 0.015, release: 0.02),
                  gain: 0.35, filter: .lowpass(900))
        return track.finish(peak: 0.5)
    }

    private static func boing() -> [Float] {
        var track = Track(duration: 0.85)
        let length = 0.8
        track.add(at: 0, length: length, wave: .saw,
                  pitch: { t in 105 * (1 + 0.7 * t) * (1 + 0.32 * exp(-t / 0.28) * sin(2 * .pi * 12 * t)) },
                  envelope: .init(attack: 0.003, decay: 0.3, release: 0.08),
                  filter: .sweep({ t in 300 + 2200 * exp(-t / 0.18) }, q: 5))
        return track.finish(peak: 0.5)
    }

    /// A kazoo raspberry: buzzy saw, fluttering amplitude, sagging pitch.
    private static func raspberry() -> [Float] {
        var track = Track(duration: 0.7)
        let length = 0.62
        let flutter: (Double) -> Double = { t in 0.35 + 0.65 * pow(0.5 + 0.5 * sin(2 * .pi * 29 * t), 2) }
        track.add(at: 0, length: length, wave: .saw, pitch: { t in 135 * (1 - 0.28 * t / length) },
                  envelope: .init(attack: 0.012, release: 0.08),
                  filter: .bandpass(950, q: 1.6), am: flutter)
        track.add(at: 0, length: length, wave: .noise, pitch: { _ in 0 },
                  envelope: .init(attack: 0.012, release: 0.08),
                  gain: 0.3, filter: .bandpass(1600, q: 1.2), am: flutter)
        return track.finish(peak: 0.5)
    }

    /// The universal 8-bit "you have died" sting, sagging on every note.
    private static func chipGameOver() -> [Float] {
        var track = Track(duration: 1.0)
        for (i, midi) in [67.0, 66.0, 65.0].enumerated() {
            let f = hz(midi)
            track.add(at: Double(i) * 0.14, length: 0.12, wave: .pulse(0.5),
                      pitch: { t in f * pow(2, -t / 0.12 / 12) },
                      envelope: .init(attack: 0.003, release: 0.02), filter: .lowpass(2400))
        }
        let f = hz(64)
        track.add(at: 0.42, length: 0.52, wave: .pulse(0.5),
                  pitch: { t in f * pow(2, -2 * t / 0.52 / 12) * vibrato(t, rate: 8, depth: 0.02, delay: 0.1) },
                  envelope: .init(attack: 0.003, decay: 0.45, release: 0.1), filter: .lowpass(2400))
        return track.finish(peak: 0.42)
    }

    // MARK: - Animal voices

    private static func voice(_ voice: AnimalVoice) -> [Float] {
        switch voice {
        case .croak: return croak()
        case .yip: return yip()
        case .squeak: return squeak()
        case .chitter: return chitter()
        case .purr: return purr()
        case .mystery: return mystery()
        }
    }

    /// Rib-bit.
    private static func croak() -> [Float] {
        var track = Track(duration: 0.4)
        let creak: (Double) -> Double = { t in 0.3 + 0.7 * pow(0.5 + 0.5 * sin(2 * .pi * 42 * t), 3) }
        for (time, length, top, bottom) in [(0.0, 0.11, 100.0, 86.0), (0.16, 0.16, 124.0, 96.0)] {
            track.add(at: time, length: length, wave: .pulse(0.2),
                      pitch: { t in top + (bottom - top) * t / length },
                      envelope: .init(attack: 0.006, release: 0.04),
                      filter: .bandpass(680, q: 2.2), am: creak)
        }
        return track.finish(peak: 0.5)
    }

    private static func yip() -> [Float] {
        var track = Track(duration: 0.3)
        for (time, low, high) in [(0.0, 720.0, 1500.0), (0.12, 820.0, 1750.0)] {
            track.add(at: time, length: 0.09, wave: .triangle,
                      pitch: { t in low * pow(high / low, min(t / 0.06, 1)) },
                      envelope: .init(attack: 0.003, decay: 0.05, release: 0.02))
            track.add(at: time, length: 0.09, wave: .pulse(0.3),
                      pitch: { t in low * pow(high / low, min(t / 0.06, 1)) },
                      envelope: .init(attack: 0.003, decay: 0.03, release: 0.02),
                      gain: 0.25, filter: .lowpass(4000))
        }
        return track.finish(peak: 0.36)
    }

    private static func squeak() -> [Float] {
        var track = Track(duration: 0.4)
        for (time, length, base) in [(0.0, 0.15, 1250.0), (0.2, 0.12, 1450.0)] {
            track.add(at: time, length: length, wave: .sine,
                      pitch: { t in (base + 380 * sin(.pi * t / length)) * vibrato(t, rate: 24, depth: 0.03) },
                      envelope: .init(attack: 0.008, release: 0.04))
        }
        return track.finish(peak: 0.3)
    }

    private static func chitter() -> [Float] {
        var track = Track(duration: 0.42)
        let pitches: [Double] = [1180, 1420, 1050, 1560, 1250, 1640, 1120, 1480]
        for (i, f) in pitches.enumerated() {
            track.add(at: Double(i) * 0.042, length: 0.03, wave: .pulse(0.25),
                      pitch: { t in f * (1 + 0.15 * t / 0.03) },
                      envelope: .init(attack: 0.002, release: 0.01),
                      gain: i.isMultiple(of: 3) ? 1 : 0.7, filter: .bandpass(2000, q: 1.2))
        }
        return track.finish(peak: 0.32)
    }

    /// A low purr that swells into a small, dignified rawr.
    private static func purr() -> [Float] {
        var track = Track(duration: 0.85)
        let rumble: (Double) -> Double = { t in 0.5 + 0.5 * sin(2 * .pi * 24 * t) }
        track.add(at: 0, length: 0.45, wave: .saw, pitch: { _ in 58 },
                  envelope: .init(attack: 0.15, release: 0.1),
                  gain: 0.8, filter: .lowpass(520), am: rumble)
        track.add(at: 0, length: 0.45, wave: .noise, pitch: { _ in 0 },
                  envelope: .init(attack: 0.15, release: 0.1),
                  gain: 0.25, filter: .lowpass(700), am: rumble)
        let rawr = 0.38
        track.add(at: 0.38, length: rawr, wave: .saw,
                  pitch: { t in 88 + 60 * sin(.pi * min(t / rawr, 1) * 0.85) },
                  envelope: .init(attack: 0.03, release: 0.12),
                  filter: .sweep({ t in 450 + 1300 * sin(.pi * min(t / rawr, 1)) }, q: 2.5))
        return track.finish(peak: 0.5)
    }

    /// For the animals nobody has met yet: a curious theremin "hmm?" that lifts at the end.
    private static func mystery() -> [Float] {
        var track = Track(duration: 0.72)
        let length = 0.66
        let pitch: (Double) -> Double = { t in
            let dip = 1 - 0.08 * sin(.pi * min(t / 0.3, 1))
            let lift = 1 + 0.45 * pow(max(0, (t - 0.36) / 0.3), 2)
            return 430 * dip * lift * vibrato(t, rate: 5.5, depth: 0.02, delay: 0.05)
        }
        track.add(at: 0, length: length, wave: .sine, pitch: pitch,
                  envelope: .init(attack: 0.06, release: 0.14))
        track.add(at: 0, length: length, wave: .triangle, pitch: pitch,
                  envelope: .init(attack: 0.06, release: 0.14), gain: 0.12)
        return track.finish(peak: 0.3)
    }

    // MARK: - Start screen and celebration

    private static func bubbleGrab() -> [Float] {
        var track = Track(duration: 0.12)
        track.add(at: 0, length: 0.1, wave: .sine, pitch: { t in 280 * pow(2, t / 0.07) },
                  envelope: .init(attack: 0.003, decay: 0.045, release: 0.02))
        return track.finish(peak: 0.24)
    }

    private static func bubbleBump() -> [Float] {
        var track = Track(duration: 0.09)
        track.add(at: 0, length: 0.08, wave: .sine, pitch: { t in 190 - 50 * t / 0.08 },
                  envelope: .init(attack: 0.002, decay: 0.025, release: 0.02))
        return track.finish(peak: 0.16)
    }

    private static func tick() -> [Float] {
        var track = Track(duration: 0.04)
        track.add(at: 0, length: 0.035, wave: .sine, pitch: { _ in 1800 },
                  envelope: .init(attack: 0.001, decay: 0.008, release: 0.01))
        track.add(at: 0, length: 0.02, wave: .noise, pitch: { _ in 0 },
                  envelope: .init(attack: 0.001, decay: 0.004, release: 0.01),
                  gain: 0.15, filter: .bandpass(5000, q: 1))
        return track.finish(peak: 0.16)
    }

    private static func select() -> [Float] {
        var track = Track(duration: 0.3)
        track.pluck(at: 0, frequency: hz(keyScale[5]), gain: 0.8)
        track.pluck(at: 0.05, frequency: hz(keyScale[7]))
        return track.finish(peak: 0.28)
    }

    private static func start() -> [Float] {
        var track = Track(duration: 0.7)
        let notes: [Double] = [72, 76, 79, 84]
        for (i, midi) in notes.enumerated() {
            let f = hz(midi)
            let isLast = i == notes.count - 1
            track.add(at: Double(i) * 0.065, length: isLast ? 0.4 : 0.07, wave: .pulse(0.5), pitch: { _ in f },
                      envelope: .init(attack: 0.003, decay: isLast ? 0.15 : .infinity, release: 0.02),
                      filter: .lowpass(3200))
        }
        // Whoosh underneath, rising with the arpeggio.
        track.add(at: 0, length: 0.4, wave: .noise, pitch: { _ in 0 },
                  envelope: .init(attack: 0.12, release: 0.2), gain: 0.22,
                  filter: .sweep({ t in 500 * pow(8, t / 0.4) }, q: 1.4))
        return track.finish(peak: 0.36)
    }

    private static func fanfare() -> [Float] {
        var track = Track(duration: 1.6)
        for (i, midi) in [67.0, 72.0, 76.0].enumerated() {
            let f = hz(midi)
            track.add(at: Double(i) * 0.1, length: 0.09, wave: .pulse(0.5), pitch: { _ in f },
                      envelope: .init(attack: 0.003, release: 0.015), filter: .lowpass(3200))
        }
        for (midi, gain) in [(84.0, 1.0), (79.0, 0.5), (76.0, 0.4)] {
            let f = hz(midi)
            track.add(at: 0.3, length: 1.1, wave: .pulse(0.5),
                      pitch: { t in f * vibrato(t, rate: 6, depth: 0.012, delay: 0.2) },
                      envelope: .init(attack: 0.005, decay: 0.9, release: 0.25),
                      gain: gain, filter: .lowpass(3000))
        }
        // Sparkle run on top.
        for i in 0..<10 {
            let f = hz(pentatonic(10 + i, base: 67))
            track.add(at: 0.38 + Double(i) * 0.035, length: 0.2, wave: .sine, pitch: { _ in f },
                      envelope: .init(attack: 0.002, decay: 0.06, release: 0.05), gain: 0.22)
        }
        return track.finish(peak: 0.45)
    }

    private static func confetti() -> [Float] {
        var track = Track(duration: 0.25)
        track.add(at: 0, length: 0.2, wave: .noise, pitch: { _ in 0 },
                  envelope: .init(attack: 0.002, decay: 0.05, release: 0.05),
                  filter: .bandpass(2400, q: 0.9))
        return track.finish(peak: 0.22)
    }

    /// Da-da-da-DUM. Tapping the logo is serious business.
    private static func logo() -> [Float] {
        var track = Track(duration: 1.0)
        for i in 0..<3 {
            track.add(at: Double(i) * 0.12, length: 0.09, wave: .pulse(0.5), pitch: { _ in hz(67) },
                      envelope: .init(attack: 0.003, release: 0.02), filter: .lowpass(2400))
        }
        track.add(at: 0.36, length: 0.55, wave: .pulse(0.5),
                  pitch: { t in hz(63) * vibrato(t, rate: 6, depth: 0.015, delay: 0.15) },
                  envelope: .init(attack: 0.004, decay: 0.5, release: 0.12), filter: .lowpass(2400))
        return track.finish(peak: 0.36)
    }
}

// MARK: - Track

extension Synth {
    struct Track {
        private(set) var samples: [Float]

        init(duration: Double) {
            samples = [Float](repeating: 0, count: Int(duration * Synth.sampleRate))
        }

        /// The keypad voice: a triangle "plink" with a tiny pitch drop, plus a quiet
        /// octave-up pulse that's gone within a few milliseconds to give it a chip edge.
        mutating func pluck(at start: Double, frequency f: Double, gain: Double = 1) {
            add(at: start, length: 0.22, wave: .triangle,
                pitch: { t in f * (1 + 0.04 * exp(-t / 0.012)) },
                envelope: .init(attack: 0.002, decay: 0.07, release: 0.03), gain: gain)
            add(at: start, length: 0.05, wave: .pulse(0.25), pitch: { _ in f * 2 },
                envelope: .init(attack: 0.001, decay: 0.012, release: 0.01),
                gain: gain * 0.25, filter: .lowpass(3500))
        }

        /// Mixes one voice into the track. `pitch` and `am` are functions of seconds
        /// since the voice started.
        mutating func add(
            at start: Double,
            length: Double,
            wave: Wave,
            pitch: (Double) -> Double,
            envelope: Envelope,
            gain: Double = 1,
            filter: Filter? = nil,
            am: ((Double) -> Double)? = nil
        ) {
            let sr = Synth.sampleRate
            let first = Int(start * sr)
            let count = min(Int(length * sr), samples.count - first)
            guard first >= 0, count > 0 else { return }

            var phase = 0.0
            var noise = NoiseSource()
            var svf = StateVariableFilter()

            samples.withUnsafeMutableBufferPointer { out in
                for i in 0..<count {
                    let t = Double(i) / sr
                    let f = pitch(t)
                    let dt = f / sr

                    var value: Double
                    switch wave {
                    case .sine:
                        value = sin(2 * .pi * phase)
                    case .triangle:
                        value = 4 * abs(phase - 0.5) - 1
                    case .saw:
                        value = 2 * phase - 1 - Self.polyBLEP(phase, dt)
                    case .pulse(let duty):
                        value = phase < duty ? 1 : -1
                        value += Self.polyBLEP(phase, dt)
                        value -= Self.polyBLEP((phase + 1 - duty).truncatingRemainder(dividingBy: 1), dt)
                        // A narrow pulse isn't centered on zero; remove the offset or it thumps.
                        value -= 2 * duty - 1
                    case .noise:
                        value = noise.next()
                    }

                    phase += dt
                    if phase >= 1 { phase -= floor(phase) }

                    if let filter {
                        switch filter {
                        case .lowpass(let cutoff):
                            value = svf.process(value, cutoff: cutoff, q: 0.707).low
                        case .bandpass(let cutoff, let q):
                            value = svf.process(value, cutoff: cutoff, q: q).band
                        case .sweep(let cutoff, let q):
                            value = svf.process(value, cutoff: cutoff(t), q: q).low
                        }
                    }

                    let level = envelope.level(at: t, length: length) * gain * (am?(t) ?? 1)
                    out[first + i] += Float(value * level)
                }
            }
        }

        /// Soft-clips, then normalizes to `peak`, so every sound sits at a deliberate
        /// loudness regardless of how many voices went into it.
        func finish(peak: Double) -> [Float] {
            let maxValue = samples.reduce(Float(0)) { max($0, abs($1)) }
            guard maxValue > 0 else { return samples }
            let drive: Float = 1.3
            let norm = tanh(drive)
            var result = samples.map { tanh($0 / maxValue * drive) / norm * Float(peak) }
            // Guard against a click if the last voice was still sounding at the end.
            let tail = min(result.count, Int(0.004 * Synth.sampleRate))
            for i in 0..<tail {
                result[result.count - 1 - i] *= Float(i) / Float(tail)
            }
            return result
        }

        private static func polyBLEP(_ t: Double, _ dt: Double) -> Double {
            guard dt > 0 else { return 0 }
            if t < dt {
                let x = t / dt
                return x + x - x * x - 1
            } else if t > 1 - dt {
                let x = (t - 1) / dt
                return x * x + x + x + 1
            }
            return 0
        }
    }

    /// Chamberlin state-variable filter: cheap, and resonant enough for a convincing "wah".
    private struct StateVariableFilter {
        private var low = 0.0
        private var band = 0.0

        mutating func process(_ input: Double, cutoff: Double, q: Double) -> (low: Double, band: Double) {
            let fc = min(max(cutoff, 20), Synth.sampleRate / 6)
            let f = 2 * sin(.pi * fc / Synth.sampleRate)
            let damping = 1 / max(q, 0.5)
            low += f * band
            let high = input - low - damping * band
            band += f * high
            return (low, band)
        }
    }

    /// Deterministic noise, so a sound renders identically every time.
    private struct NoiseSource {
        private var state: UInt32 = 0x9E3779B9

        mutating func next() -> Double {
            state ^= state << 13
            state ^= state >> 17
            state ^= state << 5
            return Double(state) / Double(UInt32.max) * 2 - 1
        }
    }
}
