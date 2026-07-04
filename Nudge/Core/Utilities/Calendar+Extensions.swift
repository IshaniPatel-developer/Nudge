import Foundation

extension Calendar {
    public static var currentUTC: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }
}

extension Date {
    public var startOfDay: Date {
        Calendar.currentUTC.startOfDay(for: self)
    }
    
    public func adding(days: Int) -> Date {
        Calendar.currentUTC.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    public func days(from date: Date) -> Int {
        let components = Calendar.currentUTC.dateComponents([.day], from: date.startOfDay, to: self.startOfDay)
        return components.day ?? 0
    }
    
    public var isToday: Bool {
        Calendar.currentUTC.isDateInToday(self)
    }
    
    public func formattedRelative() -> String {
        if isToday {
            return "Today"
        } else if self.adding(days: 1).isToday {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: self)
        }
    }
    
    public static var last7Days: [Date] {
        let today = Date().startOfDay
        return (0..<7).map { today.adding(days: -$0) }.reversed()
    }
}
