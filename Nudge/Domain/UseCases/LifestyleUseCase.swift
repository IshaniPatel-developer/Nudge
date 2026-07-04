import Foundation

public struct DailyTrendPoint: Identifiable, Equatable {
    public let id: UUID
    public let date: Date
    public let value: Double
    public let target: Double
    
    public init(id: UUID = UUID(), date: Date, value: Double, target: Double) {
        self.id = id
        self.date = date
        self.value = value
        self.target = target
    }
}

public final class LifestyleUseCase {
    private let repository: LifestyleRepositoryProtocol
    
    public init(repository: LifestyleRepositoryProtocol) {
        self.repository = repository
    }
    
    public func logValue(_ value: Double, for metric: LifestyleMetric, date: Date = Date()) async throws {
        let log = LifestyleLog(metricId: metric.id, value: value, date: date)
        try await repository.saveLog(log)
    }
    
    public func fetchTodayProgress(for metric: LifestyleMetric) async throws -> Double {
        let startOfToday = Date().startOfDay
        let todayLogs = try await repository.getLogs(for: metric, since: startOfToday)
        return todayLogs.reduce(0.0) { $0 + $1.value }
    }
    
    public func fetch7DayTrend(for metric: LifestyleMetric) async throws -> [DailyTrendPoint] {
        let sevenDaysAgo = Date().adding(days: -6).startOfDay
        let logs = try await repository.getLogs(for: metric, since: sevenDaysAgo)
        let dates = Date.last7Days
        
        return dates.map { date in
            let dayLogs = logs.filter { Calendar.currentUTC.isDate($0.date, inSameDayAs: date) }
            let total = dayLogs.reduce(0.0) { $0 + $1.value }
            return DailyTrendPoint(date: date, value: total, target: metric.dailyTarget)
        }
    }
}
