import SpriteKit
import SwiftUI

struct HomeView: View {
    @Environment(GameState.self) private var state
    @State private var scene = DateScene(size: CGSize(width: 390, height: 844))
    var openSettings: () -> Void
    var openHelp: () -> Void

    var body: some View {
        ZStack {
            SpriteView(scene: scene, preferredFramesPerSecond: 120, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
                .accessibilityLabel("Date scene. Tap the heart to earn Chemistry.")
                .accessibilityAddTraits(.allowsDirectInteraction)

            // Soft vignette at the top so the HUD always reads.
            VStack {
                LinearGradient(colors: [Theme.plumDeep.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 220)
                    .ignoresSafeArea(edges: .top)
                Spacer()
            }
            .allowsHitTesting(false)

            VStack(spacing: 10) {
                TopBar(openSettings: openSettings, openHelp: openHelp)
                CurrencyHUD()
                DateHeader()
                Spacer(minLength: 0)
                if !state.hasSeenIntro {
                    TapHint().allowsHitTesting(false)
                    Spacer(minLength: 0)
                }
                BoosterRow()
                DialogueBubble(line: state.dialogue)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
        }
        .onAppear { scene.state = state }
    }
}

private struct TapHint: View {
    @State private var bounce = false
    var body: some View {
        Text("Tap the heart!")
            .font(Theme.title(16))
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(Capsule().fill(Theme.pink).shadow(color: Theme.pink.opacity(0.4), radius: 8, y: 3))
            .offset(y: bounce ? -4 : 4)
            .padding(.top, 150)
            .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever()) { bounce = true } }
    }
}

struct TopBar: View {
    var openSettings: () -> Void
    var openHelp: () -> Void
    var body: some View {
        HStack {
            iconButton("questionmark", label: "How to play", action: openHelp)
            Spacer()
            HStack(spacing: 2) {
                Text("Idle Hearts").font(Theme.logo(36))
                Image(systemName: "heart.fill").font(.system(size: 16)).offset(y: -8)
            }
            .foregroundStyle(LinearGradient(colors: [.white, Color(hex: 0xFFD3E8)], startPoint: .top, endPoint: .bottom))
            .shadow(color: Theme.pink.opacity(0.7), radius: 8)
            .accessibilityAddTraits(.isHeader)
            Spacer()
            iconButton("gearshape.fill", label: "Settings", action: openSettings)
        }
    }

    private func iconButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Theme.plum.opacity(0.75)).overlay(Circle().strokeBorder(.white.opacity(0.2))))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
    }
}

struct CurrencyHUD: View {
    @Environment(GameState.self) private var state
    var body: some View {
        HStack(spacing: 6) {
            tile("Chemistry", Fmt.number(state.chemistry), "heart.fill", Theme.pink)
            tile("Love Notes", Fmt.number(state.loveNotes), "envelope.fill", Color(hex: 0xC79BFF))
            tile("Drama", "\(state.drama)", "theatermasks.fill", Theme.drama)
            tile("Heart Gems", "\(state.heartGems)", "diamond.fill", Theme.gem)
        }
    }

    private func tile(_ title: String, _ value: String, _ symbol: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 10, weight: .bold)).foregroundStyle(tint)
                Text(title.uppercased()).font(.system(size: 8.5, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Text(value)
                .font(Theme.number(17))
                .foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.6)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.plum.opacity(0.82)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.18)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct DateHeader: View {
    @Environment(GameState.self) private var state
    var body: some View {
        let t = state.currentTemplate
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(Dates.title(for: state.dateIndex))
                        .font(.system(size: 20, weight: .bold, design: .serif).italic())
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Label(t.location, systemImage: "mappin.and.ellipse")
                        .font(Theme.body(12, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                HStack(spacing: -10) {
                    Portrait(character: t.partners.0, mood: .happy, size: 34)
                    Portrait(character: t.partners.1, mood: .happy, size: 34)
                }
            }
            HStack(spacing: 8) {
                ProgressHeartBar(fraction: state.dateFraction)
                Text("\(Int(state.dateFraction * 100))%")
                    .font(Theme.number(14))
                    .foregroundStyle(Theme.pink)
                    .frame(width: 42, alignment: .trailing)
                    .contentTransition(.numericText())
            }
            HStack {
                Text("\(Fmt.number(state.dateProgress)) / \(Fmt.number(state.dateRequirement)) Chemistry")
                Spacer()
                if state.chemistryPerSecond > 0 {
                    Text("+\(Fmt.rate(state.chemistryPerSecond))/s")
                }
            }
            .font(Theme.body(11, .semibold))
            .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white, lineWidth: 1.5))
        .shadow(color: Theme.plum.opacity(0.18), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }
}

struct ProgressHeartBar: View {
    let fraction: Double
    var height: CGFloat = 12
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.lavenderDeep)
                Capsule()
                    .fill(Theme.pinkGradient)
                    .frame(width: max(height, geo.size.width * fraction))
                    .overlay(alignment: .top) {
                        Capsule().fill(.white.opacity(0.35)).frame(height: height * 0.35).padding(.horizontal, 4).padding(.top, 2)
                    }
                Image(systemName: "heart.fill")
                    .font(.system(size: height * 1.5))
                    .foregroundStyle(Theme.pink)
                    .shadow(color: .white, radius: 0, x: 0, y: 0)
                    .background(Image(systemName: "heart.fill").font(.system(size: height * 1.5 + 5)).foregroundStyle(.white))
                    .offset(x: max(0, geo.size.width * fraction - height))
            }
            .animation(.easeOut(duration: 0.25), value: fraction)
        }
        .frame(height: height)
    }
}

struct BoosterRow: View {
    @Environment(GameState.self) private var state
    @State private var rechargeTarget: Booster?

    var body: some View {
        HStack(spacing: 8) {
            booster(.spark, title: "Spark", detail: "2× taps · 30s", symbol: "sparkles",
                    gradient: [Color(hex: 0xFF8CC6), Color(hex: 0xE5468F)])
            booster(.rush, title: "Chem Rush", detail: "5× taps · 10s", symbol: "bolt.fill",
                    gradient: [Color(hex: 0x8E7CFF), Color(hex: 0x5A43D6)])
            booster(.drama, title: "Cause Drama", detail: "\(state.dramaCost) Drama", symbol: "theatermasks.fill",
                    gradient: [Color(hex: 0xFF9B6B), Color(hex: 0xE5536B)])
        }
        .confirmationDialog("Recharge booster?", isPresented: Binding(get: { rechargeTarget != nil }, set: { if !$0 { rechargeTarget = nil } }), titleVisibility: .visible) {
            Button("Recharge for \(state.rechargeGemCost) Heart Gems") {
                if let b = rechargeTarget { state.recharge(b) }
            }
            .disabled(state.heartGems < state.rechargeGemCost)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Skip the cooldown and use it again right away. You have \(state.heartGems) Heart Gems.")
        }
    }

    private func booster(_ b: Booster, title: String, detail: String, symbol: String, gradient: [Color]) -> some View {
        let active = state.isActive(b)
        let ready = state.isReady(b)
        let status: String = {
            if active { return "Active \(Fmt.duration(state.endsAt(b).timeIntervalSince(state.now)))" }
            if b == .drama { return detail }
            if !ready { return Fmt.duration(state.readyAt(b).timeIntervalSince(state.now)) }
            return detail
        }()
        return Button {
            if active { return }
            if ready { state.activate(b) }
            else if b == .drama { state.toast = "Earn Drama by tapping and finishing dates." ; Haptics.error() }
            else { rechargeTarget = b }
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom))
                    Image(systemName: symbol).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                }
                .frame(width: 34, height: 34)
                .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1.5))
                .shadow(color: gradient[1].opacity(active ? 0.8 : 0.3), radius: active ? 8 : 3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(Theme.body(12, .bold)).foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.8)
                    Text(status).font(Theme.body(10.5, .semibold))
                        .foregroundStyle(active ? gradient[1] : Theme.inkSoft)
                        .lineLimit(1).minimumScaleFactor(0.8)
                        .monospacedDigit()
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8).padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(ready || active ? 0.95 : 0.75)))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(active ? gradient[1] : .white, lineWidth: active ? 2 : 1))
            .shadow(color: Theme.plum.opacity(0.15), radius: 6, y: 3)
            .saturation(ready || active ? 1 : 0.4)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("\(title), \(status)")
    }
}

struct DialogueBubble: View {
    let line: DialogueLine
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Portrait(character: line.speaker, mood: line.mood, size: 56, ring: line.speaker.info.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(line.speaker.info.firstName)
                    .font(Theme.body(12, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9).padding(.vertical, 2)
                    .background(Capsule().fill(Theme.pinkGradient))
                Text("“\(line.text)”")
                    .font(.system(size: 14.5, weight: .medium, design: .serif).italic())
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.95)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Theme.pinkLight.opacity(0.6), lineWidth: 1.5))
        .shadow(color: Theme.plum.opacity(0.2), radius: 10, y: 4)
        .id(line.id)
        .transition(.asymmetric(insertion: .scale(scale: 0.96).combined(with: .opacity), removal: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: line.id)
        .accessibilityElement(children: .combine)
    }
}
