//
//  CelebrationVideoCache.swift
//  FarkleScoreTracker
//

import Foundation
import UIKit
import SwiftUI

class CelebrationVideoCache {
    private var cachedURLs: [URL] = []
    private var lastUsedPath: String? = nil

    /// A shuffled "deck" of backgrounds still to be shown this cycle. Each new game
    /// deals one off the top; when it empties, a fresh random order is dealt. This
    /// guarantees every background is shown once before any repeats.
    private var shuffleBag: [URL] = []

    private let queue = DispatchQueue(label: "com.farkleforge.videocache", qos: .utility)
    private let assetPrefix = "celebration_"
    private let fileExtension = "mp4"

    init() {
        prime()
    }

    /// Discovers all celebration_NNN assets and writes them to temp files on a background queue.
    private func prime() {
        queue.async { [weak self] in
            self?.loadAssets()
        }
    }

    private func loadAssets() {
        var urls: [URL] = []

        for index in 1..<100 {
            let name = String(format: "\(assetPrefix)%03d", index)
            guard let dataAsset = NSDataAsset(name: name) else { continue }

            let tempFile = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(name).\(fileExtension)")

            do {
                if FileManager.default.fileExists(atPath: tempFile.path) {
                    try FileManager.default.removeItem(at: tempFile)
                }
                try dataAsset.data.write(to: tempFile)
                urls.append(tempFile)
            } catch {
                // Asset found but write failed — skip it and keep probing
            }
        }

        // Already on queue — assign directly, no dispatch needed
        cachedURLs = urls
    }

    /// Deals the next unique background for a new game, cycling through every
    /// available background (in a fresh random order) before any repeats.
    /// Returns the pre-cached URL and the asset name, which matches the corresponding image asset.
    func selectForNewGame() -> (url: URL?, name: String?) {
        var snapshot: [URL] = []
        queue.sync { snapshot = cachedURLs }

        let valid = snapshot.filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !valid.isEmpty else { return (nil, nil) }

        // Drop any staged picks whose assets have gone away since the bag was dealt.
        let validPaths = Set(valid.map { $0.path })
        shuffleBag.removeAll { !validPaths.contains($0.path) }

        // Bag exhausted (or first run) — deal a fresh, fully shuffled cycle.
        if shuffleBag.isEmpty {
            shuffleBag = valid.shuffled()
            // Don't let a reshuffle repeat the background that just ended the last cycle.
            if valid.count > 1, shuffleBag.first?.path == lastUsedPath {
                shuffleBag.append(shuffleBag.removeFirst())
            }
        }

        let picked = shuffleBag.removeFirst()
        lastUsedPath = picked.path
        let name = picked.deletingPathExtension().lastPathComponent + "_bg"
        return (picked, name)
    }

    deinit {
        for url in cachedURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

private struct VideoCacheKey: EnvironmentKey {
    static let defaultValue = CelebrationVideoCache()
}

extension EnvironmentValues {
    var videoCache: CelebrationVideoCache {
        get { self[VideoCacheKey.self] }
        set { self[VideoCacheKey.self] = newValue }
    }
}
