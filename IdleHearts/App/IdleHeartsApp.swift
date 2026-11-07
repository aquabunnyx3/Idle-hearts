import SwiftUI

@main
struct IdleHeartsApp: App {
    @State private var state: GameState
    @Environment(\.scenePhase) private var scenePhase
    private let launch = LaunchOptions()

    init() {
        let options = LaunchOptions()
        _state = State(initialValue: GameState(demo: options.demo))
    }

    var body: some Scene {
        WindowGroup {
            RootView(initialTab: launch.tab)
                .environment(state)
                .onAppear {
                    if let overlay = launch.overlay { state.applyDemoOverlay(overlay) }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: state.willEnterForeground()
            case .background: state.didEnterBackground()
            default: break
            }
        }
    }
}

/// Launch arguments used for App Store screenshots and UI review:
///   -demo            seed a mid-game state that is never saved
///   -tab matches     open on a given tab (home, matches, agency, story)
///   -overlay welcome show a modal (welcome, complete, drama)
struct LaunchOptions {
    let demo: Bool
    let tab: AppTab
    let overlay: String?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        demo = arguments.contains("-demo")
        func value(_ key: String) -> String? {
            guard let i = arguments.firstIndex(of: key), i + 1 < arguments.count else { return nil }
            return arguments[i + 1]
        }
        tab = value("-tab").flatMap(AppTab.init(rawValue:)) ?? .home
        overlay = value("-overlay")
    }
}
