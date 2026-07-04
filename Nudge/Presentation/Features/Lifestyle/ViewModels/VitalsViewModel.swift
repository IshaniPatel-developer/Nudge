import Foundation
import SwiftUI
import Combine

@MainActor
public final class VitalsViewModel: ObservableObject {
    private let lifestyleUseCase: LifestyleUseCase
    
    @Published public private(set) var loadingState: ViewState<Bool> = .loading
    
    // Water metric states
    @Published public private(set) var waterToday: Double = 0.0
    @Published public private(set) var waterTrend: [DailyTrendPoint] = []
    
    // Steps metric states
    @Published public private(set) var stepsToday: Double = 0.0
    @Published public private(set) var stepsTrend: [DailyTrendPoint] = []
    
    // Weight metric states
    @Published public private(set) var weightToday: Double = 0.0
    @Published public private(set) var weightTrend: [DailyTrendPoint] = []
    
    public init(lifestyleUseCase: LifestyleUseCase) {
        self.lifestyleUseCase = lifestyleUseCase
    }
    
    public var proteinToday: Double { weightToday } // compatibility alias
    public var proteinTrend: [DailyTrendPoint] { weightTrend } // compatibility alias
    
    public func loadAllData() async {
        do {
            // Load all metric values and historical trends concurrently
            async let wToday = lifestyleUseCase.fetchTodayProgress(for: .water)
            async let wTrend = lifestyleUseCase.fetch7DayTrend(for: .water)
            
            async let sToday = lifestyleUseCase.fetchTodayProgress(for: .steps)
            async let sTrend = lifestyleUseCase.fetch7DayTrend(for: .steps)
            
            async let wgToday = lifestyleUseCase.fetchTodayProgress(for: .weight)
            async let wgTrend = lifestyleUseCase.fetch7DayTrend(for: .weight)
            
            let (wt, wtr, st, str, wgt, wgtr) = try await (wToday, wTrend, sToday, sTrend, wgToday, wgTrend)
            
            self.waterToday = wt
            self.waterTrend = wtr
            
            self.stepsToday = st
            self.stepsTrend = str
            
            self.weightToday = wgt
            self.weightTrend = wgtr
            
            self.loadingState = .success(true)
        } catch {
            self.loadingState = .error(error.localizedDescription)
        }
    }
    
    public func logValue(_ value: Double, for metric: LifestyleMetric) async {
        do {
            try await lifestyleUseCase.logValue(value, for: metric, date: Date())
            await loadAllData()
        } catch {
            self.loadingState = .error(error.localizedDescription)
        }
    }
}
