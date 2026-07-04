import Foundation

public final class MockLifestyleRepository: LifestyleRepositoryProtocol {
    private var logs: [LifestyleLog] = []
    private let lock = NSLock()
    
    public init() {
        let dates = Date.last7Days
        
        // Pre-calculated realistic metric totals for each of the 7 days (index 6 is today)
        let waterValues = [2300.0, 2600.0, 1900.0, 2550.0, 2100.0, 2750.0, 1250.0]
        let weightValues = [82.0, 82.2, 81.9, 82.5, 82.1, 82.3, 82.4]
        let stepsValues = [9200.0, 10800.0, 8100.0, 11200.0, 7800.0, 12400.0, 4200.0]
        
        for i in 0..<dates.count {
            let date = dates[i]
            
            // Generate multiple granular log entries per day for realism
            let morningTime = date.addingTimeInterval(3600 * 9)   // 9:00 AM
            let afternoonTime = date.addingTimeInterval(3600 * 14) // 2:00 PM
            let eveningTime = date.addingTimeInterval(3600 * 19)   // 7:00 PM
            
            // Seed Water logs (split across morning & afternoon)
            logs.append(LifestyleLog(metricId: LifestyleMetric.water.id, value: waterValues[i] * 0.4, date: morningTime))
            logs.append(LifestyleLog(metricId: LifestyleMetric.water.id, value: waterValues[i] * 0.6, date: afternoonTime))
            
            // Seed Weight logs (logged once a day in the morning)
            logs.append(LifestyleLog(metricId: LifestyleMetric.weight.id, value: weightValues[i], date: morningTime))
            
            // Seed Steps logs (aggregated log at evening)
            logs.append(LifestyleLog(metricId: LifestyleMetric.steps.id, value: stepsValues[i], date: eveningTime))
        }
    }
    
    public func getLogs(for metric: LifestyleMetric, since startDate: Date) async throws -> [LifestyleLog] {
        try await Task.sleep(nanoseconds: 80_000_000)
        lock.lock()
        defer { lock.unlock() }
        
        return logs.filter { $0.metricId == metric.id && $0.date >= startDate }
    }
    
    public func saveLog(_ log: LifestyleLog) async throws {
        try await Task.sleep(nanoseconds: 80_000_000)
        lock.lock()
        defer { lock.unlock() }
        
        logs.append(log)
    }
    
    public func deleteLog(_ id: UUID) async throws {
        try await Task.sleep(nanoseconds: 80_000_000)
        lock.lock()
        defer { lock.unlock() }
        
        logs.removeAll { $0.id == id }
    }
}
