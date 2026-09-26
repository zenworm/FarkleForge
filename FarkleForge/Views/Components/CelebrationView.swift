//
//  CelebrationView.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI
import AVKit
import AVFoundation

struct CelebrationView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let winnerName: String
    let videoURL: URL?
    /// The foggy background the game was played over. The celebration opens on it,
    /// then the fog gives way to the animal, built up pixel by pixel.
    var fogImageName: String? = nil
    let onDismiss: () -> Void
    @State private var showBottomSheet = false
    @State private var showScores = false
    @State private var videoOffset: CGFloat = 0
    @State private var maskProgress: CGFloat = 0
    @State private var revealProgress: Double = 0
    @State private var titleProgress: Double = 0
    @State private var confettiBursts = 0

    private let winnerGreen = Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0)

    private var glassBackground: some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28
            )
            .fill(.ultraThinMaterial)

            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28
            )
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var rankedPlayers: [Player] {
        gameState.players.sorted { $0.score > $1.score }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background image behind video
            Image("celebrationbg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // The fog from the game, until the animal builds up over it
            if let fogImageName {
                Image(fogImageName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(revealProgress < 1 ? 1 : 0)
            }

            // Fullscreen video background, shifts up when bottom sheet appears
            // Gradient mask fades the video at the bottom, revealing the bg image beneath
            ZStack {
                LoopingVideoPlayer(url: videoURL)
                    .ignoresSafeArea()
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.85),
                                .init(color: .black.opacity(1.0 - maskProgress), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: videoOffset)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: videoOffset)
            }
            .mask {
                Rectangle()
                    .scaleEffect(x: 1, y: revealProgress, anchor: .bottom)
                    .ignoresSafeArea()
            }

            VerticalBuildEmitter(progress: revealProgress, duration: 1.1)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            PixelConfetti(bursts: confettiBursts)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Main bottom sheet
            if showBottomSheet && !showScores {
                VStack(spacing: 24) {
                    Text("\(winnerName) is the Farkle Master!")
                        .font(.custom("Daydream", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textRenderer(DropInTextRenderer(progress: titleProgress))
                        .padding(.horizontal, 24)

                    Button(action: {
                        SoundEngine.shared.play(.start)
                        Haptics.soft()
                        videoOffset = 0
                        onDismiss()
                    }) {
                        Text("Let's Farkle again")
                            .font(.custom("Daydream", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(winnerGreen)
                            .cornerRadius(3)
                    }
                    .buttonStyle(SquishButtonStyle())
                    .padding(.horizontal, 24)

                    Button(action: {
                        SoundEngine.shared.play(.tick)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showScores = true
                        }
                    }) {
                        Text("View scores")
                            .font(.custom("Daydream", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 28)
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity)
                .background(glassBackground)
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Scores sheet
            if showScores {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            SoundEngine.shared.play(.tick)
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showScores = false
                            }
                        }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()

                        Text("Final Scores")
                            .font(.custom("Daydream", size: 18))
                            .foregroundColor(.white)

                        Spacer()

                        // Balance the chevron
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 16)

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, 24)

                    // Player rows sorted by score descending
                    VStack(spacing: 0) {
                        ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                            let isWinner = player.name == winnerName
                            HStack(spacing: 10) {
                                if isWinner {
                                    PixelCrown(pixel: 2)
                                }
                                Text(player.name)
                                    .font(.custom("Daydream", size: 16))
                                    .foregroundColor(isWinner ? winnerGreen : .white)
                                Spacer()
                                Text("\(player.score)")
                                    .font(.custom("Daydream", size: 16))
                                    .foregroundColor(isWinner ? winnerGreen : .white)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .modifier(StaggeredAppear(index: index))

                            if player.id != rankedPlayers.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity)
                .background(glassBackground)
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // 1. The fog clears: the animal builds up from the bottom in pixels.
            let revealDelay = reduceMotion ? 0 : 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay) {
                withAnimation(.easeOut(duration: reduceMotion ? 0.3 : 1.1)) {
                    revealProgress = 1
                }
            }
            // 2. Fanfare and confetti the moment it's whole.
            DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay + 0.95) {
                SoundEngine.shared.play(.fanfare)
                SoundEngine.shared.play(.confetti)
                Haptics.success()
                if !reduceMotion { confettiBursts += 1 }
            }
            // 3. Then the crown goes to its owner.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showBottomSheet = true
                    videoOffset = -200
                    maskProgress = 1
                }
                withAnimation(.easeOut(duration: 1.0).delay(0.15)) {
                    titleProgress = 1
                }
            }
        }
    }
}

/// Drops each glyph in on its own slight delay, with a little overshoot.
private struct DropInTextRenderer: TextRenderer, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let glyphs = layout.flatMap { line in line.flatMap { run in run } }
        let count = Double(max(glyphs.count, 1))
        for (index, glyph) in glyphs.enumerated() {
            let start = Double(index) / count * 0.6
            let local = min(max((progress - start) / 0.4, 0), 1)
            // Ease-out-back: lands a hair past its spot and settles.
            let c1 = 1.70158, c3 = c1 + 1
            let eased = 1 + c3 * pow(local - 1, 3) + c1 * pow(local - 1, 2)
            var copy = context
            copy.opacity = local
            copy.translateBy(x: 0, y: (1 - eased) * 22)
            copy.draw(glyph)
        }
    }
}

private struct StaggeredAppear: ViewModifier {
    let index: Int
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(0.12 + Double(index) * 0.06)) {
                    isVisible = true
                }
            }
    }
}

/// Square confetti in crown colors, fired from both bottom corners. Every so often
/// a piece is a tiny crown.
private struct PixelConfetti: View {
    let bursts: Int

    @State private var system = ConfettiSystem()
    @State private var isRunning = false

    var body: some View {
        TimelineView(.animation(paused: !isRunning)) { timeline in
            Canvas { context, size in
                system.update(at: timeline.date, size: size)
                for piece in system.pieces {
                    var copy = context
                    copy.translateBy(x: piece.x, y: piece.y)
                    copy.rotate(by: .radians(piece.angle))
                    // Flutter: pieces flip edge-on as they tumble
                    copy.scaleBy(x: abs(cos(piece.flip)), y: 1)
                    if piece.isCrown {
                        PixelCrown.draw(in: &copy, origin: CGPoint(x: -9, y: -6), pixel: 2)
                    } else {
                        let rect = CGRect(x: -piece.size / 2, y: -piece.size / 2, width: piece.size, height: piece.size)
                        copy.fill(Path(rect), with: .color(piece.color))
                    }
                }
            }
        }
        .onChange(of: bursts) { _, _ in
            system.pendingBursts += 2
            isRunning = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                isRunning = false
            }
        }
    }
}

private final class ConfettiSystem {
    struct Piece {
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var angle: Double
        let spin: Double
        var flip: Double
        let flipRate: Double
        let size: CGFloat
        let color: Color
        let isCrown: Bool
    }

    private(set) var pieces: [Piece] = []
    var pendingBursts = 0
    private var lastUpdate: Date?
    private var nextBurstAt: Date?

    private static let palette: [Color] = [
        Palette.gold, Palette.goldShadow, Palette.ruby, Palette.accent, Palette.leaf, Palette.mist, .white,
    ]

    func update(at date: Date, size: CGSize) {
        let dt = min(lastUpdate.map { date.timeIntervalSince($0) } ?? 0, 1.0 / 20.0)
        lastUpdate = date

        if pendingBursts > 0, date >= (nextBurstAt ?? .distantPast) {
            pendingBursts -= 1
            nextBurstAt = date.addingTimeInterval(0.22)
            emit(size: size)
        }

        for i in pieces.indices {
            pieces[i].vy += 900 * dt
            // Air drag, stronger once falling, so pieces drift down instead of dropping
            let drag = pieces[i].vy > 0 ? 3.2 : 0.9
            pieces[i].vx *= CGFloat(exp(-drag * dt))
            pieces[i].vy *= CGFloat(exp(-drag * 0.8 * dt))
            pieces[i].x += pieces[i].vx * dt + CGFloat(sin(pieces[i].flip)) * 0.6
            pieces[i].y += pieces[i].vy * dt
            pieces[i].angle += pieces[i].spin * dt
            pieces[i].flip += pieces[i].flipRate * dt
        }
        pieces.removeAll { $0.y > size.height + 40 }
    }

    private func emit(size: CGSize) {
        for side in [-1.0, 1.0] {
            let originX = side < 0 ? -10 : size.width + 10
            for _ in 0..<70 {
                let angle = Double.random(in: 55...80) * .pi / 180
                let speed = Double.random(in: 900...1500)
                pieces.append(Piece(
                    x: originX,
                    y: size.height * 0.82,
                    vx: CGFloat(-side * cos(angle) * speed),
                    vy: CGFloat(-sin(angle) * speed),
                    angle: .random(in: 0...(2 * .pi)),
                    spin: .random(in: -9...9),
                    flip: .random(in: 0...(2 * .pi)),
                    flipRate: .random(in: 5...12),
                    size: [5, 6, 7, 8, 9].randomElement()!,
                    color: Self.palette.randomElement()!,
                    isCrown: Int.random(in: 0..<14) == 0
                ))
            }
        }
    }
}

struct LoopingVideoPlayer: UIViewRepresentable {
    let videoURL: URL?

    /// Use a pre-cached URL from CelebrationVideoCache.
    init(url: URL?) {
        self.videoURL = url
    }

    func makeUIView(context: Context) -> LoopingVideoPlayerView {
        let view = LoopingVideoPlayerView()
        if let url = videoURL {
            view.setupVideo(url: url)
        } else {
            // Fallback: load celebration_001 directly if cache missed
            view.setupVideo(name: "celebration_001", type: "mp4")
        }
        return view
    }

    func updateUIView(_ uiView: LoopingVideoPlayerView, context: Context) {
        uiView.updateFrame()
    }

    static func dismantleUIView(_ uiView: LoopingVideoPlayerView, coordinator: ()) {
        // Cleanup if needed
    }
}

class LoopingVideoPlayerView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    private var observer: NSObjectProtocol?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Update frame when view is added to window
        if window != nil {
            setNeedsLayout()
        }
    }
    
    /// Fast path: URL already resolved by CelebrationVideoCache — skips NSDataAsset entirely.
    func setupVideo(url: URL) {
        setupPlayer(with: url)
    }

    /// Fallback path: resolves the asset by name (used when cache missed).
    func setupVideo(name: String, type: String) {
        var url: URL?

        if let dataAsset = NSDataAsset(name: name) {
            let tempFile = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(name).\(type)")
            do {
                if FileManager.default.fileExists(atPath: tempFile.path) {
                    try FileManager.default.removeItem(at: tempFile)
                }
                try dataAsset.data.write(to: tempFile)
                url = tempFile
            } catch {}
        } else if let path = Bundle.main.path(forResource: name, ofType: type) {
            url = URL(fileURLWithPath: path)
        } else if let bundleUrl = Bundle.main.url(forResource: name, withExtension: type) {
            url = bundleUrl
        }

        guard let videoUrl = url,
              FileManager.default.fileExists(atPath: videoUrl.path) else { return }

        setupPlayer(with: videoUrl)
    }

    private func setupPlayer(with videoUrl: URL) {
        // Create player item
        playerItem = AVPlayerItem(url: videoUrl)
        player = AVPlayer(playerItem: playerItem)

        // Create player layer
        playerLayer = AVPlayerLayer(player: player)
        guard let layer = playerLayer else { return }

        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        layer.backgroundColor = UIColor.black.cgColor
        self.layer.addSublayer(layer)

        // Observe player item status
        playerItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)

        // Loop the video
        observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        // Play the video on main thread after a short delay
        DispatchQueue.main.async { [weak self] in
            self?.player?.play()
            #if DEBUG
            print("▶️ Video player play() called")
            #endif
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    #if DEBUG
                    print("✅ Video is ready to play")
                    #endif
                    player?.play()
                case .failed:
                    #if DEBUG
                    print("❌ Video failed to load: \(item.error?.localizedDescription ?? "Unknown error")")
                    #endif
                case .unknown:
                    #if DEBUG
                    print("⏳ Video status unknown")
                    #endif
                @unknown default:
                    break
                }
            }
        }
    }
    
    func updateFrame() {
        // Trigger layout update which will properly position the layer
        setNeedsLayout()
    }
    
    deinit {
        playerItem?.removeObserver(self, forKeyPath: "status")
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
        player?.pause()
    }
}

#Preview {
    CelebrationView(winnerName: "Alice", videoURL: nil, onDismiss: {})
}

