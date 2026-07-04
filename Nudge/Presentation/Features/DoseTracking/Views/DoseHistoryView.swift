import SwiftUI

public struct DoseHistoryView: View {
    @StateObject private var viewModel: DoseHistoryViewModel
    @State private var showBackdateSheet = false
    @State private var selectedDate = Date()
    
    public init(viewModel: DoseHistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            AppColors.darkBackground
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header Title: Dose History
                Text("Dose History")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                switch viewModel.historyState {
                case .loading:
                    LoadingView(message: "Compiling injection timeline...")
                        .frame(maxHeight: .infinity)
                case .success(let state):
                    // Current Active Dose Capsule Banner
                    let takenCount = state.logs.filter { $0.status == .taken }.count
                    Text("Current: \(Formatters.formatDose(state.currentDose)) · Week \(takenCount + 1)")
                        .font(AppTypography.bodySemibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.brandBlue)
                        .cornerRadius(20)
                        .padding()
                    
                    // Timeline logs list
                    ScrollView {
                        VStack(spacing: 0) {
                            let sortedLogs = state.logs.sorted { $0.scheduledDate > $1.scheduledDate }
                            
                            ForEach(sortedLogs) { log in
                                DoseLogRow(log: log)
                            }
                            
                            // Forecast Upcoming Dose
                            UpcomingDoseRow(date: state.nextDoseDate, dose: state.activeDose)
                        }
                        .padding(.horizontal)
                    }
                case .error(let message):
                    ErrorView(message: message) {
                        Task { await viewModel.loadHistory() }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            
            // Floating Action Button (+)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showBackdateSheet = true }) {
                        Image(systemName: "plus")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Circle().fill(AppColors.brandBlue))
                            .shadow(color: AppColors.brandBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90) // Shift button above the custom tab bar
                }
            }
        }
        .task {
            await viewModel.loadHistory()
        }
        .sheet(isPresented: $showBackdateSheet) {
            if case .success(let state) = viewModel.historyState {
                DoseLoggingSheet(targetDose: state.activeDose) { status, date in
                    Task {
                        await viewModel.logDose(status: status, date: date, dose: state.activeDose)
                        await viewModel.loadHistory()
                    }
                }
            }
        }
    }
}

// MARK: - Row Components
struct DoseLogRow: View {
    let log: DoseLog
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(log.status == .taken ? AppColors.successGreen : AppColors.errorRed)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(log.scheduledDate))
                    .font(AppTypography.bodySemibold)
                    .foregroundColor(.white)
                
                Text(Formatters.formatDose(log.dose))
                    .font(AppTypography.captionRegular)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Text(log.status == .taken ? "Taken" : "Missed")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(log.status == .taken ? AppColors.successGreen : AppColors.errorRed)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(log.status == .taken ? AppColors.successGreen.opacity(0.12) : AppColors.errorRed.opacity(0.12))
                )
        }
        .padding(.vertical, 14)
        .overlay(
            VStack {
                Spacer()
                Divider()
                    .background(Color.white.opacity(0.04))
            }
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct UpcomingDoseRow: View {
    let date: Date
    let dose: Double
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppColors.textSecondary.opacity(0.3))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(date))
                    .font(AppTypography.bodySemibold)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(Formatters.formatDose(dose))
                    .font(AppTypography.captionRegular)
                    .foregroundColor(AppColors.textSecondary.opacity(0.7))
            }
            
            Spacer()
            
            Text("Upcoming")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                )
        }
        .padding(.vertical, 14)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
