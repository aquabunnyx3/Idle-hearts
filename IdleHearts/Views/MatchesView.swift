import SwiftUI

struct MatchesView: View {
    @Environment(GameState.self) private var state
    @Binding var tab: AppTab
    @State private var segment = 0

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Matches", symbol: "heart.circle.fill")
            ScrollView {
                VStack(spacing: 14) {
                    SegmentedPicker(options: [(0, "Active"), (1, "Upcoming"), (2, "Completed")], selection: $segment)
                    switch segment {
                    case 0:
                        DateCard(index: state.dateIndex, status: .active)
                            .onTapGesture { tab = .home }
                        statsCard
                    case 1:
                        ForEach(state.dateIndex + 1 ..< state.dateIndex + 6, id: \.self) { i in
                            DateCard(index: i, status: .locked)
                        }
                    default:
                        if state.dateIndex == 0 {
                            EmptyState(symbol: "heart.text.square", title: "No completed dates yet",
                                       message: "Finish your first date to start a collection of happy couples.")
                        } else {
                            ForEach((0..<state.dateIndex).reversed(), id: \.self) { i in
                                DateCard(index: i, status: .completed)
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .background(Theme.pageGradient.ignoresSafeArea())
    }

    private var statsCard: some View {
        Card {
            HStack {
                stat("\(state.dateIndex)", "Couples matched", "heart.fill", Theme.pink)
                Divider().frame(height: 36)
                stat("+\(Fmt.rate(state.loveNotesPerSecond))/s", "Love Notes from couples", "envelope.fill", Theme.violet)
                Divider().frame(height: 36)
                stat(Fmt.number(Double(state.totalTaps)), "Total taps", "hand.tap.fill", Theme.drama)
            }
        }
    }

    private func stat(_ value: String, _ label: String, _ symbol: String, _ tint: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: symbol).foregroundStyle(tint).font(.system(size: 14, weight: .bold))
            Text(value).font(Theme.number(17)).foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(Theme.body(10.5, .semibold)).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DateCard: View {
    enum Status { case active, locked, completed }
    @Environment(GameState.self) private var state
    let index: Int
    let status: Status

    var body: some View {
        let t = Dates.template(for: index)
        HStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                Image("scene_\(t.scene)")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 112, height: 112)
                    .clipped()
                HStack(spacing: -14) {
                    Portrait(character: t.partners.0, mood: .happy, size: 46)
                    Portrait(character: t.partners.1, mood: .happy, size: 46)
                }
                .padding(.bottom, 8)
                if status == .locked {
                    Color.black.opacity(0.35)
                    Image(systemName: "lock.fill").font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 112, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(Dates.title(for: index))
                    .font(.system(size: 17, weight: .bold, design: .serif).italic())
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text("\(t.partners.0.info.firstName) & \(t.partners.1.info.firstName)")
                    .font(Theme.body(13, .semibold))
                    .foregroundStyle(Theme.pink)
                Label(t.location, systemImage: "mappin.circle.fill")
                    .font(Theme.body(12, .medium))
                    .foregroundStyle(Theme.inkSoft)
                switch status {
                case .active:
                    HStack(spacing: 6) {
                        ProgressHeartBar(fraction: state.dateFraction, height: 9)
                        Text("\(Int(state.dateFraction * 100))%").font(Theme.number(12)).foregroundStyle(Theme.pink)
                    }
                    Text("Tap to continue the date").font(Theme.body(11, .semibold)).foregroundStyle(Theme.inkSoft)
                case .locked:
                    HStack(spacing: 4) {
                        CurrencyIcon(currency: .chemistry, size: 10)
                        Text("\(Fmt.number(GameState.requirement(for: index))) Chemistry to complete")
                    }
                    .font(Theme.body(11, .semibold)).foregroundStyle(Theme.inkSoft)
                case .completed:
                    HStack(spacing: 10) {
                        reward(.loveNotes, "+\(Fmt.rate(GameState.coupleRate(for: index)))/s")
                        Label("Matched", systemImage: "checkmark.seal.fill")
                            .font(Theme.body(11, .bold)).foregroundStyle(Color(hex: 0x3DBE8B))
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(status == .locked ? 0.7 : 0.95)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(status == .active ? Theme.pink.opacity(0.6) : .white, lineWidth: status == .active ? 2 : 1))
        .shadow(color: Theme.plum.opacity(0.08), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
    }

    private func reward(_ c: Currency, _ text: String) -> some View {
        HStack(spacing: 3) {
            CurrencyIcon(currency: c, size: 10)
            Text(text).font(Theme.number(12)).foregroundStyle(Theme.ink)
        }
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 40)).foregroundStyle(Theme.pinkLight)
            Text(title).font(Theme.title(17)).foregroundStyle(Theme.ink)
            Text(message).font(Theme.body(14)).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
    }
}
