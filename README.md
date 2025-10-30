# Farkle Score Tracker

A modern iOS app for tracking scores in the dice game Farkle, built with SwiftUI and targeting iOS 17+.

## Features

- **Player Management**: Add and remove players dynamically
- **Turn Tracking**: Clear visual indicator of whose turn it is
- **Calculator-Style Input**: Large, touch-friendly number pad for quick score entry
- **Quick Shortcuts**: Fast buttons for adding common scores (+50, +100)
- **Score Display**: Real-time score updates with highlighted current player
- **Game Reset**: Reset all scores to start a new game

## Project Structure

```
FarkleScoreTracker/
├── FarkleScoreTrackerApp.swift       # App entry point
├── Models/
│   ├── Player.swift                   # Player data model
│   └── GameState.swift                # Game state management (@Observable)
├── Views/
│   ├── ContentView.swift              # Main game screen
│   ├── ScoreInputView.swift           # Calculator-style score input
│   ├── PlayerListView.swift           # Player management sheet
│   └── Components/
│       ├── PlayerRowView.swift        # Individual player display
│       └── CalculatorButton.swift     # Reusable calculator button
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

