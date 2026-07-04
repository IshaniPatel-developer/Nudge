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
                    // Header
                    Text("Lifestyle & Vitals")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)

                    // Segmented Control
                    HStack(spacing: 0) {
                        ForEach(["Today", "7 Days"], id: \.self) { label in
                            let isSelected = (label == "Today") ? selectedTab == 0 : selectedTab == 1
                            Button(action: { selectedTab = (label == "Today") ? 0 : 1 }) {
                                Text(label)
                                    .font(AppTypography.bodySemibold)
                                    .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isSelected ? AppColors.brandBlue : Color.clear)
                                    )
                            }
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
                        VStack(spacing: 16) {
                            VitalsCard(
                                metric: .water,
                                currentValue: viewModel.waterToday,
                                trendPoints: viewModel.waterTrend,
                                isWeeklyMode: selectedTab == 1,
                                onEdit: { activeMetric = .water; showInputSheet = true }
                            )

                            VitalsCard(
                                metric: .steps,
                                currentValue: viewModel.stepsToday,
                                trendPoints: viewModel.stepsTrend,
                                isWeeklyMode: selectedTab == 1,
                                onEdit: { activeMetric = .steps; showInputSheet = true }
                            )

                            VitalsCard(
                                metric: .weight,
                                currentValue: viewModel.weightToday,
                                trendPoints: viewModel.weightTrend,
                                isWeeklyMode: selectedTab == 1,
                                onEdit: { activeMetric = .weight; showInputSheet = true }
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
                .padding(.bottom, 100)
            }
        }
        .task {
            await viewModel.loadAllData()
        }
        .sheet(isPresented: $showInputSheet) {
            MetricInputSheet(metric: activeMetric) { val in
                Task { await viewModel.logValue(val, for: activeMetric) }
            }
        }
    }
}

// MARK: - Vitals Card
struct VitalsCard: View {
    let metric: LifestyleMetric
    let currentValue: Double
    let trendPoints: [DailyTrendPoint]
    let isWeeklyMode: Bool
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack(spacing: 8) {
                Image(metric.customAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text(metric.title)
                    .font(AppTypography.bodySemibold)
                    .foregroundColor(.white)

                Spacer()

                // Value + pencil icon (tappable)
                Button(action: onEdit) {
                    HStack(spacing: 6) {
                        Text(fractionString)
                            .font(AppTypography.captionRegular)
                            .foregroundColor(AppColors.textSecondary)

                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }

            // Progress bar (daily target)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))

                    let displayValue = isWeeklyMode ? averageValue : currentValue
                    // For weight: progress is how close to goal, otherwise raw / target
                    let fraction = progressFraction(for: displayValue)
                    Capsule()
                        .fill(LinearGradient(gradient: metric.gradient, startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * fraction)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: fraction)
                }
            }
            .frame(height: 6)

            // 7-day trend bar chart
            VStack(alignment: .leading, spacing: 6) {
                Text("7-day trend")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))

                VitalsMiniChart(
                    points: trendPoints,
                    gradient: metric.gradient,
                    metric: metric
                )
            }
            .padding(.top, 4)
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
        switch metric {
        case .water:
            return String(format: "%.1fL of %.1fL", value / 1000.0, metric.dailyTarget / 1000.0)
        case .steps:
            let nf = NumberFormatter(); nf.numberStyle = .decimal
            let v = nf.string(from: NSNumber(value: Int(value))) ?? "\(Int(value))"
            let t = nf.string(from: NSNumber(value: Int(metric.dailyTarget))) ?? "\(Int(metric.dailyTarget))"
            return "\(v) of \(t)"
        case .weight:
            return String(format: "%.1f kg → %.0f kg goal", value, metric.goalValue)
        }
    }

    private func progressFraction(for value: Double) -> Double {
        metric.progressFraction(for: value)
    }

    private var averageValue: Double {
        guard !trendPoints.isEmpty else { return 0.0 }
        // Weight: use the latest reading, not average
        if metric == .weight {
            return trendPoints.last?.value ?? 0.0
        }
        return trendPoints.reduce(0.0) { $0 + $1.value } / Double(trendPoints.count)
    }
}

// MARK: - Mini Bar Chart
struct VitalsMiniChart: View {
    let points: [DailyTrendPoint]
    let gradient: Gradient
    let metric: LifestyleMetric

    private var maxValue: Double {
        let rawMax = points.map(\.value).max() ?? 1.0
        return max(rawMax, metric.dailyTarget * 0.5) // ensure target line is always visible
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                let isToday = index == points.count - 1
                let fraction = maxValue > 0 ? (point.value / maxValue) : 0.0
                let clampedFraction = max(0.02, min(1.0, fraction)) // min height so bars are visible

                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(gradient: gradient, startPoint: .bottom, endPoint: .top)
                                .opacity(isToday ? 1.0 : 0.45)
                        )
                        .frame(height: max(4, 44 * clampedFraction))
                        .overlay(
                            isToday
                                ? RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.2), lineWidth: 1)
                                : nil
                        )

                    Text(dayLabel(from: point.date))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(isToday ? .white : AppColors.textSecondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.04), value: fraction)
            }
        }
        .frame(height: 60)
    }

    private func dayLabel(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}
