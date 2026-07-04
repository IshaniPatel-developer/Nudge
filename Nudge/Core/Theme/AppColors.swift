import SwiftUI

public enum AppColors {
    // Brand Colors (aligned with Figma)
    public static let brandBlue = Color(hex: "#4F73F6")
    public static let brandPurple = Color(hex: "#8B5CF6")
    
    // Status Colors
    public static let successGreen = Color(hex: "#10B981")
    public static let errorRed = Color(hex: "#EF4444")
    public static let warningOrange = Color(hex: "#F59E0B")
    
    // Backgrounds & Surfaces (Premium Slate Dark Theme)
    public static let darkBackground = Color(hex: "#0E1012")
    public static let darkCardBackground = Color(hex: "#191B21")
    public static let dividerColor = Color(hex: "#262932")
    
    // Text Labels
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "#8E919A")
    
    // Glassmorphism Spec
    public static let glassBackground = Color.white.opacity(0.04)
    public static let glassBorder = Color.white.opacity(0.08)
    public static let glassShadow = Color.black.opacity(0.2)
    
    // Gradients
    public static let blueGradient = Gradient(colors: [Color(hex: "#4F73F6"), Color(hex: "#6366F1")])
    public static let greenGradient = Gradient(colors: [Color(hex: "#10B981"), Color(hex: "#059669")])
    public static let purpleGradient = Gradient(colors: [Color(hex: "#8B5CF6"), Color(hex: "#7C3AED")])
    
    // Backwards Compatibility Aliases
    public static let brandTeal = brandBlue
    public static let brandIndigo = brandPurple
    public static let background = darkBackground
    public static let secondaryBackground = darkCardBackground
    public static let brandGradient = blueGradient
    public static let indigoGradient = purpleGradient
    public static let alertGradient = blueGradient
}

extension Color {
    public static let emerald = Color(hex: "#10B981")
    public static let teal = Color(hex: "#0D9488")
    
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
}
