# Farkle Score Tracker

A modern iOS app for tracking scores in the dice game Farkle, built with SwiftUI and targeting iOS 17+.

## Features

- **Player Management**: Add and remove players dynamically
- **Turn Tracking**: Clear visual indicator of whose turn it is
- **Calculator-Style Input**: Large, touch-friendly number pad for quick score entry
- **Quick Shortcuts**: Fast buttons for adding common scores (+50, +100)
- **Score Display**: Real-time score updates with highlighted current player
- **Game Reset**: Reset all scores to start a new game

## Design Notes

The app is about the animals, so the UI stays minimal and the motion, sound and
copy carry the personality.

- **The crown is the prize.** Every animal wears one. A pixel crown sits on the
  current leader's row and hops when the lead changes; at the end the fog clears
  to reveal the crowned animal.
- **The leader's progress is the whole game's progress bar.** As someone closes
  in on the target, the foggy background slowly leans toward the animal hiding in it.
- **Everything has a sound, and every sound is synthesized** (`Sound/Synth.swift`):
  warm chiptune voices, no audio files. The keypad is a pentatonic scale, so
  typing a score plays a little tune. Farkles rotate through five comedy sounds.
  Sounds respect the silent switch and can be turned off from the menu.
- **Farkles are an event.** Red edges, a very quick rattle, and a one-liner
  (some personal, some escalating on back-to-back farkles). Nothing blocks the next turn.
- **Motion is quick and springy, never abrupt**, and Reduce Motion is respected.

In Debug builds the menu has a **Sound lab** for auditioning every sound, and
launch arguments drive the game for recording: `-demo start|bank|farkle|final|win`.

## Adding an Animal

1. Add `celebration_NNN` (video data set) and `celebration_NNN_bg` (foggy background).
2. Add `animal_NNN`, a square portrait cropped from the video, for the start screen bubble.
3. Add an entry to `AnimalCatalog` in `Models/Animal.swift` (species, voice, lines,
   and where it sits in the fog).

## Project Structure

```
FarkleScoreTracker/
├── FarkleScoreTrackerApp.swift       # App entry point
├── Models/
│   ├── Player.swift                   # Player data model
│   ├── GameState.swift                # Game state management (@Observable)
│   ├── Animal.swift                   # The crowned animals: voices, lines, fog focus
│   └── FarkleLines.swift              # One-liners for farkles
├── Sound/
│   ├── Synth.swift                    # Every sound, synthesized from code
│   └── SoundEngine.swift              # Playback pool + haptics
├── Views/
│   ├── StartGameView.swift            # Setup sentence + floating animal bubbles
│   ├── ContentView.swift              # Main game screen and its big moments
│   ├── ScoreInputView.swift           # Calculator-style score input
│   └── Components/
│       ├── PlayerRowView.swift        # Player row: progress bar, crown, rolling score
│       ├── CalculatorButton.swift     # Musical keypad button
│       ├── AnimalBubbleField.swift    # Start screen bubble physics
│       ├── GameMoments.swift          # Farkle vignette, shake, stickers
│       ├── CelebrationView.swift      # Fog-to-animal reveal, confetti
│       └── PixelCrown.swift           # The crown, drawn pixel by pixel
└── Assets.xcassets/                   # App icons and colors
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## How to Build

1. Open `FarkleScoreTracker.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press `Cmd+R` to build and run

## Usage

1. **Add Players**: Tap the people icon in the top right to add players
2. **Enter Scores**: Use the calculator-style interface to enter scores
   - Tap numbers to build your score
   - Use +50 or +100 for quick additions
   - Tap "Add to Score" to submit
3. **Turn Management**: The app automatically advances to the next player after each score entry
4. **Reset Game**: Tap the reset icon in the top left to reset all scores to 0

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **@Observable**: iOS 17+ observation framework for state management
- **MVVM Pattern**: Clear separation between views and business logic
- Portrait-only orientation for focused gameplay

## License

This project is open source and available for personal use.

