import CoreText
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct ForgeTheme {
    private static let appFontName = "BebasNeue-Regular"
    private static let appFontFileName = "BebasNeue-Regular"

    // MARK: - Colors
    static let background   = Color(light: "ffffff", dark: "0a0a0a")
    static let surface      = Color(light: "f5f5f5", dark: "141414")
    static let surface2     = Color(light: "ebebeb", dark: "1e1e1e")
    static let textPrimary  = Color(light: "000000", dark: "ffffff")
    static let textMuted    = Color(light: "888888", dark: "555555")
    static let border       = Color(light: Color.black.opacity(0.1), dark: Color.white.opacity(0.07))

    // MARK: - Accent colors per goal
    static let accentBulk   = Color(hex: "0a84ff")  // iOS System Blue
    static let accentCut    = Color(hex: "00d4ff")  // Bright Cyan Blue
    static let accentRecomp = Color(hex: "5e5ce6")  // Electric Blue

    // MARK: - Weekday header symbols
    // Ordering matters — use the variant that matches the grid's first weekday.
    static let weekdaySymbolsSundayFirst = ["S", "M", "T", "W", "T", "F", "S"]
    static let weekdaySymbolsMondayFirst = ["M", "T", "W", "T", "F", "S", "S"]

    // MARK: - Day colors
    static let dayColors: [Color] = [
        Color(hex: "0a84ff"),  // iOS Blue
        Color(hex: "64b5f6"),  // Light Blue
        Color(hex: "5e5ce6"),  // Electric Blue
        Color(hex: "4a90e2"),  // Sky Blue
        Color(hex: "440aff"),  // Deep Purple-Blue
        Color(hex: "0066cc"),  // Dark Blue
        Color(hex: "1e88e5"),  // Medium Blue
    ]

    // MARK: - Typography
    static func bebas(_ size: CGFloat) -> Font {
        .custom(appFontName, size: size)
    }

    static func nunito(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(appFontName, size: size).weight(weight)
    }

    static func registerFonts() {
        guard let fontURL = Bundle.main.url(forResource: appFontFileName, withExtension: "ttf") else {
            return
        }

        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    // Adaptive color for light and dark modes
    init(light: String, dark: String) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
        #else
        self.init(hex: light)
        #endif
    }
    
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
        #else
        self = light
        #endif
    }
}
// MARK: - View Extensions
extension View {
    /// Adds a tap gesture to dismiss the keyboard when tapping anywhere on the view
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            #if canImport(UIKit)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            #endif
        }
    }
}

