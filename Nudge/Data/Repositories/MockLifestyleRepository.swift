import Foundation

public final class MockLifestyleRepository: LifestyleRepositoryProtocol {
    private var logs: [LifestyleLog] = []
    private let lock = NSLock()

    public init() {
        let dates = Date.last7Days

        // Realistic daily totals for the past 7 days (index 6 = today).
        // Today's values are intentionally partial (mid-day progress).
        let waterValues:  [Double] = [2300, 2600, 1900, 2550, 2100, 2750, 1100]  // ml, today = 1100ml
        let weightValues: [Double] = [82.4, 82.2, 82.0, 81.8, 81.9, 82.1, 82.0] // kg, taken once/day
        let stepsValues:  [Double] = [9200, 10800, 8100, 11200, 7800, 12400, 4600] // steps, today = 4600

        for (i, date) in dates.enumerated() {
            let morning   = date.addingTimeInterval(3600 * 8)    //  8:00 AM
            let afternoon = date.addingTimeInterval(3600 * 13)   //  1:00 PM
            let evening   = date.addingTimeInterval(3600 * 19)   //  7:00 PM

            let isToday = i == dates.count - 1

            // --- Water (split morning / afternoon; today only morning so far) ---
            if isToday {
                // One morning drink logged so far today
                logs.append(LifestyleLog(metricId: LifestyleMetric.water.id,
                                         value: waterValues[i],
                                         date: morning))
            } else {
                logs.append(LifestyleLog(metricId: LifestyleMetric.water.id,
                                         value: waterValues[i] * 0.45, date: morning))
                logs.append(LifestyleLog(metricId: LifestyleMetric.water.id,
                                         value: waterValues[i] * 0.55, date: afternoon))
            }

            // --- Weight (one reading per day, morning) ---
            logs.append(LifestyleLog(metricId: LifestyleMetric.weight.id,
                                     value: weightValues[i],
                                     date: morning))

            // --- Steps (aggregated at evening, today only so far mid-day) ---
            if isToday {
                logs.append(LifestyleLog(metricId: LifestyleMetric.steps.id,
                                         value: stepsValues[i],
                                         date: afternoon))
            } else {
                logs.append(LifestyleLog(metricId: LifestyleMetric.steps.id,
                                         value: stepsValues[i],
                                         date: evening))
            }
        }
    }

    public func getLogs(for metric: LifestyleMetric, since startDate: Date) async throws -> [LifestyleLog] {
        try await Task.sleep(nanoseconds: 60_000_000) // 60 ms simulated latency
        lock.lock()
        defer { lock.unlock() }
        return logs.filter { $0.metricId == metric.id && $0.date >= startDate }
    }

    public func saveLog(_ log: LifestyleLog) async throws {
        try await Task.sleep(nanoseconds: 60_000_000)
        lock.lock()
        defer { lock.unlock() }
        logs.append(log)
    }

    public func deleteLog(_ id: UUID) async throws {
        try await Task.sleep(nanoseconds: 60_000_000)
        lock.lock()
        defer { lock.unlock() }
        logs.removeAll { $0.id == id }
    }
}
