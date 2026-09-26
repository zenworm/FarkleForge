import SwiftUI

/// The same small palette follows the table from setup through the victory lap.
enum Arcade {
    static let forest = Color(red: 0.065, green: 0.14, blue: 0.11)
    static let panel = Color(red: 0.12, green: 0.23, blue: 0.18)
    static let mint = Color(red: 0.72, green: 0.94, blue: 0.57)
    static let cream = Color(red: 1, green: 0.95, blue: 0.81)
    static let gold = Color(red: 1, green: 0.83, blue: 0.42)
    static let coral = Color(red: 1, green: 0.50, blue: 0.42)
    static let muted = Color(red: 0.66, green: 0.76, blue: 0.65)
    static let playerColors: [Color] = [mint, gold, Color(red: 0.74, green: 0.70, blue: 0.98), coral, .cyan, .pink, .orange, .white]

    static func display(_ size: CGFloat) -> Font { .custom("Daydream", size: size, relativeTo: .title) }
    static func mono(_ size: CGFloat) -> Font { .custom("GeistMono-Medium", size: size, relativeTo: .body) }
}

struct ArcadeBackground: View {
    var image: String = "startBg"
    var body: some View {
        GeometryReader { geometry in
            Image(image)
                .resizable().scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay(Arcade.forest.opacity(0.73))
                .overlay(LinearGradient(colors: [.clear, Arcade.forest], startPoint: .top, endPoint: .bottom))
        }
        .background(Arcade.forest)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct ArcadeButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var fill: Color = Arcade.mint
    var ink: Color = Arcade.forest
    var height: CGFloat = 54
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(ink)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(fill, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.12)))
            .shadow(color: .black.opacity(0.30), radius: 0, y: configuration.isPressed ? 1 : 5)
            .offset(y: configuration.isPressed ? 4 : 0)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct SoundButton: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    var body: some View {
        Button {
            soundEnabled.toggle()
            if soundEnabled { ArcadeFeedback.shared.play(.tap) }
        } label: {
            Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.06), in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Arcade.cream)
        .accessibilityLabel(soundEnabled ? "Mute sound effects" : "Enable sound effects")
    }
}

struct ArcadeDie: View {
    var face: Int
    var size: CGFloat = 64
    var color: Color = Arcade.cream
    var body: some View {
        Image(systemName: "die.face.\(face).fill")
            .resizable().scaledToFit()
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: size * 0.09)
            .accessibilityHidden(true)
    }
}

struct DiceTable: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var toss = 0
    var body: some View {
        Button {
            toss += 1
            ArcadeFeedback.shared.play(.roll)
        } label: {
            let motionDisabled = reduceMotion
            ZStack {
                Ellipse().fill(.black.opacity(0.16)).frame(width: 220, height: 38).offset(y: 47)
                ArcadeDie(face: toss % 6 + 1, size: 72, color: Arcade.gold)
                    .rotationEffect(.degrees(-19)).offset(x: -69, y: 11)
                ArcadeDie(face: (toss + 4) % 6 + 1, size: 88, color: Arcade.cream)
                    .rotationEffect(.degrees(12)).offset(x: 8, y: -10)
                ArcadeDie(face: (toss + 2) % 6 + 1, size: 59, color: Arcade.mint)
                    .rotationEffect(.degrees(27)).offset(x: 83, y: 22)
                Image(systemName: "sparkle").foregroundStyle(Arcade.gold).offset(x: -114, y: -36)
                Image(systemName: "sparkle").foregroundStyle(Arcade.mint).offset(x: 114, y: -28)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .keyframeAnimator(initialValue: 0.0, trigger: toss) { content, value in
                content.offset(y: motionDisabled ? 0 : value)
            } keyframes: { _ in
                CubicKeyframe(-18, duration: 0.12)
                SpringKeyframe(0, duration: 0.4, spring: .bouncy)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toss decorative dice")
        .accessibilityHint("Just for fun. Roll your physical dice to play.")
    }
}

struct VictoryConfetti: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fly = false
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<32, id: \.self) { index in
                Rectangle()
                    .fill(Arcade.playerColors[index % Arcade.playerColors.count])
                    .frame(width: 6, height: index.isMultiple(of: 2) ? 6 : 12)
                    .rotationEffect(.degrees(fly ? Double(index * 47) : 0))
                    .position(x: geometry.size.width * CGFloat((index * 37) % 100) / 100,
                              y: fly ? geometry.size.height + 20 : -30)
                    .opacity(fly ? 0 : 1)
                    .animation(.easeIn(duration: 2.2 + Double(index % 4) * 0.3).delay(Double(index % 7) * 0.08), value: fly)
            }
        }
        .opacity(reduceMotion ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { if !reduceMotion { fly = true } }
    }
}

/// A finite burst from the banked score, rather than a continuously running emitter.
struct ScoreSparkles: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var trigger: Int
    var color: Color
    @State private var burst = 0

    var body: some View {
        let motionDisabled = reduceMotion
        Color.clear
            .frame(width: 70, height: 50)
            .keyframeAnimator(initialValue: 0.0, trigger: burst) { _, phase in
                ZStack {
                    ForEach(0..<10, id: \.self) { index in
                        let angle = Double(index) * .pi / 5
                        Rectangle().fill(index.isMultiple(of: 3) ? Arcade.gold : color)
                            .frame(width: 4, height: 4)
                            .rotationEffect(.degrees(phase * 160))
                            .offset(x: cos(angle) * phase * 55, y: sin(angle) * phase * 40)
                            .opacity(motionDisabled || trigger == 0 ? 0 : sin(phase * .pi))
                    }
                }
                .frame(width: 70, height: 50)
            } keyframes: { _ in
                LinearKeyframe(0, duration: 0.01)
                CubicKeyframe(1, duration: 0.65)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: trigger) { oldValue, newValue in
                if newValue > oldValue { burst += 1 }
            }
    }
}
