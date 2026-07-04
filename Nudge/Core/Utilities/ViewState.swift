import Foundation

public enum ViewState<T: Equatable>: Equatable {
    case loading
    case success(T)
    case error(String)
    
    public static func == (lhs: ViewState<T>, rhs: ViewState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.success(let lVal), .success(let rVal)):
            return lVal == rVal
        case (.error(let lErr), .error(let rErr)):
            return lErr == rErr
        default:
            return false
        }
    }
}
