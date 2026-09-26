import SwiftUI

struct CalculatorButton: View {
    let title: String
    var foregroundColor: Color = Arcade.cream
    let action: () -> Void

    var body: some View {
        Button {
            action()
            ArcadeFeedback.shared.play(.tap)
        } label: {
            Text(title).font(Arcade.mono(26))
        }
        .buttonStyle(ArcadeButtonStyle(fill: Arcade.panel, ink: foregroundColor, height: 50))
    }
}
