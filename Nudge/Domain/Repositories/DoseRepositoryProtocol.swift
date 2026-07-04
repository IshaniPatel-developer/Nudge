import Foundation

public protocol DoseRepositoryProtocol {
    func getSchedule() async throws -> DoseSchedule
    func getDoseLogs() async throws -> [DoseLog]
    func saveDoseLog(_ log: DoseLog) async throws
    func deleteDoseLog(_ id: UUID) async throws
}
