# What The Farkle

A native SwiftUI scorekeeper for a physical game of Farkle. Bring six dice and a few friends; the app handles the scores, turns, and bragging rights.

## The woodland arcade

The design keeps the original Daydream pixel lettering, green landscapes, and rotating celebration videos, with a shared forest / mint / cream / gold / coral palette.

- **Set the table:** 2–8 named players and quick (2,500), casual (5,000), or classic (10,000) targets. Tap the decorative dice for a little toss.
- **Keep score:** player-colored dice, animated score counters, progress tracks, and a crown for the lead. Larger groups scroll to the active player.
- **Bank or bust:** raised number keys, additive +50/+100/+500 shortcuts, digit backspace, and the original 00/50 suffix keys. Banking has a pixel burst; a Farkle has its own feedback. Both are undoable.
- **Make some noise:** original, locally synthesized cues for taps, dice, banking, Farkles, and victory, paired with haptics. The speaker button remembers mute, and audio respects the silent switch and mixes with music.
- **Take a victory lap:** existing landscape videos, a finite confetti burst, final standings, and a same-crew rematch.
- **Play comfortably:** VoiceOver labels, scalable text, scrollable layouts, and Reduce Motion support. Reduced motion disables dice movement, score particles, confetti, and victory video playback.

This is a companion to real dice, not a virtual dice game. The scoring guide preserves this app’s existing house-rule values; agree on combinations before playing.

## Build

Open `FarkleForge.xcodeproj` in Xcode, select an iPhone or simulator, and run. The current project targets iOS 26 and requires a compatible Xcode installation.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project FarkleForge.xcodeproj -scheme FarkleForge \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/FarkleForge-build CODE_SIGNING_ALLOWED=NO build
```

## Scoring tests

A lightweight Swift package runs the shared scoring model on macOS, independently of the app UI:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --scratch-path /tmp/farkle-tests
```

Tests cover bank/undo, Farkle/undo, every opponent’s final turn, undoing target crossings and winning turns, rematch reset, and invalid bank entries. Tests use in-memory players and do not modify saved player files.

## Code map

- `Views/Components/ArcadeTheme.swift`: palette, type, tactile buttons, dice, finite particles.
- `Models/ArcadeFeedback.swift`: synthesized sound and haptics.
- `Views/StartGameView.swift`: setup.
- `Views/ContentView.swift`: table, turn handoffs, undo, and game lifecycle.
- `Views/ScoreInputView.swift`: score console.
- `Views/Components/CelebrationView.swift`: victory and final standings.
- `Models/GameState.swift`: scoring, final round, undo snapshots, and rematches.

Player names persist using the existing local player file. Live game recovery across app termination is not implemented. Haptic feel and sound balance should be checked on a physical iPhone before shipping.
