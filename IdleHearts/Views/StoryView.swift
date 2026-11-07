import SwiftUI

struct StoryView: View {
    @Environment(GameState.self) private var state
    @State private var segment = 0
    @State private var selected: CharacterID?

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Story", symbol: "book.closed.fill")
            ScrollView {
                VStack(spacing: 12) {
                    SegmentedPicker(options: [(0, "Characters"), (1, "Journal")], selection: $segment)
                    if segment == 0 {
                        ForEach(CharacterID.allCases) { c in
                            Button { selected = c; Haptics.select() } label: { CharacterRow(character: c) }
                                .buttonStyle(PressableStyle())
                        }
                    } else if state.journal.isEmpty {
                        EmptyState(symbol: "book.pages", title: "Your journal is empty",
                                   message: "Dates, drama and new hires will be written here.")
                    } else {
                        ForEach(state.journal) { JournalRow(entry: $0) }
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .background(Theme.pageGradient.ignoresSafeArea())
        .sheet(item: $selected) { c in
            CharacterDetail(character: c)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct CharacterRow: View {
    @Environment(GameState.self) private var state
    let character: CharacterID
    var body: some View {
        let info = character.info
        let lvl = state.affectionLevel(character)
        HStack(spacing: 12) {
            Portrait(character: character, mood: .happy, size: 64, ring: info.accent)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(info.name).font(Theme.body(16, .bold)).foregroundStyle(Theme.ink)
                    Spacer()
                    AffectionBadge(level: lvl)
                }
                Text(info.role).font(Theme.body(12, .semibold)).foregroundStyle(Theme.pink)
                Text("“\(info.quote)”")
                    .font(.system(size: 13, weight: .medium, design: .serif).italic())
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.inkSoft.opacity(0.6))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.95)))
        .shadow(color: Theme.plum.opacity(0.08), radius: 8, y: 3)
        .contentShape(Rectangle())
    }
}

struct AffectionBadge: View {
    let level: Int
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "heart.fill").font(.system(size: 10))
            Text("Lv. \(level)").font(Theme.body(11, .bold))
        }
        .foregroundStyle(Theme.pink)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Capsule().fill(Color(hex: 0xFFE3F0)))
        .accessibilityLabel("Relationship level \(level)")
    }
}

struct JournalRow: View {
    let entry: JournalEntry
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.15))
                Image(systemName: symbol).font(.system(size: 16, weight: .bold)).foregroundStyle(tint)
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(entry.title).font(Theme.body(15, .bold)).foregroundStyle(Theme.ink)
                    Spacer()
                    Text(entry.timestamp, style: .relative).font(Theme.body(11, .medium)).foregroundStyle(Theme.inkSoft)
                }
                Text(entry.detail).font(Theme.body(13)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: -8) {
                    ForEach(entry.characters, id: \.self) { Portrait(character: $0, mood: .happy, size: 26) }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.95)))
        .shadow(color: Theme.plum.opacity(0.06), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        switch entry.kind {
        case .date: return "heart.fill"
        case .drama: return "theatermasks.fill"
        case .story: return "sparkles"
        }
    }
    private var tint: Color {
        switch entry.kind {
        case .date: return Theme.pink
        case .drama: return Theme.drama
        case .story: return Theme.violet
        }
    }
}

struct CharacterDetail: View {
    @Environment(GameState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let character: CharacterID

    var body: some View {
        let info = character.info
        let lvl = state.affectionLevel(character)
        ScrollView {
            VStack(spacing: 18) {
                ZStack(alignment: .bottom) {
                    LinearGradient(colors: [info.accent.opacity(0.35), Theme.lavender], startPoint: .top, endPoint: .bottom)
                        .frame(height: 300)
                    Image(info.chibi)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 280)
                        .shadow(color: Theme.plum.opacity(0.2), radius: 10, y: 6)
                }
                VStack(spacing: 6) {
                    Text(info.name).font(Theme.logo(40)).foregroundStyle(Theme.ink)
                    Text("\(info.role) · \(info.agencyTitle)").font(Theme.body(14, .semibold)).foregroundStyle(Theme.pink)
                    AffectionBadge(level: lvl)
                }
                Text(info.tagline)
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Text("“\(info.quote)”")
                    .font(.system(size: 17, weight: .medium, design: .serif).italic())
                    .foregroundStyle(Theme.violet)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                HStack(spacing: 8) {
                    Text("Romance style").font(Theme.body(12, .bold)).foregroundStyle(Theme.inkSoft)
                    ForEach(info.romanceStyle, id: \.self) { s in
                        Text(s).font(Theme.body(12, .semibold)).foregroundStyle(Theme.pink)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(Color(hex: 0xFFE3F0)))
                    }
                }
                HStack(spacing: 14) {
                    ForEach([Mood.neutral, .happy, .soft], id: \.self) { m in
                        Portrait(character: character, mood: m, size: 76, ring: info.accent)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Story", trailing: "\(min(lvl, info.storyBeats.count))/\(info.storyBeats.count)")
                    ForEach(Array(info.storyBeats.enumerated()), id: \.offset) { i, beat in
                        StoryBeatRow(index: i, text: beat, unlocked: lvl > i)
                    }
                    Text("Send \(info.firstName) on dates to grow your relationship and unlock more of their story.")
                        .font(Theme.body(12)).foregroundStyle(Theme.inkSoft)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 30)
        }
        .background(Theme.lavender.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.ink)
                    .frame(width: 34, height: 34).background(Circle().fill(.white.opacity(0.9)))
            }
            .padding(16)
            .accessibilityLabel("Close")
        }
    }
}

struct StoryBeatRow: View {
    let index: Int
    let text: String
    let unlocked: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index + 1)")
                .font(Theme.number(13)).foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(unlocked ? AnyShapeStyle(Theme.pinkGradient) : AnyShapeStyle(Color(hex: 0xC9BCD8))))
            if unlocked {
                Text(text).font(Theme.body(14)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                    Text("Unlocks at relationship Lv. \(index + 1)")
                }
                .font(Theme.body(13, .semibold)).foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(unlocked ? 0.95 : 0.6)))
    }
}
