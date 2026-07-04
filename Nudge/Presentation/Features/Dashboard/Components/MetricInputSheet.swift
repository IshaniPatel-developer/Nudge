import SwiftUI
import Combine

public struct MetricInputSheet: View {
    private let metric: LifestyleMetric
    private let onLog: (Double) -> Void
    
    @State private var inputValue = ""
    @Environment(\.dismiss) private var dismiss
    
    public init(metric: LifestyleMetric, onLog: @escaping (Double) -> Void) {
        self.metric = metric
        self.onLog = onLog
    }
    
    private var quickIncrements: [Double] {
        switch metric {
        case .water: return [250, 500, 750] // in ml
        case .weight: return [0.5, 1.0, 2.0] // in kg
        case .steps: return [1000, 3000, 5000] // in steps
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer() // Transparent top half — underlying screen shows through
            
            VStack(spacing: 24) {
                
                // Sheet Drag Handle Indicator
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                
                Text("Log \(metric.title.replacingOccurrences(of: "Daily ", with: ""))")
                    .font(AppTypography.bodySemibold)
                    .foregroundColor(.white)
                
                // Massive Readout - Borderless Tappable TextField + Unit Label
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    TextField(calculatePlaceholder(), text: $inputValue)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.brandBlue)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 160) // bounds width to keep it centered
                    
                    Text(displayUnit)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Quick-add bubbles matching mockup style
                HStack(spacing: 12) {
                    ForEach(quickIncrements, id: \.self) { val in
                        Button(action: {
                            let increment = metric == .water ? val / 1000.0 : val
                            if let currentNum = Double(inputValue) {
                                inputValue = String(format: metric == .steps ? "%.0f" : "%.1f", currentNum + increment)
                            } else {
                                inputValue = String(format: metric == .steps ? "%.0f" : "%.1f", increment)
                            }
                        }) {
                            Text("+\(formatQuick(val))\(quickUnit)")
                                .font(AppTypography.bodySemibold)
                                .foregroundColor(AppColors.brandBlue)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.brandBlue.opacity(0.4), lineWidth: 1.5)
                                        .background(Color.black.opacity(0.2))
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Save and Cancel buttons
                VStack(spacing: 16) {
                    Button(action: {
                        let loggedVal = Double(inputValue) ?? 0.0
                        if loggedVal > 0 {
                            // If water, user typed in Liters, convert back to ml for Mock DB compatibility
                            let logValue = metric == .water ? loggedVal * 1000.0 : loggedVal
                            onLog(logValue)
                            dismiss()
                        }
                    }) {
                        Text("Save")
                            .font(AppTypography.bodySemibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.brandBlue)
                            .cornerRadius(14)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(AppTypography.bodySemibold)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(
                AppColors.darkCardBackground
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .presentationDetents([.large])
        .presentationBackground(.clear)
    }
    
    private func calculatePlaceholder() -> String {
        return "0.0"
    }
    
    private var displayUnit: String {
        switch metric {
        case .water: return "L"
        case .weight: return "kg"
        case .steps: return "steps"
        }
    }
    
    private var quickUnit: String {
        switch metric {
        case .water: return "ml"
        case .weight: return "kg"
        case .steps: return ""
        }
    }
    
    private func formatQuick(_ val: Double) -> String {
        return String(format: "%.0f", val)
    }
}
