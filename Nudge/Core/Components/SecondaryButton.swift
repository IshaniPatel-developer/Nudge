import SwiftUI

public struct SecondaryButton: View {
    private let title: String
    private let iconName: String?
    private let action: () -> Void
    
    public init(title: String, iconName: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.iconName = iconName
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                }
                Text(title)
                    .font(AppTypography.bodySemibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.primary)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    .background(Color.primary.opacity(0.02))
            )
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
