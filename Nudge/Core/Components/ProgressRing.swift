import SwiftUI

public struct ProgressRing: View {
    private let progress: Double
    private let gradient: Gradient
    private let iconName: String?
    private let customAssetName: String?
    private let lineWidth: CGFloat
    
    public init(
        progress: Double,
        gradient: Gradient = AppColors.brandGradient,
        iconName: String? = nil,
        customAssetName: String? = nil,
        lineWidth: CGFloat = 10
    ) {
        self.progress = max(0.0, min(1.0, progress))
        self.gradient = gradient
        self.iconName = iconName
        self.customAssetName = customAssetName
        self.lineWidth = lineWidth
    }
    
    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            
            // Foreground progress ring
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            if let asset = customAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(.white)
            } else if let iconName = iconName {
                Image(systemName: iconName)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
            } else {
                Text(String(format: "%.0f%%", progress * 100))
                    .font(AppTypography.bodySemibold)
            }
        }
    }
}
