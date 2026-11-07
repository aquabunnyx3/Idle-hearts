import SwiftUI

enum Theme {
    static let plum = Color(hex: 0x3B2452)
    static let plumDeep = Color(hex: 0x24153A)
    static let plumSoft = Color(hex: 0x5A3E78)
    static let lavender = Color(hex: 0xF4ECFB)
    static let lavenderDeep = Color(hex: 0xE6D8F5)
    static let pink = Color(hex: 0xEF559A)
    static let pinkLight = Color(hex: 0xFF9CCB)
    static let violet = Color(hex: 0x8C5FD0)
    static let ink = Color(hex: 0x35244A)
    static let inkSoft = Color(hex: 0x8A7AA0)
    static let gold = Color(hex: 0xFFC857)
    static let drama = Color(hex: 0xFF7A59)
    static let gem = Color(hex: 0x6EC6FF)

    static let pinkGradient = LinearGradient(colors: [Color(hex: 0xFF7DB8), Color(hex: 0xE5468F)], startPoint: .top, endPoint: .bottom)
    static let violetGradient = LinearGradient(colors: [Color(hex: 0x9D74E0), Color(hex: 0x6F48B8)], startPoint: .top, endPoint: .bottom)
    static let headerGradient = LinearGradient(colors: [Color(hex: 0x4A2D66), Color(hex: 0x33204A)], startPoint: .top, endPoint: .bottom)
    static let pageGradient = LinearGradient(colors: [Color(hex: 0xF7F0FC), Color(hex: 0xEADDF7)], startPoint: .top, endPoint: .bottom)

    static func logo(_ size: CGFloat) -> Font { .custom("SnellRoundhand-Black", size: size) }
    static func title(_ size: CGFloat = 20) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func body(_ size: CGFloat = 15, _ weight: Font.Weight = .medium) -> Font { .system(size: size, weight: weight, design: .rounded) }
    static func number(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .heavy, design: .rounded).monospacedDigit() }
}

extension Currency {
    var symbol: String {
        switch self {
        case .chemistry: return "heart.fill"
        case .loveNotes: return "envelope.fill"
        case .gems: return "diamond.fill"
        }
    }
    var tint: Color {
        switch self {
        case .chemistry: return Theme.pink
        case .loveNotes: return Theme.violet
        case .gems: return Theme.gem
        }
    }
}

// MARK: - Reusable pieces

struct Card<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.92))
                    .shadow(color: Theme.plum.opacity(0.08), radius: 10, y: 4)
            )
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white, lineWidth: 1))
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill").font(.system(size: 12)).foregroundStyle(Theme.pink)
            Text(title).font(Theme.title(17)).foregroundStyle(Theme.ink)
            Spacer()
            if let trailing { Text(trailing).font(Theme.body(14, .semibold)).foregroundStyle(Theme.inkSoft) }
        }
        .padding(.horizontal, 4)
    }
}

struct CurrencyIcon: View {
    let currency: Currency
    var size: CGFloat = 12
    var body: some View {
        Image(systemName: currency.symbol)
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(currency.tint)
    }
}

/// Pill-shaped purchase button showing a price.
struct PriceButton: View {
    let label: String
    let cost: Double
    let currency: Currency
    let enabled: Bool
    var maxed = false
    var style: LinearGradient = Theme.pinkGradient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(maxed ? "MAX" : label).font(Theme.body(13, .bold))
                if !maxed {
                    HStack(spacing: 3) {
                        Image(systemName: currency.symbol).font(.system(size: 9, weight: .bold))
                        Text(Fmt.number(cost)).font(Theme.number(12))
                    }
                    .opacity(0.95)
                }
            }
            .foregroundStyle(.white)
            .frame(minWidth: 84)
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(Capsule().fill(enabled && !maxed ? style : LinearGradient(colors: [Color(hex: 0xC9BCD8)], startPoint: .top, endPoint: .bottom)))
            .shadow(color: (enabled && !maxed ? Theme.pink : .clear).opacity(0.3), radius: 6, y: 3)
        }
        .buttonStyle(PressableStyle())
        .disabled(maxed)
        .accessibilityLabel(maxed ? "\(label), maxed" : "\(label), costs \(Fmt.number(cost)) \(currency.rawValue)")
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct Portrait: View {
    let character: CharacterID
    var mood: Mood = .neutral
    var size: CGFloat = 52
    var ring: Color = .white
    var body: some View {
        Image(character.info.portrait(mood))
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(ring, lineWidth: max(2, size * 0.05)))
            .shadow(color: Theme.plum.opacity(0.15), radius: 4, y: 2)
            .accessibilityLabel(character.info.name)
    }
}

/// Dark plum page header used on the secondary tabs.
struct PageHeader: View {
    let title: String
    let symbol: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.pinkLight)
            Text(title).font(Theme.logo(34)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .padding(.bottom, 14)
        .background(Theme.headerGradient.ignoresSafeArea(edges: .top))
    }
}

struct SegmentedPicker<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    @Namespace private var ns
    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { i in
                let value = options[i].0
                let label = options[i].1
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = value }
                    Haptics.select()
                } label: {
                    Text(label)
                        .font(Theme.body(14, .semibold))
                        .foregroundStyle(selection == value ? .white : Theme.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if selection == value {
                                Capsule().fill(Theme.violetGradient).matchedGeometryEffect(id: "seg", in: ns)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Theme.lavenderDeep))
    }
}
