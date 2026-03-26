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
    let winnerName: String
    let videoURL: URL?
    let onDismiss: () -> Void
    @State private var showBottomSheet = false
    @State private var showScores = false

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

    var body: some View {
        ZStack(alignment: .bottom) {
            // Fullscreen video background
            LoopingVideoPlayer(url: videoURL)
                .ignoresSafeArea()

            // Main bottom sheet
            if showBottomSheet && !showScores {
                VStack(spacing: 24) {
                    Text("\(winnerName) is the Farkle Master!")
                        .font(.custom("Daydream", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button(action: {
                        gameState.resetScores()
                        onDismiss()
                    }) {
                        Text("Let's Farkle again")
                            .font(.custom("Daydream", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0))
                            .cornerRadius(3)
                    }
                    .padding(.horizontal, 24)

                    Button(action: {
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
                        ForEach(gameState.players.sorted { $0.score > $1.score }) { player in
                            HStack {
                                Text(player.name)
                                    .font(.custom("Daydream", size: 16))
                                    .foregroundColor(player.name == winnerName ? Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0) : .white)
                                Spacer()
                                Text("\(player.score)")
                                    .font(.custom("Daydream", size: 16))
                                    .foregroundColor(player.name == winnerName ? Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0) : .white)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)

                            if player.id != gameState.players.sorted { $0.score > $1.score }.last?.id {
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
            // Show bottom sheet after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showBottomSheet = true
                }
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
        // Make sure layer fills entire screen, including under status bar
        if let layer = playerLayer, let window = window {
            let windowBounds = window.bounds
            
            // Get view's frame in window coordinates
            let viewFrameInWindow = convert(bounds, to: window)
            
            // Calculate offset to position layer at window origin (0,0)
            let offsetX = -viewFrameInWindow.origin.x
            let offsetY = -viewFrameInWindow.origin.y
            
            // Set layer frame to cover entire window
            layer.frame = CGRect(
                x: offsetX,
                y: offsetY,
                width: windowBounds.width,
                height: windowBounds.height
            )
            
            #if DEBUG
            print("📐 Video layer frame: \(layer.frame)")
            print("📐 View bounds: \(bounds)")
            print("📐 View frame in window: \(viewFrameInWindow)")
            print("📐 Window bounds: \(windowBounds)")
            #endif
        } else if let layer = playerLayer {
            // Fallback: use screen bounds
            let screenBounds = UIScreen.main.bounds
            layer.frame = screenBounds
            #if DEBUG
            print("📐 Video layer frame (fallback to screen): \(screenBounds)")
            #endif
        }
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
        if let window = window {
            layer.frame = window.bounds
        } else {
            layer.frame = UIScreen.main.bounds
        }
        layer.backgroundColor = UIColor.black.cgColor
        self.layer.addSublayer(layer)
        layer.masksToBounds = false
        self.layer.masksToBounds = false

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

