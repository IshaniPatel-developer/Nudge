import Foundation

public struct LifestyleLog: Codable, Identifiable, Equatable {
    public let id: UUID
    public let metricId: String
    public let value: Double
    public let date: Date
    
    public init(
        id: UUID = UUID(),
        metricId: String,
        value: Double,
        date: Date
    ) {
        self.id = id
        self.metricId = metricId
        self.value = value
        self.date = date
    }
}
