import SwiftUI

public struct MetricInputSheet: View {
    private let metric: LifestyleMetric
    private let onLog: (Double) -> Void

    @State private var inputText = ""
    @Environment(\.dismiss) private var dismiss

    public init(metric: LifestyleMetric, onLog: @escaping (Double) -> Void) {
        self.metric = metric
        self.onLog = onLog
    }

    // Quick-add increment values in their corresponding display units
    private var quickIncrements: [(label: String, value: Double)] {
        switch metric {
        case .water:  return [("250ml", 0.25), ("500ml", 0.5), ("750ml", 0.75)]
        case .steps:  return [("1k", 1000), ("3k", 3000), ("5k", 5000)]
        case .weight: return [("+0.5kg", 0.5), ("+1kg", 1.0), ("+2kg", 2.0)]
        }
    }

    private var displayUnit: String {
        switch metric {
        case .water:  return "L"
        case .weight: return "kg"
        case .steps:  return "steps"
        }
    }

    private var themeColor: Color {
        switch metric {
        case .water:  return Color(hex: "#3B82F6") // Blue
        case .steps:  return Color(hex: "#10B981") // Green
        case .weight: return Color(hex: "#D946EF") // Purple
        }
    }

    private var parsedValue: Double {
        Double(inputText.replacingOccurrences(of: ",", with: ".")) ?? 0.0
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 5)
                .padding(.top, 14)

            VStack(spacing: 24) {
                // Header: Plain centered title (no icon)
                Text("Log \(metric.title)")
                    .font(AppTypography.bodySemibold)
                    .foregroundColor(.white)
                    .padding(.top, 6)

                // Large number input field
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    TextField("0", text: $inputText)
                        .keyboardType(metric == .steps ? .numberPad : .decimalPad)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(themeColor)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 180)

                    Text(displayUnit)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }

                // Quick-add pills matching the Figma style
                HStack(spacing: 12) {
                    ForEach(quickIncrements, id: \.label) { increment in
                        Button(action: {
                            let newVal = parsedValue + increment.value
                            inputText = formatForDisplay(newVal)
                        }) {
                            Text("+\(increment.label)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(themeColor)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeColor.opacity(0.4), lineWidth: 1.5)
                                        .background(Color.white.opacity(0.02).cornerRadius(12))
                                )
                        }
                    }
                }

                // Action buttons
                VStack(spacing: 16) {
                    // Save Button
                    Button(action: {
                        let val = parsedValue
                        guard val > 0 else { return }
                        
                        // For water, display unit is L but database expects ml, so convert back on save
                        let loggedValue = (metric == .water) ? (val * 1000.0) : val
                        onLog(loggedValue)
                        dismiss()
                    }) {
                        Text("Save")
                            .font(AppTypography.bodySemibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeColor.opacity(parsedValue > 0 ? 1.0 : 0.5))
                            .cornerRadius(14)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(parsedValue <= 0)

                    // Cancel Button
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(AppTypography.bodySemibold)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(390)])
        .presentationBackground(AppColors.darkCardBackground)
        .presentationCornerRadius(28)
        .presentationDragIndicator(.hidden)
        .onAppear {
            // Pre-fill with "0" or decimal appropriate format
            if metric == .water {
                inputText = "0.0"
            } else if metric == .weight {
                inputText = "0.0"
            } else {
                inputText = "0"
            }
        }
    }

    private func formatForDisplay(_ val: Double) -> String {
        switch metric {
        case .water:  return String(format: "%.1f", val)
        case .weight: return String(format: "%.1f", val)
        case .steps:  return String(format: "%.0f", val)
        }
    }
}
