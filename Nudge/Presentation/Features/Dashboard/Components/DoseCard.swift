import SwiftUI

// MARK: - Unified Dose Logging Sheet
public struct DoseLoggingSheet: View {
    public let targetDose: Double
    public let onLog: (DoseLog.LogStatus, Date) -> Void

    @State private var currentStep: SheetStep = .options
    @State private var selectedDate = Date()
    @State private var activeDetent: PresentationDetent = .height(360)
    @Environment(\.dismiss) private var dismiss

    // Height per step
    private static let optionsHeight: PresentationDetent = .height(360)
    private static let calendarHeight: PresentationDetent = .height(560)

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
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 5)
                .padding(.top, 14)
                .padding(.bottom, 8)

            switch currentStep {
            case .options:
                optionsContent
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            case .calendar:
                calendarContent
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .presentationDetents(
            [Self.optionsHeight, Self.calendarHeight],
            selection: $activeDetent
        )
        .presentationBackground(AppColors.darkCardBackground)
        .presentationCornerRadius(28)
        .presentationDragIndicator(.hidden) // Using our own handle
    }

    // MARK: - Options step
    private var optionsContent: some View {
        VStack(spacing: 20) {
            Text("Log Dose")
                .font(AppTypography.bodySemibold)
                .foregroundColor(.white)
                .padding(.top, 8)

            // Dose badge
            Text(Formatters.formatDose(targetDose))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.brandBlue)

            VStack(spacing: 12) {
                // Mark Taken
                Button(action: {
                    onLog(.taken, Date())
                    dismiss()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Mark as Taken")
                            .font(AppTypography.bodySemibold)
                    }
                    .foregroundColor(AppColors.successGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.successGreen.opacity(0.1))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.successGreen.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())

                // Mark Missed
                Button(action: {
                    onLog(.missed, Date())
                    dismiss()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Mark as Missed")
                            .font(AppTypography.bodySemibold)
                    }
                    .foregroundColor(AppColors.errorRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.errorRed.opacity(0.1))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.errorRed.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())

                // Back-date
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentStep = .calendar
                        activeDetent = Self.calendarHeight
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back-date Injection")
                            .font(AppTypography.bodySemibold)
                    }
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    // MARK: - Calendar step
    private var calendarContent: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentStep = .options
                        activeDetent = Self.optionsHeight
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Back")
                            .font(AppTypography.captionMedium)
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Text("Select Date")
                    .font(AppTypography.bodySemibold)
                    .foregroundColor(.white)

                Spacer()

                // Balance the layout
                Text("Back").opacity(0).font(AppTypography.captionMedium)
            }
            .padding(.top, 8)

            CustomCalendarView(selectedDate: $selectedDate)

            HStack(spacing: 12) {
                Button(action: {
                    withAnimation {
                        currentStep = .options
                        activeDetent = Self.optionsHeight
                    }
                }) {
                    Text("Cancel")
                        .font(AppTypography.bodySemibold)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
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
                        .padding(.vertical, 15)
                        .background(AppColors.brandBlue)
                        .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
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
        VStack(spacing: 14) {
            // Month selector
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(9)
                        .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.06)))
                }

                Spacer()

                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(9)
                        .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.06)))
                }
            }

            // Weekdays header
            HStack(spacing: 0) {
                ForEach(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = generateDaysInMonth(for: currentMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(0..<days.count, id: \.self) { index in
                    if let date = days[index] {
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isToday = calendar.isDateInToday(date)
                        let isFuture = date > Date()

                        Button(action: {
                            if !isFuture { selectedDate = date }
                        }) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundColor(
                                    isSelected ? .white :
                                    isFuture ? AppColors.textSecondary.opacity(0.3) :
                                    isToday ? AppColors.brandBlue : .white
                                )
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(isSelected ? AppColors.brandBlue : Color.clear))
                        }
                        .disabled(isFuture)
                    } else {
                        Text("").frame(width: 34, height: 34)
                    }
                }
            }
        }
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
        var days: [Date?] = Array(repeating: nil, count: weekday - 1)
        for day in 1...range.count {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(d)
            }
        }
        return days
    }
}
