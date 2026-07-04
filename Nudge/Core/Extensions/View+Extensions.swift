import SwiftUI

extension View {
    public func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

public struct GlassCardModifier: ViewModifier {
    private let cornerRadius: CGFloat
    private let padding: CGFloat
    
    public init(cornerRadius: CGFloat = 20, padding: CGFloat = 16) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}
