import Foundation

public enum AppError: LocalizedError, Equatable {
    case dataNotFound
    case writeFailed(String)
    case invalidDate
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .dataNotFound:
            return "The requested information could not be found."
        case .writeFailed(let message):
            return "Failed to save log: \(message)"
        case .invalidDate:
            return "The date provided is invalid for this action."
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
}
