import SwiftUI

public struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject private var router: AppRouter

    @State private var showDoseSheet = false

    public init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            AppColors.darkBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(AppTypography.captionMedium)
                                .foregroundColor(AppColors.textSecondary)

                            Text("Sarah")
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                        }
                        Spacer()

                        // Profile Avatar placeholder
                        ZStack {
                            Circle()
                                .fill(LinearGradient(gradient: AppColors.purpleGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)
                            Text("S")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 10)

                    // Week Calendar Slider
                    WeekCalendarView()
                        .padding(.vertical, 4)

                    // ViewState-driven Next Dose Widget
                    switch viewModel.doseState {
                    case .loading:
                        LoadingView(message: "Loading dose details...")
                            .frame(height: 180)
                    case .success(let state):
                        HomeDoseCard(
                            state: state,
                            onTaken: { Task { await viewModel.markDoseTaken() } },
                            onMissed: { Task { await viewModel.markDoseMissed() } },
                            onBackdate: { showDoseSheet = true }
                        )
                    case .error(let message):
                        ErrorView(message: message) {
                            Task { await viewModel.loadData() }
                        }
                        .frame(height: 180)
                    }

                    // Today's Vitals Overview Rings Card
                    VitalsRingsCard(
                        waterProgress: LifestyleMetric.water.progressFraction(for: viewModel.waterProgress),
                        waterValue: viewModel.waterProgress,
                        stepsProgress: LifestyleMetric.steps.progressFraction(for: viewModel.stepsProgress),
                        stepsValue: viewModel.stepsProgress,
                        weightProgress: LifestyleMetric.weight.progressFraction(for: viewModel.weightProgress),
                        weightValue: viewModel.weightProgress,
                        onLogMetric: { metric in
                            viewModel.activeMetricToLog = metric
                            viewModel.showMetricInput = true
                        }
                    )

                    // Titration Dose Progress Timeline Card
                    if case .success(let state) = viewModel.doseState {
                        DoseTimelineView(
                            currentDose: state.currentDose,
                            targetDose: state.targetDose,
                            nextStepUpDate: state.nextStepUpDate,
                            nextStepUpAmount: state.nextStepUpAmount
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadData()
        }
        // Dose logging sheet (taken / missed / backdate)
        .sheet(isPresented: $showDoseSheet) {
            if case .success(let state) = viewModel.doseState {
                DoseLoggingSheet(targetDose: state.activeDose) { status, date in
                    Task {
                        switch status {
                        case .taken:
                            await viewModel.backdateDose(date: date)
                        case .missed:
                            await viewModel.markDoseMissed()
                        case .pending:
                            break
                        }
                    }
                }
            }
        }
        // Metric logging sheet
        .sheet(isPresented: $viewModel.showMetricInput) {
            if let metric = viewModel.activeMetricToLog {
                MetricInputSheet(metric: metric) { val in
                    Task {
                        await viewModel.logMetricValue(val, for: metric)
                    }
                }
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning 👋"
        case 12..<17: return "Good afternoon 👋"
        default: return "Good evening 👋"
        }
    }
}

// MARK: - Week Calendar Helper Component
struct WeekCalendarView: View {
    private let calendar = Calendar.current

    // Build a dynamic rolling 7-day window centred on today
    private var days: [(label: String, number: String, isToday: Bool)] {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let numFormatter = DateFormatter()
        numFormatter.dateFormat = "d"
        return (-3...3).map { offset -> (String, String, Bool) in
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            let isToday = calendar.isDateInToday(date)
            return (String(formatter.string(from: date).prefix(3)), numFormatter.string(from: date), isToday)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<days.count, id: \.self) { index in
                let day = days[index]
                VStack(spacing: 6) {
                    Text(day.label)
                        .font(.system(size: 13, weight: day.isToday ? .bold : .medium))
                        .foregroundColor(day.isToday ? .white : AppColors.textSecondary)

                    Text(day.number)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(day.isToday ? AppColors.brandBlue : Color.clear)
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(RoundedRectangle(cornerRadius: 20).fill(AppColors.darkCardBackground.opacity(0.4)))
    }
}

// MARK: - Next Dose Card
struct HomeDoseCard: View {
    let state: DoseState
    let onTaken: () -> Void
    let onMissed: () -> Void
    let onBackdate: () -> Void

    private var daysRemaining: Int {
        max(0, Int(state.nextDoseDate.timeIntervalSinceNow / (24 * 3600)))
    }

    private var progressFraction: Double {
        let elapsed = 7.0 - Double(daysRemaining)
        return max(0.0, min(1.0, elapsed / 7.0))
    }

    private var countdownLabel: String {
        let days = daysRemaining
        if days == 0 { return "Due today" }
        return "\(days) day\(days == 1 ? "" : "s") until next dose"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Title
            Text("Next Dose")
                .font(AppTypography.captionMedium)
                .foregroundColor(AppColors.textSecondary)

            // Medication name + dose
            Text("Semaglutide \(Formatters.formatDose(state.activeDose))")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)

            // Countdown subtitle
            Text(countdownLabel)
                .font(AppTypography.captionRegular)
                .foregroundColor(AppColors.textSecondary)

            // Weekly progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(gradient: AppColors.blueGradient, startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progressFraction)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressFraction)
                }
            }
            .frame(height: 6)

            // ── Two inline action buttons ──────────────────────────────────
            HStack(spacing: 12) {

                // Log Taken — filled blue
                Button(action: onTaken) {
                    Text("Log Taken")
                        .font(AppTypography.bodySemibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(gradient: AppColors.blueGradient,
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .shadow(color: AppColors.brandBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())

                // Log Missed — red outline
                Button(action: onMissed) {
                    Text("Log Missed")
                        .font(AppTypography.bodySemibold)
                        .foregroundColor(AppColors.errorRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.errorRed, lineWidth: 1.5)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Back-date link
            Button(action: onBackdate) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption.weight(.semibold))
                    Text("Back-date injection")
                        .font(AppTypography.captionMedium)
                }
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(AppColors.darkCardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Today's Vitals Card
struct VitalsRingsCard: View {
    let waterProgress: Double
    let waterValue: Double
    let stepsProgress: Double
    let stepsValue: Double
    let weightProgress: Double
    let weightValue: Double
    let onLogMetric: (LifestyleMetric) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Vitals")
                .font(AppTypography.bodySemibold)
                .foregroundColor(AppColors.textSecondary)

            HStack(spacing: 0) {
                // Water
                Button(action: { onLogMetric(.water) }) {
                    VStack(spacing: 8) {
                        ProgressRing(progress: waterProgress, gradient: AppColors.blueGradient, customAssetName: "drop", lineWidth: 6)
                            .frame(width: 52, height: 52)

                        Text("Water")
                            .font(AppTypography.captionRegular)
                            .foregroundColor(AppColors.textSecondary)

                        Text(String(format: "%.1fL", waterValue / 1000.0))
                            .font(AppTypography.captionMedium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)

                // Steps
                Button(action: { onLogMetric(.steps) }) {
                    VStack(spacing: 8) {
                        ProgressRing(progress: stepsProgress, gradient: AppColors.greenGradient, customAssetName: "footprint", lineWidth: 6)
                            .frame(width: 52, height: 52)

                        Text("Steps")
                            .font(AppTypography.captionRegular)
                            .foregroundColor(AppColors.textSecondary)

                        Text(String(format: "%.0fk", stepsValue / 1000.0))
                            .font(AppTypography.captionMedium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)

                // Weight
                Button(action: { onLogMetric(.weight) }) {
                    VStack(spacing: 8) {
                        ProgressRing(progress: weightProgress, gradient: AppColors.purpleGradient, customAssetName: "weight", lineWidth: 6)
                            .frame(width: 52, height: 52)

                        Text("Weight")
                            .font(AppTypography.captionRegular)
                            .foregroundColor(AppColors.textSecondary)

                        Text(String(format: "%.1fkg", weightValue))
                            .font(AppTypography.captionMedium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(AppColors.darkCardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Dose Titration Timeline
struct DoseTimelineView: View {
    let currentDose: Double
    let targetDose: Double
    let nextStepUpDate: Date?
    let nextStepUpAmount: Double?

    // Canonical titration schedule matching the mock repository
    private let doseSteps: [Double] = [0.25, 0.5, 1.0, 1.7, 2.4]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Dose progress")
                    .font(AppTypography.bodySemibold)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text("Target: \(Formatters.formatDose(targetDose))")
                    .font(AppTypography.captionRegular)
                    .foregroundColor(AppColors.textSecondary)
            }

            VStack(spacing: 12) {
                ZStack {
                    // Timeline connector line
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 2)
                        .padding(.horizontal, 28)

                    HStack(spacing: 0) {
                        ForEach(0..<doseSteps.count, id: \.self) { index in
                            let step = doseSteps[index]
                            let isCompleted = step < currentDose
                            let isActive = abs(step - currentDose) < 0.001

                            ZStack {
                                Circle()
                                    .fill(isCompleted ? AppColors.brandBlue : (isActive ? AppColors.brandBlue.opacity(0.2) : Color.white.opacity(0.06)))
                                    .frame(width: 20, height: 20)

                                if isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(.white)
                                } else if isActive {
                                    Circle()
                                        .fill(AppColors.brandBlue)
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(isActive ? AppColors.brandBlue : Color.clear, lineWidth: 2.5)
                                    .frame(width: 20, height: 20)
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                // Labels
                HStack(spacing: 0) {
                    ForEach(0..<doseSteps.count, id: \.self) { index in
                        let step = doseSteps[index]
                        let isActive = abs(step - currentDose) < 0.001

                        Text(Formatters.formatDose(step))
                            .font(.system(size: 11, weight: isActive ? .bold : .medium, design: .rounded))
                            .foregroundColor(isActive ? .white : AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 8)

            // Next step-up callout
            if let stepDate = nextStepUpDate, let stepAmt = nextStepUpAmount {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppColors.brandBlue)
                    Text("Next step-up to \(Formatters.formatDose(stepAmt)) in \(daysUntil(stepDate)) days")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding()
        .background(AppColors.darkCardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func daysUntil(_ date: Date) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: Date().startOfDay, to: date.startOfDay).day ?? 0)
    }
}
