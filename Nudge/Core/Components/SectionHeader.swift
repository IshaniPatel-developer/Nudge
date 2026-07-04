import SwiftUI

public struct SectionHeader: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?
    
    public init(title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.titleSmall)
                .foregroundColor(.primary)
            Spacer()
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.callout)
                        .foregroundColor(.teal)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}
