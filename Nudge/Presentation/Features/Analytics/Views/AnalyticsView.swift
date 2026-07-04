import SwiftUI

public struct AnalyticsView: View {
    @StateObject private var viewModel: AnalyticsViewModel
    @EnvironmentObject private var router: AppRouter
    
    public init(viewModel: AnalyticsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Segmented picker to change active metric
                Picker("Metric Selection", selection: $viewModel.selectedMetric) {
                    ForEach(LifestyleMetric.allCases) { metric in
                        Text(metric.title.replacingOccurrences(of: " Intake", with: "").replacingOccurrences(of: "Daily ", with: ""))
                            .tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.selectedMetric) { metric in
                    Task { await viewModel.selectMetric(metric) }
                }
                
                // Content state rendering
                switch viewModel.trendState {
                case .loading:
                    LoadingView(message: "Compiling trend aggregates...")
                        .frame(height: 240)
                case .success(let points):
                    if points.isEmpty {
                        EmptyStateView(
                            systemImage: viewModel.selectedMetric.iconName,
                            title: "No Data Logs",
                            message: "Start logging metric values on the dashboard to populate the 7-day trend chart."
                        )
                        .frame(height: 240)
                    } else {
                        VStack(spacing: 16) {
                            TrendChart(points: points, metric: viewModel.selectedMetric)
                            
                            // Insights cards
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Insight Summary")
                                    .font(AppTypography.bodySemibold)
                                
                                HStack(spacing: 12) {
                                    InsightMetricBox(
                                        title: "Total Completed",
                                        value: formatTotal(points),
                                        unit: viewModel.selectedMetric.unit
                                    )
                                    
                                    InsightMetricBox(
                                        title: "Target Achieved",
                                        value: calculateGoalMetCount(points),
                                        unit: "days"
                                    )
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal)
                    }
                case .error(let message):
                    ErrorView(message: message) {
                        Task { await viewModel.loadTrends() }
                    }
                    .frame(height: 240)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Analytics")
        .task {
            // Sync with Dashboard card selection if navigated from quick tap
            if let targetMetric = router.selectedMetricForAnalytics {
                await viewModel.selectMetric(targetMetric)
                router.selectedMetricForAnalytics = nil
            } else {
                await viewModel.loadTrends()
            }
        }
    }
    
    private func formatTotal(_ points: [DailyTrendPoint]) -> String {
        let total = points.reduce(0.0) { $0 + $1.value }
        return String(format: "%.0f", total)
    }
    
    private func calculateGoalMetCount(_ points: [DailyTrendPoint]) -> String {
        let count = points.filter { $0.value >= $0.target }.count
        return "\(count)/\(points.count)"
    }
}

public struct InsightMetricBox: View {
    private let title: String
    private let value: String
    private let unit: String
    
    public init(title: String, value: String, unit: String) {
        self.title = title
        self.value = value
        self.unit = unit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.captionRegular)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTypography.titleSmall)
                
                Text(unit)
                    .font(AppTypography.captionMedium)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
