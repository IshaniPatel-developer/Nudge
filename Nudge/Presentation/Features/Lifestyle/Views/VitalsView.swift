import SwiftUI
import Charts

public struct VitalsView: View {
    @StateObject private var viewModel: VitalsViewModel
    @EnvironmentObject private var router: AppRouter
    
    @State private var selectedTab = 0 // 0 = Today, 1 = 7 Days
    @State private var showInputSheet = false
    @State private var activeMetric: LifestyleMetric = .water
    
    public init(viewModel: VitalsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AppColors.darkBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Title
                    Text("Lifestyle & Vitals")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Custom Segmented Control matching Figma
                    HStack(spacing: 0) {
                        Button(action: { selectedTab = 0 }) {
                            Text("Today")
                                .font(AppTypography.bodySemibold)
                                .foregroundColor(selectedTab == 0 ? .white : AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTab == 0 ? AppColors.brandBlue : Color.clear)
                                )
                        }
                        
                        Button(action: { selectedTab = 1 }) {
                            Text("7 Days")
                                .font(AppTypography.bodySemibold)
                                .foregroundColor(selectedTab == 1 ? .white : AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTab == 1 ? AppColors.brandBlue : Color.clear)
                                )
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(14)
                    .padding(.horizontal)
                    
                    switch viewModel.loadingState {
                    case .loading:
                        LoadingView(message: "Compiling lifestyle telemetry...")
                            .frame(maxHeight: .infinity)
                    case .success:
                        // Three modular vital cards
                        VStack(spacing: 16) {
                            VitalsCard(
                                metric: .water,
                                currentValue: viewModel.waterToday,
                                trendPoints: viewModel.waterTrend,
                                isWeeklyMode: selectedTab == 1,
                                onEdit: {
                                    activeMetric = .water
                                    showInputSheet = true
                                }
                            )
                            
                            VitalsCard(
                                metric: .steps,
                                currentValue: viewModel.stepsToday,
                                trendPoints: viewModel.stepsTrend,
                                isWeeklyMode: selectedTab == 1,
                                onEdit: {
                                    activeMetric = .steps
                                    showInputSheet = true
                                }
                            )
                            
                            VitalsCard(
                                metric: .weight,
                                currentValue: viewModel.weightToday,
                                trendPoints: viewModel.weightTrend,
                                isWeeklyMode: selectedTab == 1,
                                onEdit: {
                                    activeMetric = .weight
                                    showInputSheet = true
                                }
                            )
                        }
                        .padding(.horizontal)
                    case .error(let message):
                        ErrorView(message: message) {
                            Task { await viewModel.loadAllData() }
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .task {
            await viewModel.loadAllData()
        }
        .sheet(isPresented: $showInputSheet) {
            MetricInputSheet(metric: activeMetric) { val in
                Task {
                    await viewModel.logValue(val, for: activeMetric)
                }
            }
        }
    }
}

// MARK: - Reusable Vitals Card
struct VitalsCard: View {
    let metric: LifestyleMetric
    let currentValue: Double
    let trendPoints: [DailyTrendPoint]
    let isWeeklyMode: Bool
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                // Icon with metric background gradient
                Image(systemName: metric.iconName)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(LinearGradient(gradient: metric.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                
                Text(metric.title)
                    .font(AppTypography.bodySemibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(fractionString)
                    .font(AppTypography.captionRegular)
                    .foregroundColor(AppColors.textSecondary)
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Thin progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    
                    let value = isWeeklyMode ? averageValue : currentValue
                    let progressFraction = value / metric.dailyTarget
                    Capsule()
                        .fill(LinearGradient(gradient: metric.gradient, startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * max(0.0, min(1.0, progressFraction)))
                }
            }
            .frame(height: 6)
            
            // Mini 7-day bar chart
            VitalsMiniChart(points: trendPoints, gradient: metric.gradient)
                .padding(.top, 6)
        }
        .padding()
        .background(AppColors.darkCardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private var fractionString: String {
        let value = isWeeklyMode ? averageValue : currentValue
        let target = metric.dailyTarget
        
        switch metric {
        case .water:
            let lVal = value / 1000.0
            let lTarget = target / 1000.0
            return String(format: "%.1fL of %.1fL", lVal, lTarget)
        case .steps:
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedVal = numberFormatter.string(from: NSNumber(value: Int(value))) ?? "\(Int(value))"
            let formattedTarget = numberFormatter.string(from: NSNumber(value: Int(target))) ?? "\(Int(target))"
            return "\(formattedVal) of \(formattedTarget)"
        case .weight:
            return String(format: "%.1f kg of %.0f kg", value, target)
        }
    }
    
    private var averageValue: Double {
        guard !trendPoints.isEmpty else { return 0.0 }
        let total = trendPoints.reduce(0.0) { $0 + $1.value }
        return total / Double(trendPoints.count)
    }
}

// MARK: - Reusable Mini Chart Component
struct VitalsMiniChart: View {
    let points: [DailyTrendPoint]
    let gradient: Gradient
    
    var body: some View {
        Chart {
            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                let isLast = index == points.count - 1
                BarMark(
                    x: .value("Day", formatDate(point.date)),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(LinearGradient(gradient: gradient, startPoint: .bottom, endPoint: .top))
                .opacity(isLast ? 1.0 : 0.15) // Enable last, disable previous
                .cornerRadius(4)
            }
        }
        .frame(height: 52)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
