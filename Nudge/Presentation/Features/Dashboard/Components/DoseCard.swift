import SwiftUI

// MARK: - Unified Dose Logging Sheet (Combines Options & Calendar)
public struct DoseLoggingSheet: View {
    public let targetDose: Double
    public let onLog: (DoseLog.LogStatus, Date) -> Void
    
    @State private var currentStep: SheetStep = .options
    @State private var selectedDate = Date()
    @Environment(\.dismiss) private var dismiss
    
    public enum SheetStep {
        case options
        case calendar
    }
    
    public init(targetDose: Double, onLog: @escaping (DoseLog.LogStatus, Date) -> Void) {
        self.targetDose = targetDose
        self.onLog = onLog
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer() // Transparent top half — underlying screen shows through
            
            VStack(spacing: 24) {
                
                // Drag handle
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                
                switch currentStep {
                case .options:
                    Text("Log Today's Dose")
                        .font(AppTypography.bodySemibold)
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    VStack(spacing: 16) {
                        // Mark as Taken
                        Button(action: {
                            onLog(.taken, Date())
                            dismiss()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Mark as Taken")
                                    .font(AppTypography.bodySemibold)
                            }
                            .foregroundColor(AppColors.successGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppColors.successGreen.opacity(0.08))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.successGreen.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Mark as Missed
                        Button(action: {
                            onLog(.missed, Date())
                            dismiss()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Mark as Missed")
                                    .font(AppTypography.bodySemibold)
                            }
                            .foregroundColor(AppColors.errorRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppColors.errorRed.opacity(0.08))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.errorRed.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Back-date
                        Button(action: {
                            currentStep = .calendar
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                Text("Back-date")
                                    .font(AppTypography.bodySemibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal)
                    
                case .calendar:
                    Text("Select Date")
                        .font(AppTypography.bodySemibold)
                        .foregroundColor(.white)
                        
                    CustomCalendarView(selectedDate: $selectedDate)
                        .padding(.vertical, 4)
                    
                    // Side-by-side action buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            currentStep = .options
                        }) {
                            Text("Cancel")
                                .font(AppTypography.bodySemibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(14)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {
                            onLog(.taken, selectedDate)
                            dismiss()
                        }) {
                            Text("Confirm Date")
                                .font(AppTypography.bodySemibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.brandBlue)
                                .cornerRadius(14)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal)
                }
            }
            .frame(minHeight: 480) // Match calendar step height so transparent area is consistent
            .padding(.bottom, 32)
            .background(
                AppColors.darkCardBackground
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .presentationDetents([.large])
        .presentationBackground(.clear)
    }
}

// MARK: - Custom Month-based Grid Calendar View
public struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth: Date
    
    private let calendar = Calendar.current
    
    public init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._currentMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    public var body: some View {
        VStack(spacing: 18) {
            // Month selector: < June 2025 >
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }
            }
            .padding(.horizontal, 8)
            
            // Weekdays Header: Su Mo Tu We Th Fr Sa
            HStack(spacing: 0) {
                ForEach(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            let days = generateDaysInMonth(for: currentMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 10) {
                ForEach(0..<days.count, id: \.self) { index in
                    if let date = days[index] {
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isToday = calendar.isDateInToday(date)
                        
                        Button(action: { selectedDate = date }) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundColor(isSelected ? .white : (isToday ? AppColors.brandBlue : .white))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(isSelected ? AppColors.brandBlue : Color.clear)
                                )
                        }
                    } else {
                        Text("")
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func generateDaysInMonth(for date: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = weekday - 1
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in 1...range.count {
            if let dateOfDay = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(dateOfDay)
            }
        }
        
        return days
    }
}
