import SwiftUI

public struct MetricCard: View {
    private let metric: LifestyleMetric
    private let currentValue: Double
    private let onQuickLog: () -> Void
    private let onTapCard: () -> Void
    
    public init(
        metric: LifestyleMetric,
        currentValue: Double,
        onQuickLog: @escaping () -> Void,
        onTapCard: @escaping () -> Void
    ) {
        self.metric = metric
        self.currentValue = currentValue
        self.onQuickLog = onQuickLog
        self.onTapCard = onTapCard
    }
    
    public var body: some View {
        Button(action: onTapCard) {
            HStack(spacing: 16) {
                // Reusable progress ring
                ProgressRing(
                    progress: currentValue / metric.dailyTarget,
                    gradient: metric.gradient,
                    iconName: metric.iconName,
                    lineWidth: 7
                )
                .frame(width: 52, height: 52)
                
                // Numeric descriptions
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.title)
                        .font(AppTypography.bodySemibold)
                        .foregroundColor(.primary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(formatValue(currentValue))
                            .font(AppTypography.titleSmall)
                            .foregroundColor(.primary)
                        
                        Text("/ \(formatValue(metric.dailyTarget)) \(metric.unit)")
                            .font(AppTypography.captionRegular)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Direct quick logger button
                Button(action: onQuickLog) {
                    Image(systemName: "plus")
                        .font(.body.weight(.bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(LinearGradient(gradient: metric.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .buttonStyle(CardButtonStyle())
    }
    
    private func formatValue(_ value: Double) -> String {
        switch metric {
        case .water:
            return String(format: "%.0f", value)
        case .weight:
            return String(format: "%.1f", value)
        case .steps:
            return String(format: "%.0f", value)
        }
    }
}

public struct CardButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glassCard(cornerRadius: 16, padding: 12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
