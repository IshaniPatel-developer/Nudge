import SwiftUI
import Combine

@MainActor
public final class AppRouter: ObservableObject {
    public enum Tab: Hashable {
        case home
        case dose
        case vitals
    }
    
    @Published public var selectedTab: Tab = .home
    @Published public var path = NavigationPath()
    @Published public var selectedMetricForVitals: LifestyleMetric? = nil
    
    public init() {}
    
    public func navigateToVitals(for metric: LifestyleMetric? = nil) {
        selectedMetricForVitals = metric
        selectedTab = .vitals
        path = NavigationPath()
    }
    
    // Backwards compatibility bridge
    public var selectedMetricForAnalytics: LifestyleMetric? {
        get { selectedMetricForVitals }
        set { selectedMetricForVitals = newValue }
    }
    
    public func navigateToAnalytics(for metric: LifestyleMetric? = nil) {
        navigateToVitals(for: metric)
    }
}
