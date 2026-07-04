import SwiftUI

@main
struct NudgeApp: App {
    private let compositionRoot = CompositionRoot()

    var body: some Scene {
        WindowGroup {
            ContentView(router: compositionRoot.router)
                .environment(\.compositionRoot, compositionRoot)
                .preferredColorScheme(.dark)
        }
    }
}
