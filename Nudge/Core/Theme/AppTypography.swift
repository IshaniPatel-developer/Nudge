import SwiftUI

public enum AppTypography {
    public static let titleLarge = Font.system(.largeTitle, design: .rounded).weight(.bold)
    public static let titleMedium = Font.system(.title, design: .rounded).weight(.bold)
    public static let titleSmall = Font.system(.title3, design: .rounded).weight(.semibold)
    public static let bodySemibold = Font.system(.body, design: .rounded).weight(.semibold)
    public static let bodyRegular = Font.system(.body, design: .default)
    public static let callout = Font.system(.callout, design: .default)
    public static let captionMedium = Font.system(.caption, design: .default).weight(.medium)
    public static let captionRegular = Font.system(.caption, design: .default)
    public static let countdown = Font.system(.largeTitle, design: .monospaced).weight(.black)
}
