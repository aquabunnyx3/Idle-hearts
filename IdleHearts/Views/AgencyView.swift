import SwiftUI

struct AgencyView: View {
    @Environment(GameState.self) private var state
    @State private var segment = 0

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Agency", symbol: "building.2.fill")
            ScrollView {
                VStack(spacing: 16) {
                    incomeCard
                    SegmentedPicker(options: [(0, "Team"), (1, "Upgrades")], selection: $segment)
                    if segment == 0 { team } else { upgrades }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .background(Theme.pageGradient.ignoresSafeArea())
    }

    // MARK: Income summary

    private var incomeCard: some View {
        HStack(spacing: 10) {
            incomeTile("Chemistry", "+\(Fmt.rate(state.chemistryPerSecond))/s", .chemistry)
            incomeTile("Love Notes", "+\(Fmt.rate(state.loveNotesPerSecond))/s", .loveNotes)
            incomeTile("Per tap", Fmt.rate(state.tapValue), .chemistry, symbol: "hand.tap.fill")
        }
    }

    private func incomeTile(_ title: String, _ value: String, _ c: Currency, symbol: String? = nil) -> some View {
        VStack(spacing: 3) {
            Image(systemName: symbol ?? c.symbol).font(.system(size: 13, weight: .bold)).foregroundStyle(c.tint)
            Text(value).font(Theme.number(16)).foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.6)
                .contentTransition(.numericText())
            Text(title).font(Theme.body(11, .semibold)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.92)))
        .shadow(color: Theme.plum.opacity(0.08), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
    }

    // MARK: Team

    private var team: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                SectionHeader(title: "Employees", trailing: "\(CharacterID.allCases.filter { state.level($0) > 0 }.count)/\(CharacterID.allCases.count)")
                Card(padding: 6) {
                    VStack(spacing: 0) {
                        ForEach(Array(CharacterID.allCases.enumerated()), id: \.element) { i, c in
                            EmployeeRow(character: c)
                            if i < CharacterID.allCases.count - 1 { Divider().padding(.leading, 70) }
                        }
                    }
                }
            }
            VStack(spacing: 8) {
                SectionHeader(title: "Departments")
                Card(padding: 6) {
                    VStack(spacing: 0) {
                        ForEach(Array(DepartmentID.allCases.enumerated()), id: \.element) { i, d in
                            DepartmentRow(department: d)
                            if i < DepartmentID.allCases.count - 1 { Divider().padding(.leading, 70) }
                        }
                    }
                }
            }
        }
    }

    // MARK: Upgrades

    private var upgrades: some View {
        VStack(spacing: 10) {
            ForEach(UpgradeID.allCases) { u in UpgradeCard(upgrade: u) }
        }
    }
}

struct EmployeeRow: View {
    @Environment(GameState.self) private var state
    let character: CharacterID

    var body: some View {
        let info = character.info
        let lvl = state.level(character)
        let cost = state.hireCost(character)
        HStack(spacing: 12) {
            Portrait(character: character, mood: lvl > 0 ? .happy : .neutral, size: 54, ring: info.accent)
                .grayscale(lvl > 0 ? 0 : 0.6)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(info.name).font(Theme.body(15, .bold)).foregroundStyle(Theme.ink)
                    if lvl > 0 {
                        Text("Lv. \(lvl)").font(Theme.body(11, .bold)).foregroundStyle(Theme.violet)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Capsule().fill(Theme.lavenderDeep))
                    }
                }
                Text(info.agencyTitle).font(Theme.body(12, .medium)).foregroundStyle(Theme.inkSoft)
                HStack(spacing: 3) {
                    CurrencyIcon(currency: .chemistry, size: 10)
                    if lvl > 0 {
                        Text("+\(Fmt.rate(state.employeeRate(character)))/s").foregroundStyle(Theme.ink)
                        Text("→ \(Fmt.rate(state.employeeRate(character, level: lvl + 1)))").foregroundStyle(Theme.inkSoft)
                    } else {
                        Text("+\(Fmt.rate(info.baseRate))/s when hired").foregroundStyle(Theme.inkSoft)
                    }
                }
                .font(Theme.number(12))
            }
            Spacer(minLength: 4)
            PriceButton(label: lvl == 0 ? "Hire" : "Level up", cost: cost, currency: .loveNotes,
                        enabled: state.canAfford(cost, .loveNotes),
                        style: lvl == 0 ? Theme.pinkGradient : Theme.violetGradient) {
                state.hire(character)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 9)
    }
}

struct DepartmentRow: View {
    @Environment(GameState.self) private var state
    let department: DepartmentID

    var body: some View {
        let lvl = state.level(department)
        let cost = state.cost(department)
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.violetGradient)
                Image(systemName: department.symbol).font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
            }
            .frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(department.title).font(Theme.body(15, .bold)).foregroundStyle(Theme.ink)
                    Text("Lv. \(lvl)").font(Theme.body(11, .bold)).foregroundStyle(Theme.violet)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(Capsule().fill(Theme.lavenderDeep))
                }
                Text(department.effect + " per level").font(Theme.body(12, .medium)).foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 4)
            PriceButton(label: "Upgrade", cost: cost, currency: .loveNotes,
                        enabled: state.canAfford(cost, .loveNotes), style: Theme.violetGradient) {
                state.buy(department)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 9)
    }
}

struct UpgradeCard: View {
    @Environment(GameState.self) private var state
    let upgrade: UpgradeID

    private var currentValue: String {
        switch upgrade {
        case .tapPower: return "\(Fmt.rate(state.baseTap)) / tap"
        case .critChance: return "\(Int((state.critChance * 100).rounded()))%"
        case .passiveIncome: return "+\(state.level(.passiveIncome) * 25)%"
        case .offlineEarnings: return "\(Int(state.offlineCapHours))h max"
        }
    }

    private var nextValue: String {
        let l = state.level(upgrade) + 1
        switch upgrade {
        case .tapPower: return Fmt.rate(Double(1 + l) * pow(2, Double(l / 10)))
        case .critChance: return "\(min(5 + l, 30))%"
        case .passiveIncome: return "+\(l * 25)%"
        case .offlineEarnings: return "\(2 + l)h"
        }
    }

    var body: some View {
        let cost = state.cost(upgrade)
        let maxed = state.isMaxed(upgrade)
        Card {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [Color(hex: 0xFFE3F0), Color(hex: 0xFFC6DF)], startPoint: .top, endPoint: .bottom))
                    Image(systemName: upgrade.symbol).font(.system(size: 22, weight: .semibold)).foregroundStyle(Theme.pink)
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(upgrade.title).font(Theme.body(15, .bold)).foregroundStyle(Theme.ink)
                        Text("Lv. \(state.level(upgrade))").font(Theme.body(11, .bold)).foregroundStyle(Theme.violet)
                    }
                    Text(upgrade.subtitle).font(Theme.body(12, .medium)).foregroundStyle(Theme.inkSoft)
                    HStack(spacing: 4) {
                        Text(currentValue).foregroundStyle(Theme.ink)
                        if !maxed {
                            Image(systemName: "arrow.right").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.pink)
                            Text(nextValue).foregroundStyle(Theme.pink)
                        }
                    }
                    .font(Theme.number(13))
                }
                Spacer(minLength: 4)
                PriceButton(label: "Upgrade", cost: cost, currency: upgrade.currency,
                            enabled: state.canAfford(cost, upgrade.currency), maxed: maxed) {
                    state.buy(upgrade)
                }
            }
        }
    }
}
