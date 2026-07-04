import SwiftUI

public struct EmptyStateView: View {
    private let systemImage: String
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?
    
    public init(
        systemImage: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            Text(title)
                .font(AppTypography.titleSmall)
                .foregroundColor(.primary)
            
            Text(message)
                .font(AppTypography.bodyRegular)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.bodySemibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(AppColors.brandTeal)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
}
