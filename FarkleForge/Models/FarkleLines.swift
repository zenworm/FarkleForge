//
//  FarkleLines.swift
//  FarkleForge
//
//  The one-liners that appear when someone farkles. Lines come out of a shuffled bag
//  so nobody sees a repeat until the whole deck has been dealt. Back-to-back farkles
//  by the same player get their own escalating material.
//

import Foundation

struct FarkleLines {
    private static let general = [
        "The dice have spoken.",
        "Bold strategy.",
        "Well, that happened.",
        "Tragic. Beautiful, but tragic.",
        "Zero. Zilch. Nada.",
        "Oof.",
        "Womp womp.",
        "Character building!",
        "That's showbiz, baby.",
        "We'll never speak of this.",
        "The dice gods are laughing.",
        "Plot twist: nothing.",
        "Have you tried rolling better?",
        "Statistically inevitable.",
        "Big nothing energy.",
        "Ah, the classic zero.",
    ]

    private static let named = [
        "{name}, no…",
        "Thoughts and prayers, {name}.",
        "{name} has angered the dice.",
        "Sorry, {name}. Truly.",
        "{name} chose chaos.",
        "Somebody hug {name}.",
    ]

    private static let animal = [
        "The {animal} saw that.",
        "Even the {animal} winced.",
        "The {animal} is not impressed.",
    ]

    private static let twice = [
        "Twice?! Impressive.",
        "Back-to-back farkles!",
        "{name} is on a cold streak.",
    ]

    private static let thrice = [
        "Three in a row. Legendary.",
        "A farkle hat trick!",
        "Someone check {name}'s dice.",
    ]

    private var bag: [String] = []

    /// `streak` is how many farkles in a row this player has now had (1 = just this one).
    mutating func next(name: String, animal: String?, streak: Int) -> String {
        let template: String
        if streak >= 3 {
            template = Self.thrice.randomElement()!
        } else if streak == 2 {
            template = Self.twice.randomElement()!
        } else {
            if bag.isEmpty {
                bag = (Self.general + Self.named + (animal == nil ? [] : Self.animal)).shuffled()
            }
            template = bag.removeFirst()
        }
        return template
            .replacingOccurrences(of: "{name}", with: name)
            .replacingOccurrences(of: "{animal}", with: animal ?? "frog")
    }
}
