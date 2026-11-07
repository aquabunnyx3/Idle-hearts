import SwiftUI

/// Dimmed full-screen modal card used for rewards.
struct ModalCard<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var appeared = false
    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.45 : 0).ignoresSafeArea()
            content
                .padding(22)
                .frame(maxWidth: 360)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0xFFF6FB), Color(hex: 0xF3E6FB)], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
                )
                .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(.white, lineWidth: 2))
                .padding(24)
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear { withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { appeared = true } }
        .accessibilityAddTraits(.isModal)
    }
}

struct BigButton: View {
    let title: String
    var gradient: LinearGradient = Theme.pinkGradient
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.title(19))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Capsule().fill(gradient))
                .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1.5))
                .shadow(color: Theme.pink.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(PressableStyle())
    }
}

struct FloatingHearts: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                Image(systemName: "heart.fill")
                    .font(.system(size: CGFloat(10 + (i * 7) % 16)))
                    .foregroundStyle([Theme.pink, Theme.pinkLight, Color(hex: 0xC59BFF)][i % 3].opacity(0.8))
                    .offset(x: CGFloat((i * 53) % 260) - 130, y: animate ? -70 - CGFloat(i * 9) : 40)
                    .opacity(animate ? 0 : 1)
                    .animation(.easeOut(duration: 2.2).repeatForever(autoreverses: false).delay(Double(i) * 0.18), value: animate)
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}

struct WelcomeBackView: View {
    @Environment(GameState.self) private var state
    let report: OfflineReport
    var body: some View {
        ModalCard {
            VStack(spacing: 14) {
                Text("Welcome Back!").font(Theme.logo(40)).foregroundStyle(Theme.ink)
                ZStack {
                    Circle().fill(RadialGradient(colors: [Color(hex: 0xFFD3E8), .clear], center: .center, startRadius: 10, endRadius: 110))
                        .frame(height: 170)
                    FloatingHearts()
                    HStack(spacing: -18) {
                        Portrait(character: .lola, mood: .happy, size: 92, ring: .white)
                        Portrait(character: .riley, mood: .happy, size: 92, ring: .white)
                    }
                }
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill").foregroundStyle(Theme.violet)
                    Text("+\(Fmt.number(report.loveNotes))").font(Theme.number(36)).foregroundStyle(Theme.pink)
                }
                Text("Love Notes earned while away").font(Theme.title(16)).foregroundStyle(Theme.ink)
                if report.chemistry >= 1 {
                    Text("+\(Fmt.number(report.chemistry)) Chemistry from your team")
                        .font(Theme.body(13, .semibold)).foregroundStyle(Theme.inkSoft)
                }
                Text("Your matchmaking agency has been busy for \(Fmt.duration(report.seconds)).")
                    .font(Theme.body(13)).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
                BigButton(title: "Amazing!") { state.collectOffline(doubled: false) }
                Button {
                    state.collectOffline(doubled: true)
                } label: {
                    HStack(spacing: 4) {
                        Text("Collect 2× for 10")
                        Image(systemName: "diamond.fill").foregroundStyle(Theme.gem)
                    }
                    .font(Theme.body(14, .bold))
                    .foregroundStyle(state.heartGems >= 10 ? Theme.violet : Theme.inkSoft)
                }
                .disabled(state.heartGems < 10)
            }
        }
    }
}

struct DateCompleteView: View {
    @Environment(GameState.self) private var state
    let report: CompletionReport
    var body: some View {
        ModalCard {
            VStack(spacing: 14) {
                Text("Date Complete!").font(Theme.logo(40)).foregroundStyle(Theme.ink)
                Text(report.title).font(.system(size: 17, weight: .bold, design: .serif).italic()).foregroundStyle(Theme.pink)
                ZStack {
                    FloatingHearts()
                    HStack(spacing: 8) {
                        Image(report.partners.0.info.chibi).resizable().scaledToFit().frame(height: 150)
                        Image(systemName: "heart.fill").font(.system(size: 28)).foregroundStyle(Theme.pinkGradient)
                        Image(report.partners.1.info.chibi).resizable().scaledToFit().frame(height: 150)
                    }
                }
                Text("\(report.partners.0.info.firstName) & \(report.partners.1.info.firstName) are officially a match.")
                    .font(Theme.body(14, .semibold)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
                VStack(spacing: 8) {
                    rewardRow("envelope.fill", Theme.violet, "+\(Fmt.number(report.loveNotes)) Love Notes")
                    rewardRow("arrow.up.heart.fill", Theme.pink, "+\(Fmt.rate(report.newRate)) Love Notes/sec forever")
                    rewardRow("diamond.fill", Theme.gem, "+\(report.gems) Heart Gems")
                    rewardRow("theatermasks.fill", Theme.drama, "+\(report.drama) Drama")
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.85)))
                HStack(alignment: .top, spacing: 8) {
                    Portrait(character: report.line.speaker, mood: .happy, size: 36)
                    Text("“\(report.line.text)”").font(.system(size: 13, weight: .medium, design: .serif).italic()).foregroundStyle(Theme.inkSoft)
                    Spacer(minLength: 0)
                }
                BigButton(title: "Next Date") { withAnimation { state.collectCompletion() } }
            }
        }
    }

    private func rewardRow(_ symbol: String, _ tint: Color, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).foregroundStyle(tint).frame(width: 22)
            Text(text).font(Theme.body(14, .bold)).foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}

struct DramaEventView: View {
    @Environment(GameState.self) private var state
    let report: DramaReport
    var body: some View {
        ModalCard {
            VStack(spacing: 14) {
                Text("Drama!").font(Theme.logo(42)).foregroundStyle(Theme.ink)
                ZStack {
                    Circle().fill(LinearGradient(colors: [Color(hex: 0xFF9B6B), Color(hex: 0xE5536B)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 86, height: 86)
                    Image(systemName: report.symbol).font(.system(size: 36, weight: .semibold)).foregroundStyle(.white)
                }
                .shadow(color: Theme.drama.opacity(0.4), radius: 12, y: 5)
                Text(report.title).font(Theme.title(20)).foregroundStyle(Theme.ink)
                Text(report.text).font(Theme.body(15)).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
                HStack(spacing: 14) {
                    Label("+\(Fmt.number(report.chemistry))", systemImage: "heart.fill").foregroundStyle(Theme.pink)
                    if report.gems > 0 {
                        Label("+\(report.gems)", systemImage: "diamond.fill").foregroundStyle(Theme.gem)
                    }
                }
                .font(Theme.number(18))
                BigButton(title: "Juicy!", gradient: LinearGradient(colors: [Color(hex: 0xFF9B6B), Color(hex: 0xE5536B)], startPoint: .top, endPoint: .bottom)) {
                    withAnimation { state.collectDrama() }
                }
            }
        }
    }
}

struct ToastView: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill").foregroundStyle(Theme.pinkLight)
            Text(text).font(Theme.body(13, .semibold)).foregroundStyle(.white).lineLimit(2)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Capsule().fill(Theme.plum.opacity(0.95)))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, 24)
    }
}
