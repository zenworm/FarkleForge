// swift-tools-version: 5.9
import PackageDescription

// A small macOS harness for the shared scoring engine; the app still builds in Xcode.
let package = Package(
    name: "FarkleScoring",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "FarkleScoring", path: "FarkleForge/Models",
                exclude: ["ArcadeFeedback.swift", "CelebrationVideoCache.swift"],
                sources: ["Player.swift", "GameState.swift", "PlayerPersistence.swift"]),
        .testTarget(name: "FarkleScoringTests", dependencies: ["FarkleScoring"], path: "Tests")
    ]
)
