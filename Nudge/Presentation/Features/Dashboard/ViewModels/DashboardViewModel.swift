import Foundation
import SwiftUI
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    private let doseUseCase: DoseUseCase
    private let lifestyleUseCase: LifestyleUseCase
    
    @Published public private(set) var doseState: ViewState<DoseState> = .loading
    @Published public private(set) var waterProgress: Double = 0.0
    @Published public private(set) var weightProgress: Double = 0.0
    @Published public private(set) var stepsProgress: Double = 0.0
    
    @Published public var showMetricInput = false
    @Published public var activeMetricToLog: LifestyleMetric? = nil
    
    // Backwards compatibility bridge
    public var proteinProgress: Double { weightProgress }
    
    public init(doseUseCase: DoseUseCase, lifestyleUseCase: LifestyleUseCase) {
        self.doseUseCase = doseUseCase
        self.lifestyleUseCase = lifestyleUseCase
    }
    
    public func loadData() async {
        do {
            let state = try await doseUseCase.fetchCurrentState()
            
            // Load lifestyle progresses in parallel for efficiency
            async let water = lifestyleUseCase.fetchTodayProgress(for: .water)
            async let weight = lifestyleUseCase.fetchTodayProgress(for: .weight)
            async let steps = lifestyleUseCase.fetchTodayProgress(for: .steps)
            
            let w = try await water
            let wg = try await weight
            let s = try await steps
            
            self.waterProgress = w
            self.weightProgress = wg
            self.stepsProgress = s
            self.doseState = .success(state)
        } catch {
            self.doseState = .error(error.localizedDescription)
        }
    }
    
    public func markDoseTaken() async {
        guard case .success(let state) = doseState else { return }
        do {
            try await doseUseCase.logDose(status: .taken, date: Date(), dose: state.activeDose)
            await loadData()
        } catch {
            self.doseState = .error(error.localizedDescription)
        }
    }
    
    public func markDoseMissed() async {
        guard case .success(let state) = doseState else { return }
        do {
            try await doseUseCase.logDose(status: .missed, date: state.nextDoseDate, dose: state.activeDose)
            await loadData()
        } catch {
            self.doseState = .error(error.localizedDescription)
        }
    }
    
    public func backdateDose(date: Date) async {
        guard case .success(let state) = doseState else { return }
        do {
            // Backdated doses are logged as taken at a historical date
            try await doseUseCase.logDose(status: .taken, date: date, dose: state.activeDose)
            await loadData()
        } catch {
            self.doseState = .error(error.localizedDescription)
        }
    }
    
    public func logMetricValue(_ value: Double, for metric: LifestyleMetric) async {
        do {
            try await lifestyleUseCase.logValue(value, for: metric, date: Date())
            let updatedProgress = try await lifestyleUseCase.fetchTodayProgress(for: metric)
            switch metric {
            case .water: self.waterProgress = updatedProgress
            case .weight: self.weightProgress = updatedProgress
            case .steps: self.stepsProgress = updatedProgress
            }
        } catch {
            // Error handling can trigger banner states if needed
        }
    }
}
