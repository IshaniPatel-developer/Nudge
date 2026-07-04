import SwiftUI

@MainActor
public final class CompositionRoot {
    public let doseUseCase: DoseUseCase
    public let lifestyleUseCase: LifestyleUseCase
    public let router: AppRouter
    
    public init() {
        let doseRepo = MockDoseRepository()
        let lifestyleRepo = MockLifestyleRepository()
        
        self.doseUseCase = DoseUseCase(repository: doseRepo)
        self.lifestyleUseCase = LifestyleUseCase(repository: lifestyleRepo)
        self.router = AppRouter()
    }
    
    public func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(doseUseCase: doseUseCase, lifestyleUseCase: lifestyleUseCase)
    }
    
    public func makeDoseHistoryViewModel() -> DoseHistoryViewModel {
        DoseHistoryViewModel(doseUseCase: doseUseCase)
    }
    
    public func makeVitalsViewModel() -> VitalsViewModel {
        VitalsViewModel(lifestyleUseCase: lifestyleUseCase)
    }
    
    public func makeAnalyticsViewModel() -> AnalyticsViewModel {
        AnalyticsViewModel(lifestyleUseCase: lifestyleUseCase)
    }
}

public struct CompositionRootKey: EnvironmentKey {
    @MainActor public static let defaultValue: CompositionRoot = CompositionRoot()
}

extension EnvironmentValues {
    public var compositionRoot: CompositionRoot {
        get { self[CompositionRootKey.self] }
        set { self[CompositionRootKey.self] = newValue }
    }
}
