import SwiftUI

// MARK: - Cast

enum CharacterID: String, Codable, CaseIterable, Identifiable {
    case jamie, riley, lola, adrian, vincent
    var id: String { rawValue }
    var info: CastMember { Cast.member(self) }
}

enum Mood: Int, Codable {
    case neutral = 1, happy = 2, soft = 3
}

struct CastMember {
    let id: CharacterID
    let name: String
    let firstName: String
    let role: String
    let agencyTitle: String
    let tagline: String
    let quote: String
    let romanceStyle: [String]
    let accent: Color
    /// Chemistry per second at level 1 when working at the agency.
    let baseRate: Double
    /// Love Notes needed to hire.
    let hireCost: Double
    let banter: [String]
    let critLines: [String]
    let progressLines: [String]
    let completeLines: [String]
    let storyBeats: [String]

    func portrait(_ mood: Mood = .neutral) -> String { "portrait_\(id.rawValue)_\(mood.rawValue)" }
    var chibi: String { "chibi_\(id.rawValue)" }
}

enum Cast {
    static func member(_ id: CharacterID) -> CastMember {
        switch id {
        case .jamie: return jamie
        case .riley: return riley
        case .lola: return lola
        case .adrian: return adrian
        case .vincent: return vincent
        }
    }

    static let jamie = CastMember(
        id: .jamie, name: "Jamie Park", firstName: "Jamie", role: "Employee",
        agencyTitle: "Junior Matchmaker",
        tagline: "Late. Clumsy. Surprisingly successful at matchmaking.",
        quote: "I'm not late! I'm fashionably delayed!",
        romanceStyle: ["Cute Romance", "Wholesome"],
        accent: Color(hex: 0xB59BE8), baseRate: 0.5, hireCost: 25,
        banter: [
            "I spilled latte on the booking sheet, but I think that's good luck?",
            "Okay, they're holding eye contact. I'm holding my breath.",
            "Should I bring them dessert? I'm bringing them dessert.",
            "I wrote 'soulmates?' in my notes. With a question mark. For now.",
            "This is going better than my last three dates combined.",
            "Nobody look at me, I'm crying a tiny bit.",
            "Is it weird that I made a playlist for this date?",
        ],
        critLines: ["SPARKS! Actual sparks!", "Did everyone see that?!", "I felt that one from here."],
        progressLines: ["We're halfway to adorable!", "They laughed at the same time. That's science."],
        completeLines: ["I'm framing this receipt.", "Another happy couple! And I was only six minutes late."],
        storyBeats: [
            "Jamie joined Idle Hearts after accidentally matching two strangers at a bus stop. They're engaged now.",
            "Jamie keeps a scrapbook of every couple the agency has helped. It's already on volume three.",
            "Turns out Jamie's lateness is a strategy: couples relax when someone more nervous than them shows up.",
            "Jamie confesses they've never been on a date they actually enjoyed. Yet.",
            "Jamie asked you to set them up. 'Just… someone who thinks being early is overrated.'",
        ])

    static let riley = CastMember(
        id: .riley, name: "Riley Hart", firstName: "Riley", role: "Dating Coach",
        agencyTitle: "Dating Coach",
        tagline: "Charming. Confident. Always a flirt. (Especially with you.)",
        quote: "Relax. I got you. …Or do I?",
        romanceStyle: ["Friends with Benefits", "→ Real Feelings"],
        accent: Color(hex: 0xE7B26A), baseRate: 3, hireCost: 200,
        banter: [
            "Lean in. Smile. Now laugh like they're funnier than they are.",
            "Rule one: never order soup on a first date.",
            "Look at that posture. I taught them that.",
            "Confidence is 90% eyebrows. Trust me.",
            "If this works out, I want a mention in the wedding speech.",
            "Not to brag, but my coaching is undefeated. Mostly.",
            "Somebody's blushing. I won't say who. It's both of them.",
        ],
        critLines: ["Textbook. I'm a genius.", "That's what I call chemistry.", "Ooh, smooth."],
        progressLines: ["Look at them go. I'm basically a love wizard.", "Halfway there. Don't fumble it."],
        completeLines: ["Another one! Put it on my highlight reel.", "Told you. I always deliver."],
        storyBeats: [
            "Riley has coached two hundred clients and has never once kept a date for himself past dessert.",
            "Riley's secret: he writes every client a pep talk on a napkin before their date.",
            "Riley admits the flirting is a reflex. 'It's easier than being serious.'",
            "On a slow night, Riley tells you about the one who got away. He still has her napkin.",
            "Riley asks if you'd ever go on a date with a dating coach. Hypothetically. Very hypothetically.",
        ])

    static let lola = CastMember(
        id: .lola, name: "Lola Monroe", firstName: "Lola", role: "Best Friend",
        agencyTitle: "Social Strategist",
        tagline: "Chaotic. Loyal. Knows everything about love (except how to stop dating losers).",
        quote: "He said he's emotionally unavailable. And?",
        romanceStyle: ["Best Friends", "→ Romance"],
        accent: Color(hex: 0xE58BB8), baseRate: 15, hireCost: 1_500,
        banter: [
            "Okay… they're either flirting or arguing. Honestly, both work.",
            "Please tell me he didn't bring up his ex again.",
            "That's the 'I'm interested but playing it cool' laugh. I know it well.",
            "If she touches her hair one more time, it's official.",
            "I'd date him. Wait, no. Bad Lola.",
            "This is better than reality TV and I've watched ALL of it.",
            "Their vibe is giving 'second date already booked.'",
            "Someone order these two a dessert to share. Strategically.",
        ],
        critLines: ["OH. Okay, chemistry!", "Did the lights just flicker? That's love.", "I screamed. Internally."],
        progressLines: ["Halfway there and nobody's cried. Iconic.", "We are SO close. Don't jinx it."],
        completeLines: ["I called it. I always call it.", "Book the venue. I'm not kidding."],
        storyBeats: [
            "Lola has been your best friend since college, when she set you up with your roommate. It was a disaster. You're still friends.",
            "Lola keeps a group chat with every ex she's ever had. They all love her. Nobody understands it.",
            "Lola's dating rule: 'Never date someone whose plants are dead.' She has broken it twice.",
            "Lola admits she started helping the agency because she was scared of you leaving to do it alone.",
            "Lola asks you to set her up. 'Someone nice. Someone who answers texts. Someone… like you, maybe.'",
        ])

    static let adrian = CastMember(
        id: .adrian, name: "Adrian Vale", firstName: "Adrian", role: "Co-Founder",
        agencyTitle: "Co-Founder",
        tagline: "Brilliant. Sarcastic. Emotionally unavailable. (Probably.)",
        quote: "Are you talking about the date? No. Us.",
        romanceStyle: ["Enemies to Lovers", "Slow Burn"],
        accent: Color(hex: 0x6B5B7B), baseRate: 80, hireCost: 12_000,
        banter: [
            "Statistically, this should not be working. It's working.",
            "Love is just good data and better lighting.",
            "I'm not invested. I'm monitoring. Closely.",
            "If they kiss, I'm adding it to the quarterly report.",
            "That was a good line. I'll pretend I didn't hear it.",
            "Our conversion rate just went up and so did my heart rate. Coincidence.",
        ],
        critLines: ["…Impressive.", "Fine. That was romantic.", "Efficient. I approve."],
        progressLines: ["Projections look favourable.", "Halfway. Don't get sentimental."],
        completeLines: ["Another successful merger.", "I'll admit it. That was nice."],
        storyBeats: [
            "Adrian co-founded Idle Hearts with you on a napkin business plan. He still has the napkin. He'll deny it.",
            "Adrian runs the numbers on every match. He's never once run them on himself.",
            "Adrian was engaged once. He doesn't talk about it. Lola talks about it constantly.",
            "Late night at the office, Adrian admits the agency is the only thing he's never wanted to walk away from.",
            "'Are you talking about the date?' Adrian asks. 'No,' he answers himself. 'Us.'",
        ])

    static let vincent = CastMember(
        id: .vincent, name: "Vincent Cross", firstName: "Vincent", role: "Investor",
        agencyTitle: "Investor",
        tagline: "Successful. Sophisticated. Recently divorced. His ex owns part of your building.",
        quote: "Love is a risk. But you… might be worth it.",
        romanceStyle: ["Luxury Romance", "Forbidden"],
        accent: Color(hex: 0x8C8C9C), baseRate: 400, hireCost: 100_000,
        banter: [
            "In my day we wrote letters. Long ones. With wax seals.",
            "A good date, like a good investment, needs patience.",
            "That wine is a 2011. Excellent choice. Mine, naturally.",
            "Patience is a virtue. And I have plenty of it.",
            "I've seen boardroom negotiations with less tension.",
            "My ex would hate how well this is going. Wonderful.",
        ],
        critLines: ["Exquisite.", "Now that is a return on investment.", "Bravo."],
        progressLines: ["A promising portfolio.", "Halfway. Hold your position."],
        completeLines: ["A sound investment, beautifully executed.", "Champagne for the table."],
        storyBeats: [
            "Vincent invested in Idle Hearts after a three-minute pitch in an elevator. He said it was the first honest pitch he'd heard in years.",
            "Vincent's ex-wife owns forty percent of your building. They are extremely polite to each other. It's terrifying.",
            "Vincent reads poetry on his lunch break. He keeps the book hidden inside a financial report.",
            "Vincent admits the divorce was his fault: 'I treated love like a merger. It deserved better.'",
            "Vincent asks to take you to dinner. 'Purely professional,' he says, and doesn't believe himself.",
        ])
}

// MARK: - Dates

struct DateTemplate {
    let title: String
    let location: String
    let scene: String
    let partners: (CharacterID, CharacterID)
    let commentator: CharacterID
    /// Table colors used to extend the foreground below the art.
    let tableEdge: UInt32
}

enum Dates {
    static let templates: [DateTemplate] = [
        DateTemplate(title: "The First Date", location: "Cozy Downtown Café", scene: "cafe",
                     partners: (.riley, .jamie), commentator: .lola, tableEdge: 0xC99AB8),
        DateTemplate(title: "The Business Trip", location: "Skyline Hotel", scene: "hotel",
                     partners: (.adrian, .lola), commentator: .jamie, tableEdge: 0x1B1229),
        DateTemplate(title: "The Festival", location: "Riverside Festival", scene: "festival",
                     partners: (.riley, .lola), commentator: .vincent, tableEdge: 0xA4734C),
        DateTemplate(title: "The Blind Date", location: "City Restaurant", scene: "restaurant",
                     partners: (.vincent, .riley), commentator: .adrian, tableEdge: 0xB98AA5),
        DateTemplate(title: "Golden Hour", location: "Rooftop Lounge", scene: "rooftop",
                     partners: (.adrian, .jamie), commentator: .riley, tableEdge: 0xD29BBD),
        DateTemplate(title: "Picnic in Bloom", location: "Blossom Park", scene: "park",
                     partners: (.vincent, .lola), commentator: .jamie, tableEdge: 0xC49B72),
    ]

    static func template(for index: Int) -> DateTemplate { templates[index % templates.count] }

    static func title(for index: Int) -> String {
        let base = template(for: index).title
        let round = index / templates.count
        return round == 0 ? base : "\(base) · Encore \(roman(round + 1))"
    }

    static func roman(_ n: Int) -> String {
        let table: [(Int, String)] = [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
        var n = n, s = ""
        for (v, r) in table { while n >= v { s += r; n -= v } }
        return s
    }
}

// MARK: - Upgrades & departments

enum Currency: String, Codable { case chemistry, loveNotes, gems }

enum UpgradeID: String, Codable, CaseIterable, Identifiable {
    case tapPower, critChance, passiveIncome, offlineEarnings
    var id: String { rawValue }

    var title: String {
        switch self {
        case .tapPower: return "Tap Power"
        case .critChance: return "Critical Spark Chance"
        case .passiveIncome: return "Passive Income"
        case .offlineEarnings: return "Offline Earnings"
        }
    }
    var subtitle: String {
        switch self {
        case .tapPower: return "More Chemistry per tap"
        case .critChance: return "Chance for a 10× tap"
        case .passiveIncome: return "+25% Love Notes per second"
        case .offlineEarnings: return "Earn longer while you're away"
        }
    }
    var symbol: String {
        switch self {
        case .tapPower: return "hand.tap.fill"
        case .critChance: return "sparkles"
        case .passiveIncome: return "envelope.open.fill"
        case .offlineEarnings: return "moon.stars.fill"
        }
    }
    var currency: Currency {
        switch self {
        case .tapPower, .critChance: return .chemistry
        case .passiveIncome, .offlineEarnings: return .loveNotes
        }
    }
    var baseCost: Double {
        switch self {
        case .tapPower: return 15
        case .critChance: return 150
        case .passiveIncome: return 100
        case .offlineEarnings: return 250
        }
    }
    var growth: Double {
        switch self {
        case .tapPower: return 1.55
        case .critChance: return 2.0
        case .passiveIncome: return 1.9
        case .offlineEarnings: return 2.3
        }
    }
    var maxLevel: Int? {
        switch self {
        case .critChance: return 25
        case .offlineEarnings: return 10
        default: return nil
        }
    }
}

enum DepartmentID: String, Codable, CaseIterable, Identifiable {
    case marketing, operations, clientServices
    var id: String { rawValue }
    var title: String {
        switch self {
        case .marketing: return "Marketing"
        case .operations: return "Operations"
        case .clientServices: return "Client Services"
        }
    }
    var effect: String {
        switch self {
        case .marketing: return "+10% Chemistry/sec"
        case .operations: return "+10% Love Notes/sec"
        case .clientServices: return "+15% date rewards"
        }
    }
    var symbol: String {
        switch self {
        case .marketing: return "megaphone.fill"
        case .operations: return "gearshape.2.fill"
        case .clientServices: return "person.2.fill"
        }
    }
    var baseCost: Double {
        switch self {
        case .marketing: return 400
        case .operations: return 600
        case .clientServices: return 900
        }
    }
}

// MARK: - Drama

struct DramaTemplate {
    let title: String
    let text: String   // {A} {B} = date partners
    let symbol: String
}

enum Drama {
    static let events: [DramaTemplate] = [
        DramaTemplate(title: "The Ex Walks In", text: "{A}'s ex just walked in… holding a puppy. {B} pets the puppy. Somehow it's romantic now.", symbol: "figure.walk"),
        DramaTemplate(title: "Wrong Order", text: "The waiter brought one dessert and two spoons. Nobody is complaining.", symbol: "fork.knife"),
        DramaTemplate(title: "Sudden Rain", text: "It started pouring. {A} offered {B} a jacket. Cinematic.", symbol: "cloud.rain.fill"),
        DramaTemplate(title: "Mistaken Identity", text: "A stranger congratulated {A} and {B} on their engagement. Neither corrected them.", symbol: "theatermasks.fill"),
        DramaTemplate(title: "Phone Buzz", text: "{B}'s phone lit up with 'DON'T ANSWER'. {B} didn't. {A} noticed. Points.", symbol: "iphone.radiowaves.left.and.right"),
        DramaTemplate(title: "Karaoke Dare", text: "Lola dared {A} to sing. {A} did. Badly. {B} joined in. Worse. Perfect.", symbol: "music.mic"),
        DramaTemplate(title: "Spilled Drink", text: "{A} knocked over a drink. {B} laughed so hard they snorted. Instant bond.", symbol: "drop.fill"),
        DramaTemplate(title: "Secret Admirer", text: "Roses arrived for {B}, unsigned. {A} is suddenly very attentive.", symbol: "gift.fill"),
        DramaTemplate(title: "Power Outage", text: "The lights went out. Candles came out. Conversation got real.", symbol: "lightbulb.slash.fill"),
        DramaTemplate(title: "Parent Call", text: "{A}'s mom FaceTimed mid-date and asked {B} about grandchildren.", symbol: "phone.fill"),
    ]
}

// MARK: - Color helper

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}
