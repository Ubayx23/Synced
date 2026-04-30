import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    /// Accepts 6-character hex strings with optional `#` prefix, e.g. `"#00E5FF"` or `"00E5FF"`.
    init(hex: String, alpha: Double = 1.0) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt32(s, radix: 16) ?? 0
        self.init(hex: v, alpha: alpha)
    }
}

enum SYN {
    static let bg          = Color(hex: 0x0A0A0A)
    static let bgDeep      = Color(hex: 0x050505)
    static let surface     = Color(hex: 0x161618)
    static let surfaceHi   = Color(hex: 0x1F1F23)
    static let border      = Color(hex: 0x2A2A2E)
    static let text        = Color.white
    static let textDim     = Color(hex: 0x8E8E93)
    static let textFaint   = Color(hex: 0x5A5A60)
    static let cyan        = Color(hex: 0x00E5FF)
    static let cyanSoft    = Color(hex: 0x7CE8F5)
    static let red         = Color(hex: 0xFF453A)
    static let amber       = Color(hex: 0xF59E0B)
    static let green       = Color(hex: 0x22C55E)
    static let bronze      = Color(hex: 0xCD7F32)
}

enum Spacing {
    static let xs: CGFloat = 4
    static let s:  CGFloat = 8
    static let m:  CGFloat = 12
    static let md: CGFloat = 16
    static let l:  CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let pageH: CGFloat = 24
}

enum Radius {
    static let button: CGFloat = 14
    static let card:   CGFloat = 16
    static let input:  CGFloat = 14
    static let pill:   CGFloat = 999
}
