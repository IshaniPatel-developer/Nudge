import SwiftUI
import Charts

public struct TrendChart: View {
    private let points: [DailyTrendPoint]
    private let metric: LifestyleMetric
    
    public init(points: [DailyTrendPoint], metric: LifestyleMetric) {
        self.points = points
        self.metric = metric
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("7-Day Historical Trend")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(.secondary)
                    
                    Text("Daily Average: \(formatAverage()) \(metric.unit)")
                        .font(AppTypography.titleSmall)
                }
                Spacer()
            }
            
            Chart {
                ForEach(points) { point in
                    BarMark(
                        x: .value("Day", formatDate(point.date)),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(LinearGradient(gradient: metric.gradient, startPoint: .bottom, endPoint: .top))
                    .cornerRadius(4)
                }
                
                RuleMark(
                    y: .value("Daily Target", metric.dailyTarget)
                )
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                .foregroundStyle(Color.indigo.opacity(0.8))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Goal (\(Int(metric.dailyTarget)))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.indigo)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks()
            }
        }
        .glassCard()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // "Mon", "Tue" etc.
        return formatter.string(from: date)
    }
    
    private func formatAverage() -> String {
        guard !points.isEmpty else { return "0" }
        let total = points.reduce(0.0) { $0 + $1.value }
        let average = total / Double(points.count)
        return String(format: "%.0f", average)
    }
}
