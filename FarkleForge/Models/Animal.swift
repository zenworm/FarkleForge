//
//  Animal.swift
//  FarkleForge
//
//  The crowned animals are the heart of the app. Each one owns a celebration video
//  (celebration_NNN), a foggy game background (celebration_NNN_bg) and a portrait
//  (animal_NNN) cropped from the video for the start screen bubbles.
//
//  Adding an animal: drop in the three assets, then add an entry here. Until then
//  the video still plays, it just won't get a bubble or a voice.
//

import SwiftUI

struct Animal: Identifiable, Equatable {
    /// Matches the NNN in the asset names.
    let id: String
    /// Used in farkle jokes: "The frog saw that."
    let species: String
    let voice: AnimalVoice
    /// Where the animal sits in its foggy background, in unit coordinates. The game
    /// background drifts toward this point as someone closes in on the win.
    let focus: UnitPoint
    /// What it says when you poke its bubble on the start screen.
    let lines: [String]

    var portrait: String { "animal_\(id)" }
}

enum AnimalCatalog {
    static let all: [Animal] = [
        Animal(id: "001", species: "frog", voice: .croak, focus: UnitPoint(x: 0.42, y: 0.24),
               lines: ["Ribbit.", "I was a prince once.", "Roll a one. Trust me.", "Hop to it."]),
        Animal(id: "003", species: "fox", voice: .yip, focus: UnitPoint(x: 0.55, y: 0.22),
               lines: ["Yip!", "Feeling lucky?", "Fives are my favorite.", "I'd bank that."]),
        Animal(id: "004", species: "otter", voice: .squeak, focus: UnitPoint(x: 0.6, y: 0.34),
               lines: ["Eee!", "Hold my pebble.", "Six dice. No fear.", "Splash!"]),
        Animal(id: "005", species: "raccoon", voice: .chitter, focus: UnitPoint(x: 0.47, y: 0.2),
               lines: ["Mine now.", "Got any snacks?", "I don't steal dice. Often.", "Chk chk chk."]),
        Animal(id: "006", species: "panther", voice: .purr, focus: UnitPoint(x: 0.43, y: 0.21),
               lines: ["Purrr…", "Bank it. Or don't.", "I only play to win.", "Rawr. Respectfully."]),
    ]

    /// Crowns waiting for an owner: floating hints that more animals are coming.
    static let mysteryCount = 3
    static let mysteryLines = ["???", "Keep rolling…", "Who could it be?", "Coming soon."]

    /// Looks up the animal from a background asset name like "celebration_004_bg".
    static func animal(forBackground name: String?) -> Animal? {
        guard let name else { return nil }
        return all.first { name.hasPrefix("celebration_\($0.id)") }
    }
}
