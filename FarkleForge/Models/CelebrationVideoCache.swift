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
        var index = 1

        while true {
            let name = String(format: "\(assetPrefix)%03d", index)
            guard let dataAsset = NSDataAsset(name: name) else { break }

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

            index += 1
        }

        // Already on queue — assign directly, no dispatch needed
        cachedURLs = urls
    }

    /// Returns a random cached URL, never repeating the last one used (unless only one video exists).
    func pickRandom() -> URL? {
        var snapshot: [URL] = []
        queue.sync { snapshot = cachedURLs }

        let valid = snapshot.filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !valid.isEmpty else { return nil }

        let pool = valid.count > 1 ? valid.filter { $0.path != lastUsedPath } : valid
        guard let picked = pool.randomElement() else { return nil }

        lastUsedPath = picked.path
        return picked
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
