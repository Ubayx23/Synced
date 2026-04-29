import SwiftUI

extension Font {
    static func synDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func synText(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func synMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

struct EyebrowText: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.synText(11, weight: .semibold))
            .tracking(2.0)
            .textCase(.uppercase)
    }
}
