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
    let onDismiss: () -> Void
    @State private var showBottomSheet = false
    
    var body: some View {
        ZStack {
            // Fullscreen video background
            LoopingVideoPlayer(videoName: "farklemaster", videoType: "mp4")
            
            // Bottom sheet
            VStack {
                Spacer()
                
                if showBottomSheet {
                    VStack(spacing: 24) {
                        Text("\(winnerName) is the Farkle Master!")
                            .font(.custom("Daydream", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
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
                                .background(Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0)) // bankColor
                                .cornerRadius(3)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0), lineWidth: 2)
                                )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 27/255.0, green: 41/255.0, blue: 24/255.0)) // containerColor
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
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
    let videoName: String
    let videoType: String
    
    func makeUIView(context: Context) -> LoopingVideoPlayerView {
        let view = LoopingVideoPlayerView()
        view.setupVideo(name: videoName, type: videoType)
        return view
    }
    
    func updateUIView(_ uiView: LoopingVideoPlayerView, context: Context) {
        // Update layer frame when view size changes
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
    
    func setupVideo(name: String, type: String) {
        var url: URL?
        
        // Try loading from Assets.xcassets (data asset)
        if let dataAsset = NSDataAsset(name: name) {
            // Create a temporary file to play the video
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent("\(name).\(type)")
            
            do {
                // Remove existing file if present
                if FileManager.default.fileExists(atPath: tempFile.path) {
                    try FileManager.default.removeItem(at: tempFile)
                }
                
                try dataAsset.data.write(to: tempFile)
                url = tempFile
                #if DEBUG
                print("✅ Loaded video from Assets: \(name), size: \(dataAsset.data.count) bytes")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to write video data to temp file: \(error)")
                #endif
            }
        }
        // Fallback: Try bundle path
        else if let path = Bundle.main.path(forResource: name, ofType: type) {
            url = URL(fileURLWithPath: path)
            #if DEBUG
            print("✅ Found video at bundle path: \(path)")
            #endif
        }
        // Fallback: Try bundle URL
        else if let bundleUrl = Bundle.main.url(forResource: name, withExtension: type) {
            url = bundleUrl
            #if DEBUG
            print("✅ Found video at bundle URL: \(bundleUrl)")
            #endif
        }
        else {
            #if DEBUG
            print("❌ Video file not found: \(name).\(type)")
            #endif
            return
        }
        
        guard let videoUrl = url else {
            #if DEBUG
            print("❌ Failed to create URL for video")
            #endif
            return
        }
        
        // Check if file exists and is readable
        guard FileManager.default.fileExists(atPath: videoUrl.path) else {
            #if DEBUG
            print("❌ Video file does not exist at path: \(videoUrl.path)")
            #endif
            return
        }
        
        #if DEBUG
        print("📹 Video URL: \(videoUrl)")
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: videoUrl.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("📹 File size: \(fileSize) bytes")
        } catch {
            print("📹 Could not get file size: \(error)")
        }
        #endif
        
        // Create player item
        playerItem = AVPlayerItem(url: videoUrl)
        player = AVPlayer(playerItem: playerItem)
        
        // Create player layer
        playerLayer = AVPlayerLayer(player: player)
        guard let layer = playerLayer else { return }
        
        layer.videoGravity = .resizeAspectFill
        // Use screen bounds initially, will be updated in layoutSubviews
        if let window = window {
            layer.frame = window.bounds
        } else {
            layer.frame = UIScreen.main.bounds
        }
        layer.backgroundColor = UIColor.black.cgColor
        self.layer.addSublayer(layer)
        
        // Ensure layer fills the entire view and extends beyond
        layer.masksToBounds = false
        self.layer.masksToBounds = false
        
        #if DEBUG
        print("📐 Initial layer frame (screen): \(layer.frame)")
        print("📐 View bounds: \(bounds)")
        #endif
        
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
    CelebrationView(winnerName: "Alice", onDismiss: {})
}

