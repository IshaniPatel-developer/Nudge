import Foundation

public struct DoseLog: Codable, Identifiable, Equatable {
    public enum LogStatus: String, Codable, Equatable {
        case taken
        case missed
        case pending
    }
    
    public enum LogType: String, Codable, Equatable {
        case scheduled
        case backdated
    }
    
    public let id: UUID
    public let scheduledDate: Date
    public let loggedDate: Date?
    public let dose: Double
    public var status: LogStatus
    public let type: LogType
    
    public init(
        id: UUID = UUID(),
        scheduledDate: Date,
        loggedDate: Date? = nil,
        dose: Double,
        status: LogStatus = .pending,
        type: LogType = .scheduled
    ) {
        self.id = id
        self.scheduledDate = scheduledDate
        self.loggedDate = loggedDate
        self.dose = dose
        self.status = status
        self.type = type
    }
}
