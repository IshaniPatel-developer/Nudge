import Foundation

public final class MockDoseRepository: DoseRepositoryProtocol {
    private let schedule: DoseSchedule
    private var logs: [DoseLog] = []
    private let lock = NSLock()
    
    public init() {
        // Start date is 56 days ago, so user is starting Week 9 (titrating to 1.0mg)
        let today = Date().startOfDay
        let startDate = today.adding(days: -56)
        self.schedule = DoseSchedule(startDate: startDate)
        
        // Seed logs dynamically going backwards
        // Today - 2 days (Week 8, 0.5mg, Taken)
        let d1 = today.adding(days: -2)
        // Today - 9 days (Week 7, 0.5mg, Taken)
        let d2 = today.adding(days: -9)
        // Today - 16 days (Week 6, 0.5mg, Taken)
        let d3 = today.adding(days: -16)
        // Today - 23 days (Week 5, 0.5mg, Taken)
        let d4 = today.adding(days: -23)
        // Today - 30 days (Week 4, 0.25mg, Taken)
        let d5 = today.adding(days: -30)
        // Today - 37 days (Week 3, 0.25mg, Taken)
        let d6 = today.adding(days: -37)
        // Today - 44 days (Week 2, 0.25mg, Missed)
        let d7 = today.adding(days: -44)
        // Today - 51 days (Week 1, 0.25mg, Missed)
        let d8 = today.adding(days: -51)
        
        self.logs = [
            DoseLog(scheduledDate: d1, loggedDate: d1, dose: 0.5, status: .taken),
            DoseLog(scheduledDate: d2, loggedDate: d2, dose: 0.5, status: .taken),
            DoseLog(scheduledDate: d3, loggedDate: d3, dose: 0.5, status: .taken),
            DoseLog(scheduledDate: d4, loggedDate: d4, dose: 0.5, status: .taken),
            DoseLog(scheduledDate: d5, loggedDate: d5, dose: 0.25, status: .taken),
            DoseLog(scheduledDate: d6, loggedDate: d6, dose: 0.25, status: .taken),
            DoseLog(scheduledDate: d7, loggedDate: nil, dose: 0.25, status: .missed),
            DoseLog(scheduledDate: d8, loggedDate: nil, dose: 0.25, status: .missed)
        ]
    }
    
    public func getSchedule() async throws -> DoseSchedule {
        try await Task.sleep(nanoseconds: 30_000_000)
        lock.lock()
        defer { lock.unlock() }
        return schedule
    }
    
    public func getDoseLogs() async throws -> [DoseLog] {
        try await Task.sleep(nanoseconds: 30_000_000)
        lock.lock()
        defer { lock.unlock() }
        return logs
    }
    
    public func saveDoseLog(_ log: DoseLog) async throws {
        try await Task.sleep(nanoseconds: 30_000_000)
        lock.lock()
        defer { lock.unlock() }
        
        if let index = logs.firstIndex(where: { $0.id == log.id }) {
            logs[index] = log
        } else if let index = logs.firstIndex(where: { Calendar.currentUTC.isDate($0.scheduledDate, inSameDayAs: log.scheduledDate) }) {
            logs[index] = log
        } else {
            logs.append(log)
        }
    }
    
    public func deleteDoseLog(_ id: UUID) async throws {
        try await Task.sleep(nanoseconds: 30_000_000)
        lock.lock()
        defer { lock.unlock() }
        logs.removeAll { $0.id == id }
    }
}
