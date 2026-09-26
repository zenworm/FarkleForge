import SwiftUI
import AVKit
import AVFoundation

struct CelebrationView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let winnerName: String
    let videoURL: URL?
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            ArcadeBackground(image: "celebrationbg")
            if !reduceMotion {
                LoopingVideoPlayer(url: videoURL)
                    .ignoresSafeArea()
                    .overlay(Arcade.forest.opacity(0.55))
            }
            ScrollView {
                VStack(spacing: 24) {
                    HStack { Spacer(); SoundButton() }
                    Image(systemName: "crown.fill")
                        .font(.system(size: 58)).foregroundStyle(Arcade.gold)
                        .padding(.top, 22)
                    VStack(spacing: 12) {
                        Text("ALL HAIL THE").font(Arcade.display(15))
                        Text("FARKLE\nMASTER").font(Arcade.display(30))
                            .foregroundStyle(Arcade.mint)
                            .multilineTextAlignment(.center)
                        Text(winnerName).font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        Text("A little luck. A lot of bragging rights.")
                            .font(.system(.subheadline, design: .rounded))
                    }
                    VStack(spacing: 0) {
                        HStack {
                            Text("The final tally").font(.system(.headline, design: .rounded))
                            Spacer()
                            Image(systemName: "flag.checkered")
                        }
                        .padding(.bottom, 14)
                        ForEach(Array(gameState.players.sorted { $0.score > $1.score }.enumerated()), id: \.element.id) { index, player in
                            HStack(spacing: 12) {
                                Text("\(index + 1)").font(Arcade.mono(14))
                                    .foregroundStyle(Arcade.muted).frame(width: 22)
                                Text(player.name).font(.system(.body, design: .rounded, weight: .semibold))
                                Spacer()
                                Text(player.score.formatted()).font(Arcade.mono(20))
                            }
                            .foregroundStyle(player.id == gameState.winner?.id ? Arcade.gold : Arcade.cream)
                            .padding(.vertical, 13)
                            .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.07)).frame(height: 1) }
                        }
                    }
                    .padding(20)
                    .background(Arcade.forest.opacity(0.90), in: RoundedRectangle(cornerRadius: 24))
                    Button(action: onDismiss) {
                        HStack {
                            Text("One more game").font(Arcade.display(13))
                            Spacer()
                            Image(systemName: "arrow.clockwise").font(.headline)
                        }
                    }
                    .buttonStyle(ArcadeButtonStyle())
                    Text("Same crew. Clean slate.").font(.system(.caption, design: .rounded))
                        .foregroundStyle(Arcade.muted)
                }
                .padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
            VictoryConfetti()
        }
        .foregroundStyle(Arcade.cream)
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
        player?.isMuted = true

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

