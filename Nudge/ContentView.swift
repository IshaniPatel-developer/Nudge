import SwiftUI

struct ContentView: View {
    @Environment(\.compositionRoot) private var compositionRoot
    @StateObject private var router: AppRouter
    
    init(router: AppRouter) {
        _router = StateObject(wrappedValue: router)
    }
    
    var body: some View {
        Group {
            switch router.selectedTab {
            case .home:
                NavigationStack(path: $router.path) {
                    DashboardView(viewModel: compositionRoot.makeDashboardViewModel())
                }
            case .dose:
                NavigationStack {
                    DoseHistoryView(viewModel: compositionRoot.makeDoseHistoryViewModel())
                }
            case .vitals:
                NavigationStack {
                    VitalsView(viewModel: compositionRoot.makeVitalsViewModel())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Custom Tab Bar View matching Figma mockup
            VStack(spacing: 0) {
                Divider()
                    .background(Color.white.opacity(0.08))
                
                HStack(spacing: 0) {
                    // Home
                    TabBarItem(
                        title: "Home",
                        imageName: "home",
                        isSelected: router.selectedTab == .home,
                        action: { router.selectedTab = .home }
                    )
                    
                    // Dose
                    TabBarItem(
                        title: "Dose",
                        imageName: "dose",
                        isSelected: router.selectedTab == .dose,
                        action: { router.selectedTab = .dose }
                    )
                    
                    // Vitals
                    TabBarItem(
                        title: "Vitals",
                        imageName: "heart",
                        isSelected: router.selectedTab == .vitals,
                        action: { router.selectedTab = .vitals }
                    )
                }
                .padding(.vertical, 8)
                .background(Color.black.ignoresSafeArea(edges: .bottom))
            }
        }
        .environmentObject(router)
    }
}

// MARK: - Custom Tab Bar Item View
struct TabBarItem: View {
    let title: String
    let imageName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(isSelected ? AppColors.brandBlue : AppColors.textSecondary)
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? AppColors.brandBlue : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle()) // Make the entire layout block interactive
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let root = CompositionRoot()
    return ContentView(router: root.router)
        .environment(\.compositionRoot, root)
}
