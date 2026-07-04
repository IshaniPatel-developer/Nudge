import SwiftUI

public enum AppTypography {

    // MARK: - Inter font helpers
    // PostScript names for each Inter weight
    private enum Inter {
        static let regular  = "Inter-Regular"
        static let medium   = "Inter-Medium"
        static let semiBold = "Inter-SemiBold"
        static let bold     = "Inter-Bold"
    }

    // Convenience: returns Inter if registered, falls back to system rounded
    private static func inter(_ name: String, size: CGFloat) -> Font {
        let font = UIFont(name: name, size: size)
        if font != nil {
            return Font.custom(name, size: size)
        }
        // Fallback — font not bundled yet
        return Font.system(size: size, design: .rounded)
    }

    // MARK: - Text styles
    public static let titleLarge   = inter(Inter.bold,     size: 34)
    public static let titleMedium  = inter(Inter.bold,     size: 28)
    public static let titleSmall   = inter(Inter.semiBold, size: 20)
    public static let bodySemibold = inter(Inter.semiBold, size: 16)
    public static let bodyRegular  = inter(Inter.regular,  size: 16)
    public static let callout      = inter(Inter.medium,   size: 15)
    public static let captionMedium = inter(Inter.medium,  size: 13)
    public static let captionRegular = inter(Inter.regular, size: 13)

    // Countdown uses monospaced — keep system for digit alignment
    public static let countdown = Font.system(.largeTitle, design: .monospaced).weight(.black)
}
