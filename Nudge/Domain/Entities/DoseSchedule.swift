import Foundation

public struct DoseSchedule: Codable, Equatable {
    public let startDate: Date
    public let doseSteps: [Double]
    public let stepIntervalWeeks: Int
    
    public init(
        startDate: Date,
        doseSteps: [Double] = [0.25, 0.5, 1.0, 1.7, 2.4],
        stepIntervalWeeks: Int = 4
    ) {
        self.startDate = startDate.startOfDay
        self.doseSteps = doseSteps
        self.stepIntervalWeeks = stepIntervalWeeks
    }
    
    public func dose(at date: Date) -> Double {
        let daysDiff = date.days(from: startDate)
        guard daysDiff >= 0 else { return doseSteps[0] }
        
        let weekIndex = daysDiff / 7
        let stepIndex = min(weekIndex / stepIntervalWeeks, doseSteps.count - 1)
        return doseSteps[stepIndex]
    }
    
    public var targetDose: Double {
        doseSteps.last ?? 2.4
    }
    
    public func nextStepUp(from date: Date) -> (date: Date, amount: Double)? {
        let daysDiff = date.days(from: startDate)
        let weekIndex = max(0, daysDiff / 7)
        let currentStepIndex = min(weekIndex / stepIntervalWeeks, doseSteps.count - 1)
        
        guard currentStepIndex < doseSteps.count - 1 else { return nil }
        
        let nextStepIndex = currentStepIndex + 1
        let nextPeriodWeekIndex = nextStepIndex * stepIntervalWeeks
        let stepUpDate = startDate.adding(days: nextPeriodWeekIndex * 7)
        let nextAmount = doseSteps[nextStepIndex]
        
        return (stepUpDate, nextAmount)
    }
}
