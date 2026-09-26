import AVFoundation
import UIKit

/// Tiny original synthesized cues; no downloads, music interruption, or bundled audio required.
@MainActor
final class ArcadeFeedback {
    static let shared = ArcadeFeedback()
    enum Cue { case tap, roll, bank, farkle, win }
    private var player: AVAudioPlayer?
    private var sounds: [Cue: Data] = [:]

    func play(_ cue: Cue) {
        switch cue {
        case .tap: UISelectionFeedbackGenerator().selectionChanged()
        case .roll: UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .bank, .win: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .farkle: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        guard UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true else { return }
        do {
            // Ambient obeys the silent switch and mixes with the table's music.
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            if sounds[cue] == nil { sounds[cue] = makeWave(cue) }
            guard let data = sounds[cue] else { return }
            player = try AVAudioPlayer(data: data)
            player?.volume = cue == .tap ? 0.12 : 0.25
            player?.play()
        } catch {
            // Haptics and visual feedback still work when audio is unavailable.
        }
    }

    private func makeWave(_ cue: Cue) -> Data {
        let notes: [Double]
        let duration: Double
        switch cue {
        case .tap: notes = [880]; duration = 0.028
        case .roll: notes = [330, 440, 554]; duration = 0.055
        case .bank: notes = [659, 880, 1319]; duration = 0.085
        case .farkle: notes = [330, 247, 165]; duration = 0.10
        case .win: notes = [523, 659, 784, 1047, 1319]; duration = 0.14
        }
        let rate = 22050
        let noteSamples = Int(duration * Double(rate))
        var pcm = Data()
        for frequency in notes {
            for sample in 0..<noteSamples {
                let t = Double(sample) / Double(rate)
                let envelope = min(1, t / 0.004) * max(0, 1 - Double(sample) / Double(noteSamples))
                let fundamental = sin(2 * .pi * frequency * t)
                let harmonic = 0.22 * sin(4 * .pi * frequency * t)
                var value = Int16((fundamental + harmonic) * envelope * 16000).littleEndian
                withUnsafeBytes(of: &value) { pcm.append(contentsOf: $0) }
            }
        }
        var wave = Data()
        func word(_ value: UInt16) {
            var value = value.littleEndian
            withUnsafeBytes(of: &value) { wave.append(contentsOf: $0) }
        }
        func dword(_ value: UInt32) {
            var value = value.littleEndian
            withUnsafeBytes(of: &value) { wave.append(contentsOf: $0) }
        }
        wave.append(contentsOf: "RIFF".utf8); dword(UInt32(36 + pcm.count))
        wave.append(contentsOf: "WAVEfmt ".utf8); dword(16)
        word(1); word(1); dword(UInt32(rate)); dword(UInt32(rate * 2)); word(2); word(16)
        wave.append(contentsOf: "data".utf8); dword(UInt32(pcm.count)); wave.append(pcm)
        return wave
    }
}
