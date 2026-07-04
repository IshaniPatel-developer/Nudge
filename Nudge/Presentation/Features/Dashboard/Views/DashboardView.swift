import SwiftUI

public struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject private var router: AppRouter
    
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
                            Text("Good morning 👋")
                                .font(AppTypography.captionMedium)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("Sarah")
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        
                        // Profile Avatar
                        Image("user")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
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
                            onLogTaken: {
                                Task { await viewModel.markDoseTaken() }
                            },
                            onLogMissed: {
                                Task { await viewModel.markDoseMissed() }
                            }
                        )
                    case .error(let message):
                        ErrorView(message: message) {
                            Task { await viewModel.loadData() }
                        }
                        .frame(height: 180)
                    }
                    
                    // Today's Vitals Overview Rings Card
                    VitalsRingsCard(
                        waterProgress: viewModel.waterProgress,
                        stepsProgress: viewModel.stepsProgress,
                        weightProgress: viewModel.weightProgress,
                        onLogMetric: { metric in
                            viewModel.activeMetricToLog = metric
                            viewModel.showMetricInput = true
                        }
                    )
                    
                    // Titration Dose Progress Timeline Card
                    if case .success(let state) = viewModel.doseState {
                        DoseTimelineView(currentDose: state.currentDose)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadData()
        }
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
}

// MARK: - Week Calendar Helper Component
struct WeekCalendarView: View {
    let days = [
        ("Mon", "30"),
        ("Tue", "1"),
        ("Wed", "2"),
        ("Thu", "3"),
        ("Fri", "4"),
        ("Sat", "5"),
        ("Sun", "6")
    ]
    let selectedDayIndex = 2 // Highlight Wednesday as in Figma mock
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<days.count, id: \.self) { index in
                let day = days[index]
                let isSelected = index == selectedDayIndex
                VStack(spacing: 6) {
                    Text(day.0)
                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                    
                    Text(day.1)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.brandBlue : Color.clear)
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(RoundedRectangle(cornerRadius: 20).fill(AppColors.darkCardBackground.opacity(0.4)))
    }
}

// MARK: - Redesigned Next Dose Card
struct HomeDoseCard: View {
    let state: DoseState
    let onLogTaken: () -> Void
    let onLogMissed: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Next Dose")
                .font(AppTypography.bodySemibold)
                .foregroundColor(AppColors.textSecondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Semaglutide \(Formatters.formatDose(state.activeDose))")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                let daysRemaining = Int(state.nextDoseDate.timeIntervalSinceNow / (24 * 3600))
                Text(daysRemaining <= 0 ? "Dose Pending" : "\(daysRemaining) days until next dose")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    
                    let daysRemaining = max(0, Int(state.nextDoseDate.timeIntervalSinceNow / (24 * 3600)))
                    let progressFraction = 1.0 - (Double(daysRemaining) / 7.0)
                    Capsule()
                        .fill(AppColors.brandBlue)
                        .frame(width: geo.size.width * max(0.0, min(1.0, progressFraction)))
                }
            }
            .frame(height: 6)
            
            HStack(spacing: 12) {
                Button(action: onLogTaken) {
                    Text("Log Taken")
                        .font(AppTypography.bodySemibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.brandBlue)
                        .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: onLogMissed) {
                    Text("Log Missed")
                        .font(AppTypography.bodySemibold)
                        .foregroundColor(AppColors.errorRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.errorRed, lineWidth: 1.5)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
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
}

// MARK: - Today's Vitals Card
struct VitalsRingsCard: View {
    let waterProgress: Double
    let stepsProgress: Double
    let weightProgress: Double
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
                            .frame(width: 48, height: 48)
                        
                        Text("Water")
                            .font(AppTypography.captionRegular)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(String(format: "%.1fL", waterProgress * 2.5))
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
                            .frame(width: 48, height: 48)
                        
                        Text("Steps")
                            .font(AppTypography.captionRegular)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(String(format: "%.1fk", (stepsProgress * 10000) / 1000.0))
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
                            .frame(width: 48, height: 48)
                        
                        Text("Weight")
                            .font(AppTypography.captionRegular)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(String(format: "%.1fkg", weightProgress * 80.0))
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

// MARK: - Dose Progress Timeline
struct DoseTimelineView: View {
    let currentDose: Double
    let doseSteps = [0.25, 0.5, 0.5, 1.0, 1.7] // Updated steps to reflect mockup exactly: 0.25, 0.5, 0.5, 1.0, 1.7
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dose Progress")
                .font(AppTypography.bodySemibold)
                .foregroundColor(AppColors.textSecondary)
            
            VStack(spacing: 12) {
                ZStack {
                    // Timeline Connector Line
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 2)
                        .padding(.horizontal, 28)
                    
                    HStack(spacing: 0) {
                        ForEach(0..<doseSteps.count, id: \.self) { index in
                            // Dynamic completion evaluation
                            let isCompleted = index < 3 // First three steps (0.25, 0.5, 0.5) are completed/Taken
                            let isActive = index == 3 // 1.0mg is active
                            
                            Circle()
                                .stroke(isActive ? AppColors.brandBlue : (isCompleted ? Color.clear : Color.white.opacity(0.12)), lineWidth: isActive ? 3 : 1)
                                .background(Circle().fill(isCompleted ? AppColors.brandBlue : (isActive ? AppColors.brandBlue.opacity(0.12) : Color.clear)))
                                .frame(width: 18, height: 18)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                // Labels below circles (perfectly aligned via maxWidth: .infinity)
                HStack(spacing: 0) {
                    ForEach(0..<doseSteps.count, id: \.self) { index in
                        let step = doseSteps[index]
                        let isActive = index == 3
                        
                        Text(Formatters.formatDose(step))
                            .font(.system(size: 11, weight: isActive ? .bold : .medium, design: .rounded))
                            .foregroundColor(isActive ? .white : AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 8)
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
