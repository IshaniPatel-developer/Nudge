import SwiftUI
import Combine

public struct CountdownView: View {
    private let nextDoseDate: Date
    @State private var timeInterval: TimeInterval = 0
    
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    public init(nextDoseDate: Date) {
        self.nextDoseDate = nextDoseDate
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: timeInterval <= 0 ? "exclamationmark.circle.fill" : "clock.fill")
                .font(.callout)
                .foregroundColor(timeInterval <= 0 ? AppColors.errorRed : AppColors.brandTeal)
            
            Text(timeInterval <= 0 ? "Dose Pending" : Formatters.formatCountdown(from: timeInterval))
                .font(AppTypography.bodySemibold)
                .foregroundColor(timeInterval <= 0 ? AppColors.errorRed : .primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(timeInterval <= 0 ? AppColors.errorRed.opacity(0.12) : AppColors.brandTeal.opacity(0.1))
        )
        .onAppear {
            updateInterval()
        }
        .onReceive(timer) { _ in
            updateInterval()
        }
        .onChange(of: nextDoseDate) { _ in
            updateInterval()
        }
    }
    
    private func updateInterval() {
        timeInterval = nextDoseDate.timeIntervalSince(Date())
    }
}
