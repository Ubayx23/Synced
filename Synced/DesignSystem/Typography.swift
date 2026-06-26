import SwiftUI

extension Font {
    static func synDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom(GeistFont.sans(weight), size: size)
    }
    static func synText(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(GeistFont.sans(weight), size: size)
    }
    static func synMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(GeistFont.mono(weight), size: size)
    }
}

/// Maps a SwiftUI weight to a bundled Geist PostScript name. The static faces
/// ship in Resources/Fonts and register via UIAppFonts, so they are available
/// at first render (no flash of unstyled text) and never fall back to SF Pro.
/// PostScript names were verified directly from the font files via CoreGraphics.
private enum GeistFont {
    static func sans(_ weight: Font.Weight) -> String {
        switch weight {
        case .black, .heavy, .bold: return "Geist-Bold"
        case .semibold:             return "Geist-SemiBold"
        case .medium:               return "Geist-Medium"
        default:                    return "Geist-Regular"
        }
    }

    static func mono(_ weight: Font.Weight) -> String {
        switch weight {
        case .black, .heavy, .bold: return "GeistMono-Bold"
        case .semibold:             return "GeistMono-SemiBold"
        case .medium:               return "GeistMono-Medium"
        default:                    return "GeistMono-Regular"
        }
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
