import Foundation
import SwiftUI
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    private let doseUseCase: DoseUseCase
    private let lifestyleUseCase: LifestyleUseCase

    @Published public private(set) var doseState: ViewState<DoseState> = .loading

    // Raw daily totals for each metric
    @Published public private(set) var waterProgress: Double = 0.0   // ml
    @Published public private(set) var weightProgress: Double = 0.0  // kg (latest reading)
    @Published public private(set) var stepsProgress: Double = 0.0   // steps

    @Published public var showMetricInput = false
    @Published public var activeMetricToLog: LifestyleMetric? = nil

    public init(doseUseCase: DoseUseCase, lifestyleUseCase: LifestyleUseCase) {
        self.doseUseCase = doseUseCase
        self.lifestyleUseCase = lifestyleUseCase
    }

    public func loadData() async {
        do {
            async let doseStateTask = doseUseCase.fetchCurrentState()
            async let water = lifestyleUseCase.fetchTodayProgress(for: .water)
            async let steps = lifestyleUseCase.fetchTodayProgress(for: .steps)
            async let weight = lifestyleUseCase.fetchTodayProgress(for: .weight)

            let (state, w, s, wg) = try await (doseStateTask, water, steps, weight)

            self.doseState = .success(state)
            self.waterProgress = w
            self.stepsProgress = s
            self.weightProgress = wg
        } catch {
            self.doseState = .error(error.localizedDescription)
        }
    }

    // One-tap: mark the pending dose as taken (today's date)
    public func markDoseTaken() async {
        guard case .success(let state) = doseState else { return }
        do {
            try await doseUseCase.logDose(status: .taken, date: Date(), dose: state.activeDose)
            await loadData()
        } catch {
            self.doseState = .error(error.localizedDescription)
        }
    }

    // Mark missed
    public func markDoseMissed() async {
        guard case .success(let state) = doseState else { return }
        do {
            try await doseUseCase.logDose(status: .missed, date: state.nextDoseDate, dose: state.activeDose)
            await loadData()
        } catch {
            self.doseState = .error(error.localizedDescription)
        }
    }

    // Back-date: log as taken at a historical date
    public func backdateDose(date: Date) async {
        guard case .success(let state) = doseState else { return }
        do {
            try await doseUseCase.logDose(status: .taken, date: date, dose: state.activeDose)
            await loadData()
        } catch {
            self.doseState = .error(error.localizedDescription)
        }
    }

    public func logMetricValue(_ value: Double, for metric: LifestyleMetric) async {
        do {
            try await lifestyleUseCase.logValue(value, for: metric, date: Date())
            let updated = try await lifestyleUseCase.fetchTodayProgress(for: metric)
            switch metric {
            case .water: self.waterProgress = updated
            case .weight: self.weightProgress = updated
            case .steps: self.stepsProgress = updated
            }
        } catch {
            // Silently fail; could add toast/banner state here
        }
    }
}
