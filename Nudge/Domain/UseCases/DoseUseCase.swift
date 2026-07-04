import Foundation

public struct DoseState: Equatable {
    public let activeDose: Double
    public let currentDose: Double
    public let targetDose: Double
    public let nextDoseDate: Date
    public let countdownInterval: TimeInterval
    public let nextStepUpDate: Date?
    public let nextStepUpAmount: Double?
    public let logs: [DoseLog]
    
    public init(
        activeDose: Double,
        currentDose: Double,
        targetDose: Double,
        nextDoseDate: Date,
        countdownInterval: TimeInterval,
        nextStepUpDate: Date?,
        nextStepUpAmount: Double?,
        logs: [DoseLog]
    ) {
        self.activeDose = activeDose
        self.currentDose = currentDose
        self.targetDose = targetDose
        self.nextDoseDate = nextDoseDate
        self.countdownInterval = countdownInterval
        self.nextStepUpDate = nextStepUpDate
        self.nextStepUpAmount = nextStepUpAmount
        self.logs = logs
    }
}

public final class DoseUseCase {
    private let repository: DoseRepositoryProtocol
    
    public init(repository: DoseRepositoryProtocol) {
        self.repository = repository
    }
    
    public func fetchCurrentState() async throws -> DoseState {
        let schedule = try await repository.getSchedule()
        let logs = try await repository.getDoseLogs()
        
        let now = Date()
        let startOfToday = now.startOfDay
        let startDate = schedule.startDate
        
        // Calculate weeks elapsed
        let totalDays = max(0, startOfToday.days(from: startDate))
        let currentWeekIndex = totalDays / 7
        
        // Generate list of scheduled injection dates up to current week
        var scheduledDates: [Date] = []
        for i in 0...currentWeekIndex {
            scheduledDates.append(startDate.adding(days: i * 7))
        }
        
        // Find if there is any pending dose in the past or current week
        var earliestPendingDate: Date? = nil
        for scheduledDate in scheduledDates {
            let hasLog = logs.contains { Calendar.currentUTC.isDate($0.scheduledDate, inSameDayAs: scheduledDate) }
            if !hasLog {
                earliestPendingDate = scheduledDate
                break
            }
        }
        
        let nextDoseDate: Date
        let activeDose: Double
        
        if let pendingDate = earliestPendingDate {
            nextDoseDate = pendingDate
            activeDose = schedule.dose(at: pendingDate)
        } else {
            // All scheduled doses logged, next dose is next week
            let nextWeekIndex = currentWeekIndex + 1
            let nextDate = startDate.adding(days: nextWeekIndex * 7)
            nextDoseDate = nextDate
            activeDose = schedule.dose(at: nextDate)
        }
        
        let countdownInterval = nextDoseDate.timeIntervalSince(now)
        
        // Find the last taken dose value
        let sortedLogs = logs.filter { $0.status == .taken }.sorted { $0.loggedDate ?? $0.scheduledDate > $1.loggedDate ?? $1.scheduledDate }
        let currentDose = sortedLogs.first?.dose ?? 0.0
        
        // Calculate next step-up details
        let nextStepUpDate: Date?
        let nextStepUpAmount: Double?
        
        if let stepUp = schedule.nextStepUp(from: now) {
            nextStepUpDate = stepUp.date
            nextStepUpAmount = stepUp.amount
        } else {
            nextStepUpDate = nil
            nextStepUpAmount = nil
        }
        
        return DoseState(
            activeDose: activeDose,
            currentDose: currentDose,
            targetDose: schedule.targetDose,
            nextDoseDate: nextDoseDate,
            countdownInterval: countdownInterval,
            nextStepUpDate: nextStepUpDate,
            nextStepUpAmount: nextStepUpAmount,
            logs: logs
        )
    }
    
    public func logDose(status: DoseLog.LogStatus, date: Date, dose: Double) async throws {
        // Find if a log already exists for this date to avoid duplicate entries
        let logs = try await repository.getDoseLogs()
        let startOfDate = date.startOfDay
        
        let existingLog = logs.first { Calendar.currentUTC.isDate($0.scheduledDate, inSameDayAs: startOfDate) }
        
        let log = DoseLog(
            id: existingLog?.id ?? UUID(),
            scheduledDate: startOfDate,
            loggedDate: status == .taken ? date : nil,
            dose: dose,
            status: status,
            type: status == .taken && !Calendar.currentUTC.isDateInToday(date) ? .backdated : .scheduled
        )
        
        try await repository.saveDoseLog(log)
    }
}
