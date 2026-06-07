import SwiftUI

struct GlowDot: View {
    let color: Color
    var diameter: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: diameter * 0.6, height: diameter * 0.6)
                .blur(radius: diameter * 0.4)
            Circle()
                .fill(color)
                .frame(width: diameter, height: diameter)
        }
        .shadow(color: color.opacity(0.6), radius: diameter * 0.4)
    }
}
