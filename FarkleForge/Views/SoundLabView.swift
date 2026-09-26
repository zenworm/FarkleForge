//
//  SoundLabView.swift
//  FarkleForge
//
//  Debug-only board for auditioning every synthesized sound on a device. Tweak a
//  recipe in Synth.swift, run, and tap through here.
//

#if DEBUG
import SwiftUI

struct SoundLabView: View {
    private let sections: [(String, [(String, SoundEffect)])] = [
        ("Keypad", (0...9).map { ("\($0)", SoundEffect.key($0)) }
            + [("00", .keyPair("00")), ("50", .keyPair("50")), ("Clear", .clear), ("Nope", .nope)]),
        ("Scoring", [("Coin", .coin), ("Small bank", .fill(from: 0.2, to: 0.25)),
                     ("Big bank", .fill(from: 0.3, to: 0.65)), ("Crown", .crown),
                     ("Final round", .finalRound), ("Undo", .undo)]),
        ("Farkles", [("Sad trombone", .farkle(0)), ("Slide whistle", .farkle(1)), ("Boing", .farkle(2)),
                     ("Raspberry", .farkle(3)), ("Game over", .farkle(4))]),
        ("Animals", [("Frog", .voice(.croak)), ("Fox", .voice(.yip)), ("Otter", .voice(.squeak)),
                     ("Raccoon", .voice(.chitter)), ("Panther", .voice(.purr)), ("Mystery", .voice(.mystery))]),
        ("Start & finish", [("Tick", .tick), ("Select", .select), ("Bubble grab", .bubbleGrab),
                            ("Bubble bump", .bubbleBump), ("Start", .start), ("Logo", .logo),
                            ("Fanfare", .fanfare), ("Confetti", .confetti)]),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sections, id: \.0) { title, sounds in
                    Section(title) {
                        ForEach(sounds, id: \.0) { name, effect in
                            Button(name) { SoundEngine.shared.play(effect) }
                        }
                    }
                }
            }
            .navigationTitle("Sound lab")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
