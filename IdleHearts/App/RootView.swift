import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, matches, agency, story
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Home"
        case .matches: return "Matches"
        case .agency: return "Agency"
        case .story: return "Story"
        }
    }
    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .matches: return "heart.fill"
        case .agency: return "building.2.fill"
        case .story: return "book.fill"
        }
    }
}

struct RootView: View {
    @Environment(GameState.self) private var state
    @State private var tab: AppTab
    @State private var showSettings = false
    @State private var showHelp = false

    init(initialTab: AppTab = .home) {
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            Group {
                switch tab {
                case .home: HomeView(openSettings: { showSettings = true }, openHelp: { showHelp = true })
                case .matches: MatchesView(tab: $tab)
                case .agency: AgencyView()
                case .story: StoryView()
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { TabBar(selection: $tab) }

            overlays
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showHelp) { HelpView().presentationDetents([.medium, .large]) }
        .overlay(alignment: .top) {
            if let toast = state.toast {
                ToastView(text: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: toast) {
                        try? await Task.sleep(for: .seconds(2.6))
                        withAnimation { state.toast = nil }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state.toast)
    }

    @ViewBuilder private var overlays: some View {
        if let report = state.welcomeBack {
            WelcomeBackView(report: report).transition(.opacity).zIndex(3)
        } else if let report = state.completion {
            DateCompleteView(report: report).transition(.opacity).zIndex(2)
        } else if let report = state.dramaReport {
            DramaEventView(report: report).transition(.opacity).zIndex(1)
        }
    }
}

struct TabBar: View {
    @Binding var selection: AppTab
    @Environment(GameState.self) private var state

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { t in
                Button {
                    if selection != t { Haptics.select() }
                    selection = t
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.symbol).font(.system(size: 19, weight: .semibold))
                        Text(t.title).font(Theme.body(11, .bold))
                    }
                    .foregroundStyle(selection == t ? .white : Color(hex: 0xC9B6E4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if selection == t {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.pinkGradient)
                                .shadow(color: Theme.pink.opacity(0.4), radius: 8, y: 2)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if badge(for: t) {
                            Circle().fill(Color(hex: 0xFF4D6D)).frame(width: 9, height: 9)
                                .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                                .offset(x: -14, y: 4)
                        }
                    }
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(t.title)
                .accessibilityAddTraits(selection == t ? .isSelected : [])
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Theme.headerGradient
                .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.12)).frame(height: 1) }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    /// Nudge the player toward the Agency when they can afford something there.
    private func badge(for t: AppTab) -> Bool {
        guard t == .agency, selection != .agency else { return false }
        return CharacterID.allCases.contains { state.canAfford(state.hireCost($0), .loveNotes) && state.level($0) == 0 }
    }
}
