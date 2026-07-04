import SwiftUI

public enum LifestyleMetric: String, CaseIterable, Identifiable, Codable {
    case water
    case weight
    case steps

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .water:  return "Water Intake"
        case .weight: return "Weight"
        case .steps:  return "Daily Steps"
        }
    }

    public var unit: String {
        switch self {
        case .water:  return "ml"
        case .weight: return "kg"
        case .steps:  return "steps"
        }
    }

    /// The daily target / goal for this metric in native units.
    /// For weight this represents the current tracking reference (used for chart scaling).
    public var dailyTarget: Double {
        switch self {
        case .water:  return 2500   // ml
        case .weight: return 85     // kg – scale anchor for chart; goal weight is user-configurable
        case .steps:  return 10000  // steps
        }
    }

    /// The goal the user is working toward (may differ from dailyTarget for weight).
    public var goalValue: Double {
        switch self {
        case .water:  return 2500   // ml
        case .weight: return 75     // kg goal weight
        case .steps:  return 10000  // steps
        }
    }

    public var iconName: String {
        switch self {
        case .water:  return "drop.fill"
        case .weight: return "scalemass.fill"
        case .steps:  return "figure.walk"
        }
    }

    public var customAssetName: String {
        switch self {
        case .water:  return "drop"
        case .steps:  return "footprint"
        case .weight: return "weight"
        }
    }

    public var gradient: Gradient {
        switch self {
        case .water:
            return Gradient(colors: [Color(hex: "#3B82F6"), Color(hex: "#06B6D4")])
        case .weight:
            return Gradient(colors: [Color(hex: "#D946EF"), Color(hex: "#A855F7")])
        case .steps:
            return Gradient(colors: [Color(hex: "#10B981"), Color(hex: "#0D9488")])
        }
    }

    /// For the progress ring: fraction from 0→1 based on the metric type.
    public func progressFraction(for value: Double) -> Double {
        switch self {
        case .water:
            return min(1.0, value / dailyTarget)
        case .steps:
            return min(1.0, value / dailyTarget)
        case .weight:
            // Progress toward goal weight (lower is better).
            // If current == goal → 1.0. If current == dailyTarget (scale anchor) → 0.0
            let range = dailyTarget - goalValue   // e.g. 85 - 75 = 10 kg range
            guard range > 0 else { return 1.0 }
            let progress = (dailyTarget - value) / range  // 0 at top weight, 1 at goal weight
            return max(0.0, min(1.0, progress))
        }
    }
}
