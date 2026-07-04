import Foundation

public enum Formatters {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    public static func formatDose(_ mg: Double) -> String {
        let hasDecimal = mg.truncatingRemainder(dividingBy: 1) != 0
        let format = hasDecimal ? "%.1f mg" : "%.0f mg"
        return String(format: format, mg)
    }
    
    public static func formatSteps(_ count: Int) -> String {
        let number = NSNumber(value: count)
        return (numberFormatter.string(from: number) ?? "\(count)") + " steps"
    }
    
    public static func formatWater(_ ml: Int) -> String {
        let number = NSNumber(value: ml)
        return (numberFormatter.string(from: number) ?? "\(ml)") + " ml"
    }
    
    public static func formatProtein(_ grams: Int) -> String {
        return "\(grams) g"
    }
    
    public static func formatCountdown(from timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "Dose Pending"
        }
        
        let totalSeconds = Int(timeInterval)
        let days = totalSeconds / (24 * 3600)
        let hours = (totalSeconds % (24 * 3600)) / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        var parts: [String] = []
        if days > 0 {
            parts.append("\(days)d")
        }
        if hours > 0 || days > 0 {
            parts.append("\(hours)h")
        }
        parts.append("\(minutes)m")
        
        return parts.joined(separator: " ")
    }
}
