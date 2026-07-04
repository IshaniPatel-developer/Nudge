import SwiftUI

public enum LifestyleMetric: String, CaseIterable, Identifiable, Codable {
    case water
    case weight
    case steps
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .water: return "Water Intake"
        case .weight: return "Weight"
        case .steps: return "Daily Steps"
        }
    }
    
    public var unit: String {
        switch self {
        case .water: return "ml"
        case .weight: return "kg"
        case .steps: return "steps"
        }
    }
    
    public var dailyTarget: Double {
        switch self {
        case .water: return 2500 // ml
        case .weight: return 80 // kg
        case .steps: return 10000 // steps
        }
    }
    
    public var iconName: String {
        switch self {
        case .water: return "drop.fill"
        case .weight: return "scale.fill"
        case .steps: return "figure.walk"
        }
    }
    
    public var gradient: Gradient {
        switch self {
        case .water:
            return Gradient(colors: [Color.blue, Color.cyan])
        case .weight:
            return Gradient(colors: [Color(hex: "#D946EF"), Color(hex: "#A855F7")])
        case .steps:
            return Gradient(colors: [Color.emerald, Color.teal])
        }
    }
}
