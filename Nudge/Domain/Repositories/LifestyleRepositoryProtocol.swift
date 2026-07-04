import Foundation

public protocol LifestyleRepositoryProtocol {
    func getLogs(for metric: LifestyleMetric, since startDate: Date) async throws -> [LifestyleLog]
    func saveLog(_ log: LifestyleLog) async throws
    func deleteLog(_ id: UUID) async throws
}
