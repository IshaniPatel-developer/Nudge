import Foundation
import SwiftUI
import Combine

@MainActor
public final class DoseHistoryViewModel: ObservableObject {
    private let doseUseCase: DoseUseCase
    
    @Published public private(set) var historyState: ViewState<DoseState> = .loading
    @Published public var showBackdatePicker = false
    @Published public var selectedBackdate = Date()
    
    public init(doseUseCase: DoseUseCase) {
        self.doseUseCase = doseUseCase
    }
    
    public func loadHistory() async {
        do {
            let state = try await doseUseCase.fetchCurrentState()
            self.historyState = .success(state)
        } catch {
            self.historyState = .error(error.localizedDescription)
        }
    }
    
    public func logDose(status: DoseLog.LogStatus, date: Date, dose: Double) async {
        do {
            try await doseUseCase.logDose(status: status, date: date, dose: dose)
            await loadHistory()
        } catch {
            self.historyState = .error(error.localizedDescription)
        }
    }
}
