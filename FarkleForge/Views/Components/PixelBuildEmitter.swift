//
//  PixelBuildEmitter.swift
//  FarkleForge
//
//  Builds an image up from the bottom, one pixel block at a time. The screen is cut
//  into a grid; each cell pops in along a gently wavy frontier, flashes a brighter
//  version of its own color from the image, then settles into the picture. A few
//  cells shed a sparkle as they land. Used by the game intro and by the celebration,
//  where the fog gives way to the animal.
//
//  Everything is a pure function of elapsed time, so a dropped frame can't leave a
//  gap in the build.
//

import AVFoundation
import SwiftUI

/// Where a build's flash colors come from, so it glows in the picture's own colors.
enum PixelBuildColorSource: Equatable {
    case image(String)
    case video(URL)
    case none
}

struct PixelBuildReveal<Content: View>: View {
    /// The build starts when this becomes true; setting it back to false hides the content again.
    let isRevealed: Bool
    var duration: TimeInterval = 1.0
    var colorSource: PixelBuildColorSource = .none
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate: Date?
    @State private var isComplete = false
    @State private var build = PixelBuild()
    @State private var size: CGSize = .zero

    var body: some View {
        content
            .mask {
                if isComplete {
                    Rectangle()
                } else if let startDate {
                    TimelineView(.animation) { timeline in
                        Canvas { context, size in
                            build.drawMask(in: &context, size: size, elapsed: timeline.date.timeIntervalSince(startDate))
                        }
                    }
                } else {
                    Color.clear
                }
            }
            .overlay {
                if !isComplete, let startDate {
                    TimelineView(.animation) { timeline in
                        Canvas { context, size in
                            build.drawFlashes(in: &context, size: size, elapsed: timeline.date.timeIntervalSince(startDate))
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                size = newSize
            }
            .onAppear {
                if isRevealed { begin() }
            }
            .onChange(of: isRevealed) { _, revealed in
                if revealed {
                    begin()
                } else {
                    startDate = nil
                    isComplete = false
                }
            }
    }

    private func begin() {
        if reduceMotion {
            isComplete = true
            return
        }
        build = PixelBuild(duration: duration)
        let date = Date()
        startDate = date
        isComplete = false

        let build = build
        let source = colorSource
        let aspect = size.height > 0 ? size.width / size.height : 0.46
        Task.detached(priority: .userInitiated) {
            let colors = await PixelBuild.sampleColors(from: source, aspect: aspect)
            await MainActor.run { build.colors = colors }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + build.totalDuration) {
            // Only finish the build we started (a new one may have begun since).
            if startDate == date { isComplete = true }
        }
    }
}

// MARK: - Build

private final class PixelBuild {
    /// Colors sampled from the image on a fixed grid, rows top to bottom.
    struct Swatches {
        static let columns = 48
        static let rows = 104
        var values: [SIMD3<Double>]

        func color(atX x: Double, y: Double) -> SIMD3<Double> {
            let column = min(max(Int(x * Double(Self.columns)), 0), Self.columns - 1)
            let row = min(max(Int(y * Double(Self.rows)), 0), Self.rows - 1)
            return values[row * Self.columns + column]
        }
    }

    struct Sparkle {
        let x: Double
        let y: Double
        let drift: Double
        let rise: Double
        let born: Double
        let life: Double
        let size: Double
        let color: SIMD3<Double>
    }

    let duration: TimeInterval
    var colors: Swatches?

    /// Columns across the screen; cells are square, so rows follow from the height.
    private let columns = 30
    private let pop: Double = 0.12
    private let flashLife: Double = 0.42
    private let sparkleLife: ClosedRange<Double> = 0.5...0.9

    private var layoutSize: CGSize = .zero
    private var rows = 0
    private var cell: CGFloat = 0
    private var times: [Double] = []
    private var rowFirst: [Double] = []
    private var rowLast: [Double] = []
    private var sparkles: [Sparkle] = []

    var totalDuration: TimeInterval { duration + sparkleLife.upperBound }

    init(duration: TimeInterval = 1.0) {
        self.duration = duration
    }

    // MARK: Layout

    private func layout(for size: CGSize) {
        guard size != layoutSize, size.width > 0 else { return }
        layoutSize = size
        cell = size.width / CGFloat(columns)
        rows = Int(ceil(size.height / cell))
        times = Array(repeating: 0, count: rows * columns)
        rowFirst = Array(repeating: .infinity, count: rows)
        rowLast = Array(repeating: 0, count: rows)
        sparkles = []

        let phase = Double.random(in: 0...(2 * .pi))
        for row in 0..<rows {
            // Row 0 is the bottom of the screen.
            let height = Double(row) / Double(max(rows - 1, 1))
            for column in 0..<columns {
                // A soft, rolling wave across the columns keeps the frontier organic;
                // a little per-cell noise breaks it into pixels.
                let c = Double(column)
                let wave = 0.5 + 0.3 * sin(c * 0.42 + phase) + 0.2 * sin(c * 1.13 + phase * 1.7)
                let noise = Self.hash(column, row)
                let jitter = 0.65 * wave + 0.35 * noise
                let time = duration * (0.02 + 0.8 * height + 0.16 * jitter)
                let index = row * columns + column
                times[index] = time
                rowFirst[row] = min(rowFirst[row], time)
                rowLast[row] = max(rowLast[row], time)

                // About one landing in thirty throws off a sparkle.
                if Self.hash(row, column + 101) < 0.035 {
                    sparkles.append(Sparkle(
                        x: (c + 0.5) / Double(columns),
                        y: 1 - (Double(row) + 0.5) / Double(rows),
                        drift: (Self.hash(column + 7, row) - 0.5) * 30,
                        rise: 50 + 90 * Self.hash(row + 3, column),
                        born: time,
                        life: sparkleLife.lowerBound + (sparkleLife.upperBound - sparkleLife.lowerBound) * Self.hash(column, row + 11),
                        size: [0.3, 0.4, 0.5][Int(Self.hash(row, column) * 3) % 3],
                        color: SIMD3(0.92, 1, 0.88)
                    ))
                }
            }
        }
    }

    /// Scale of a cell `age` seconds after it lands: pops from small with a hint of overshoot.
    private func scale(forAge age: Double) -> CGFloat {
        guard age < pop else { return 1 }
        let x = age / pop
        let c1 = 1.4, c3 = c1 + 1
        let eased = 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
        return CGFloat(0.6 + 0.4 * eased)
    }

    private func rect(column: Int, row: Int, size: CGSize, scale: CGFloat) -> CGRect {
        let side = (cell + 0.5) * scale
        let centerX = (CGFloat(column) + 0.5) * cell
        let centerY = size.height - (CGFloat(row) + 0.5) * cell
        return CGRect(x: centerX - side / 2, y: centerY - side / 2, width: side, height: side)
    }

    // MARK: Drawing

    func drawMask(in context: inout GraphicsContext, size: CGSize, elapsed t: Double) {
        layout(for: size)
        var path = Path()
        for row in 0..<rows where rowFirst[row] <= t {
            if rowLast[row] + pop <= t {
                // Whole row is down: one rectangle instead of thirty.
                let top = size.height - CGFloat(row + 1) * cell - 0.5
                path.addRect(CGRect(x: 0, y: top, width: size.width, height: cell + 1))
                continue
            }
            for column in 0..<columns {
                let age = t - times[row * columns + column]
                guard age >= 0 else { continue }
                path.addRect(rect(column: column, row: row, size: size, scale: scale(forAge: age)))
            }
        }
        context.fill(path, with: .color(.black))
    }

    func drawFlashes(in context: inout GraphicsContext, size: CGSize, elapsed t: Double) {
        layout(for: size)
        for row in 0..<rows where rowFirst[row] <= t && rowLast[row] + flashLife > t {
            let y = 1 - (Double(row) + 0.5) / Double(rows)
            for column in 0..<columns {
                let age = t - times[row * columns + column]
                guard age >= 0, age < flashLife else { continue }
                let fade = 1 - age / flashLife
                let base = colors?.color(atX: (Double(column) + 0.5) / Double(columns), y: y) ?? SIMD3(0.57, 0.85, 0.5)
                // The cell's own color, lifted toward light, cooling back into the picture.
                let lift = 0.55 * fade
                let color = base + (SIMD3(1, 1, 1) - base) * lift
                context.fill(
                    Path(rect(column: column, row: row, size: size, scale: scale(forAge: age))),
                    with: .color(Color(red: color.x, green: color.y, blue: color.z).opacity(0.9 * pow(fade, 1.5)))
                )
            }
        }

        for sparkle in sparkles {
            let age = t - sparkle.born
            guard age >= 0, age < sparkle.life else { continue }
            let progress = age / sparkle.life
            let side = cell * CGFloat(sparkle.size)
            let x = CGFloat(sparkle.x) * size.width + CGFloat(sparkle.drift * progress)
            // Rises fast, then floats: ease-out on the climb.
            let y = CGFloat(sparkle.y) * size.height - CGFloat(sparkle.rise * (1 - pow(1 - progress, 2)))
            let color = sparkle.color
            context.fill(
                Path(CGRect(x: x - side / 2, y: y - side / 2, width: side, height: side)),
                with: .color(Color(red: color.x, green: color.y, blue: color.z).opacity(0.85 * (1 - progress)))
            )
        }
    }

    /// Stable pseudo-random value in 0..<1 for a cell, so the same cell always behaves the same.
    private static func hash(_ a: Int, _ b: Int) -> Double {
        var h = UInt64(truncatingIfNeeded: a &* 73856093 ^ b &* 19349663)
        h ^= h >> 33
        h = h &* 0xff51afd7ed558ccd
        h ^= h >> 33
        return Double(h % 10_000) / 10_000
    }

    // MARK: Color sampling

    /// Averages the source image down to a small grid, cropped the way `.scaledToFill()`
    /// crops it on screen.
    static func sampleColors(from source: PixelBuildColorSource, aspect: CGFloat) async -> Swatches? {
        let image: CGImage?
        switch source {
        case .image(let name):
            image = UIImage(named: name)?.cgImage
        case .video(let url):
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            generator.appliesPreferredTrackTransform = true
            image = try? await generator.image(at: .zero).image
        case .none:
            image = nil
        }
        guard let image else { return nil }

        let width = CGFloat(image.width), height = CGFloat(image.height)
        var crop = CGRect(x: 0, y: 0, width: width, height: height)
        if width / height > aspect {
            crop.size.width = height * aspect
            crop.origin.x = (width - crop.width) / 2
        } else {
            crop.size.height = width / aspect
            crop.origin.y = (height - crop.height) / 2
        }
        guard let cropped = image.cropping(to: crop.integral) else { return nil }

        let columns = Swatches.columns, rows = Swatches.rows
        var pixels = [UInt8](repeating: 0, count: columns * rows * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: columns, height: rows, bitsPerComponent: 8,
                bytesPerRow: columns * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.interpolationQuality = .medium
            context.draw(cropped, in: CGRect(x: 0, y: 0, width: columns, height: rows))
            return true
        }
        guard drawn else { return nil }

        // Bitmap memory runs top to bottom.
        let values = (0..<(columns * rows)).map { i in
            SIMD3(Double(pixels[i * 4]), Double(pixels[i * 4 + 1]), Double(pixels[i * 4 + 2])) / 255
        }
        return Swatches(values: values)
    }
}
