import Foundation
import SwiftUI
import Combine

@MainActor
public final class AnalyticsViewModel: ObservableObject {
    private let lifestyleUseCase: LifestyleUseCase
    
    @Published public private(set) var trendState: ViewState<[DailyTrendPoint]> = .loading
    @Published public var selectedMetric: LifestyleMetric = .water
    
    public init(lifestyleUseCase: LifestyleUseCase) {
        self.lifestyleUseCase = lifestyleUseCase
    }
    
    public func loadTrends() async {
        do {
            let points = try await lifestyleUseCase.fetch7DayTrend(for: selectedMetric)
            self.trendState = .success(points)
        } catch {
            self.trendState = .error(error.localizedDescription)
        }
    }
    
    public func selectMetric(_ metric: LifestyleMetric) async {
        self.selectedMetric = metric
        await loadTrends()
    }
    
    public func logValue(_ value: Double, for metric: LifestyleMetric) async {
        do {
            try await lifestyleUseCase.logValue(value, for: metric, date: Date())
            await loadTrends()
        } catch {
            self.trendState = .error(error.localizedDescription)
        }
    }
}
