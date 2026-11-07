import SwiftUI

enum AppLinks {
    static let privacy = URL(string: "https://aquabunnyx3.github.io/idle-hearts/privacy.html")!
    static let support = URL(string: "https://aquabunnyx3.github.io/idle-hearts/support.html")!
}

struct SettingsView: View {
    @Environment(GameState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        @Bindable var state = state
        NavigationStack {
            Form {
                Section("Feedback") {
                    Toggle(isOn: $state.soundEnabled) { Label("Sound effects", systemImage: "speaker.wave.2.fill") }
                    Toggle(isOn: $state.hapticsEnabled) { Label("Haptics", systemImage: "iphone.radiowaves.left.and.right") }
                }
                Section("Your agency") {
                    LabeledContent("Couples matched", value: "\(state.dateIndex)")
                    LabeledContent("Total taps", value: Fmt.number(Double(state.totalTaps)))
                    LabeledContent("Lifetime Chemistry", value: Fmt.number(state.lifetimeChemistry))
                    LabeledContent("Lifetime Love Notes", value: Fmt.number(state.lifetimeLoveNotes))
                }
                Section("About") {
                    Link(destination: AppLinks.privacy) { Label("Privacy Policy", systemImage: "hand.raised.fill") }
                    Link(destination: AppLinks.support) { Label("Support", systemImage: "questionmark.circle.fill") }
                    LabeledContent("Version", value: Bundle.main.versionString)
                }
                Section {
                    Button(role: .destructive) { confirmReset = true } label: {
                        Label("Reset progress", systemImage: "arrow.counterclockwise")
                    }
                } footer: {
                    Text("Idle Hearts saves automatically on this device. It collects no personal data.")
                }
            }
            .tint(Theme.pink)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) {
                    state.resetProgress()
                    dismiss()
                }
            } message: {
                Text("This permanently erases your agency, couples and currencies.")
            }
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    private let items: [(String, String, String)] = [
        ("heart.fill", "Tap for Chemistry", "Tap the big heart to build Chemistry. When the bar fills, the date is a success."),
        ("envelope.fill", "Earn Love Notes", "Every happy couple sends Love Notes forever — even while you're away."),
        ("building.2.fill", "Grow your agency", "Hire the team with Love Notes. Employees generate Chemistry on their own."),
        ("arrow.up.circle.fill", "Upgrade", "Spend Chemistry on Tap Power and Critical Sparks. Spend Love Notes on income upgrades."),
        ("sparkles", "Boosters", "Spark doubles taps. Chemistry Rush gives 5× taps. Cause Drama spends Drama for a big burst."),
        ("book.closed.fill", "Story", "Characters who go on dates grow closer and unlock new chapters of their story."),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(items.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: items[i].0)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.pink)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(items[i].1).font(Theme.body(16, .bold)).foregroundStyle(Theme.ink)
                            Text(items[i].2).font(Theme.body(14)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Got it") { dismiss() } } }
        }
        .tint(Theme.pink)
    }
}

extension Bundle {
    var versionString: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
