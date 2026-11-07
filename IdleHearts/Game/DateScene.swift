import SpriteKit
import UIKit

/// The living date scene: background, the couple, the big tappable heart,
/// particles and floating reward text. All game logic lives in `GameState`;
/// this scene only renders and forwards taps.
final class DateScene: SKScene {
    weak var state: GameState?

    /// Vertical layout, as fractions of the scene height measured from the bottom.
    var tableLine: CGFloat = 0.36
    var heartCenterY: CGFloat = 0.52

    private let background = SKSpriteNode()
    private let foreground = SKSpriteNode()
    private let foregroundFill = SKSpriteNode(color: .clear, size: .zero)
    private let leftChar = SKSpriteNode()
    private let rightChar = SKSpriteNode()
    private let heartGlow = SKSpriteNode(imageNamed: "tap_heart")
    private let heart = SKSpriteNode(imageNamed: "tap_heart")
    private let effects = SKNode()
    private var ambient: SKEmitterNode?
    private let heartTexture = SKTexture(imageNamed: "particle_heart")
    private let sparkleTexture = SKTexture(imageNamed: "particle_sparkle")

    private var configuredIndex = -1
    private var lastReaction = 0
    private var lastCompletionShown = false
    private var labelPool: [SKLabelNode] = []

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.95, green: 0.88, blue: 0.93, alpha: 1)
        anchorPoint = .zero

        background.zPosition = 0
        foregroundFill.zPosition = 19
        foreground.zPosition = 20
        leftChar.zPosition = 10
        rightChar.zPosition = 10
        heartGlow.zPosition = 29
        heart.zPosition = 30
        effects.zPosition = 40
        heartGlow.alpha = 0
        heartGlow.blendMode = .add
        [background, foregroundFill, foreground, leftChar, rightChar, heartGlow, heart, effects].forEach(addChild)

        heart.run(.repeatForever(.sequence([
            .scale(to: 1.05, duration: 0.7).withTiming(.easeInEaseOut),
            .scale(to: 1.0, duration: 0.7).withTiming(.easeInEaseOut),
        ])), withKey: "pulse")

        if let emitter = makeAmbient() {
            emitter.zPosition = 5
            addChild(emitter)
            ambient = emitter
        }
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: Layout

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layout()
    }

    func configure(for index: Int) {
        configuredIndex = index
        let t = Dates.template(for: index)
        let bgTex = SKTexture(imageNamed: "scene_\(t.scene)")
        let fgTex = SKTexture(imageNamed: "scene_\(t.scene)_fg")
        background.texture = bgTex
        foreground.texture = fgTex
        foregroundFill.color = UIColor(rgb: t.tableEdge)
        leftChar.texture = SKTexture(imageNamed: t.partners.0.info.chibi)
        rightChar.texture = SKTexture(imageNamed: t.partners.1.info.chibi)
        layout()

        // Entrance: characters slide in from the sides.
        for (node, dir) in [(leftChar, -1.0), (rightChar, 1.0)] {
            node.removeAction(forKey: "enter")
            let home = node.position
            node.position.x += CGFloat(dir) * size.width * 0.4
            node.alpha = 0
            node.run(.group([
                .move(to: home, duration: 0.6).withTiming(.easeOut),
                .fadeIn(withDuration: 0.4),
            ]), withKey: "enter")
        }
        startIdle()
    }

    private func layout() {
        guard size.width > 0, size.height > 0, let bgTex = background.texture else { return }
        let w = size.width, h = size.height

        // Background: aspect fill.
        let bgSize = bgTex.size()
        let s = max(w / bgSize.width, h / bgSize.height)
        background.size = CGSize(width: bgSize.width * s, height: bgSize.height * s)
        background.position = CGPoint(x: w / 2, y: h / 2)

        // Foreground table: full width, with its rim (image y ≈ 1075 of 1400) on the table line.
        if let fgTex = foreground.texture {
            let fs = fgTex.size()
            let scale = (w * 1.12) / fs.width
            foreground.size = CGSize(width: fs.width * scale, height: fs.height * scale)
            foreground.anchorPoint = CGPoint(x: 0.5, y: 0)
            let rimFromBottom = (fs.height - fs.height * (1075.0 / 1400.0)) * scale
            foreground.position = CGPoint(x: w / 2, y: h * tableLine - rimFromBottom)
            // Solid fill below the art in case the screen is very tall.
            let fillTop = foreground.position.y + 4
            foregroundFill.anchorPoint = CGPoint(x: 0.5, y: 0)
            foregroundFill.size = CGSize(width: w, height: max(fillTop, 0))
            foregroundFill.position = CGPoint(x: w / 2, y: 0)
        }

        // The couple: upper ~62% of each chibi shows above the table.
        let charH = min(h * 0.34, w * 0.62)
        for (node, xf) in [(leftChar, 0.22), (rightChar, 0.78)] {
            guard let tex = node.texture else { continue }
            let ts = tex.size()
            node.size = CGSize(width: ts.width * charH / ts.height, height: charH)
            node.anchorPoint = CGPoint(x: 0.5, y: 0)
            node.position = CGPoint(x: w * CGFloat(xf), y: h * tableLine - charH * 0.38)
        }

        let heartSize = min(w * 0.40, h * 0.2)
        heart.size = CGSize(width: heartSize, height: heartSize)
        heart.position = CGPoint(x: w / 2, y: h * heartCenterY)
        heartGlow.size = heart.size
        heartGlow.position = heart.position

        ambient?.position = CGPoint(x: w / 2, y: -10)
        ambient?.particlePositionRange = CGVector(dx: w, dy: 0)
    }

    private func startIdle() {
        for (i, node) in [leftChar, rightChar].enumerated() {
            node.removeAction(forKey: "idle")
            let d = 1.4 + Double(i) * 0.25
            node.run(.repeatForever(.sequence([
                .wait(forDuration: Double(i) * 0.4),
                .group([.scaleY(to: 1.025, duration: d).withTiming(.easeInEaseOut), .scaleX(to: 0.99, duration: d)]),
                .group([.scaleY(to: 1.0, duration: d).withTiming(.easeInEaseOut), .scaleX(to: 1.0, duration: d)]),
            ])), withKey: "idle")
        }
    }

    // MARK: Frame updates

    override func update(_ currentTime: TimeInterval) {
        guard let state else { return }
        if state.dateIndex != configuredIndex { configure(for: state.dateIndex) }
        if state.reactionCounter != lastReaction {
            lastReaction = state.reactionCounter
            react(state.reactingCharacter)
        }
        let boosted = state.sparkActive || state.rushActive
        heartGlow.alpha = boosted ? 0.55 + 0.25 * CGFloat(sin(currentTime * 6)) : 0
        heartGlow.setScale(heart.xScale * 1.12)

        let ready = state.completion != nil
        if ready != lastCompletionShown {
            lastCompletionShown = ready
            if ready { celebrate() }
        }
    }

    // MARK: Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let state, state.completion == nil else { return }
        for touch in touches {
            let p = touch.location(in: self)
            let dx = p.x - heart.position.x, dy = p.y - heart.position.y
            let radius = heart.size.width * 0.75
            guard dx * dx + dy * dy < radius * radius else { continue }
            let result = state.tap()
            showTap(at: p, result: result)
        }
    }

    private func showTap(at point: CGPoint, result: TapResult) {
        heart.removeAction(forKey: "squish")
        heart.run(.sequence([
            .scale(to: 0.88, duration: 0.05),
            .scale(to: result.isCritical ? 1.18 : 1.08, duration: 0.09).withTiming(.easeOut),
            .scale(to: 1.0, duration: 0.12),
        ]), withKey: "squish")

        burst(at: heart.position, count: result.isCritical ? 16 : 6, critical: result.isCritical)
        floatText(result.isCritical ? "CRITICAL! +\(Fmt.number(result.amount))" : "+\(Fmt.number(result.amount))",
                  at: CGPoint(x: point.x + .random(in: -20...20), y: heart.position.y + heart.size.height * 0.45),
                  critical: result.isCritical)
        if result.gainedDrama {
            floatText("+1 Drama", at: CGPoint(x: heart.position.x + 60, y: heart.position.y), critical: false, color: UIColor(rgb: 0xFF8A65))
        }
    }

    private func burst(at p: CGPoint, count: Int, critical: Bool) {
        let colors: [UIColor] = [UIColor(rgb: 0xFF6FB5), UIColor(rgb: 0xFFB3D6), UIColor(rgb: 0xC59BFF), .white]
        for i in 0..<count {
            let sparkle = critical && i % 3 == 0
            let n = SKSpriteNode(texture: sparkle ? sparkleTexture : heartTexture)
            let sz = CGFloat.random(in: 12...(critical ? 30 : 22))
            n.size = CGSize(width: sz, height: sz)
            n.color = colors.randomElement()!
            n.colorBlendFactor = 1
            n.position = p
            n.zPosition = 1
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 60...(critical ? 190 : 120))
            let dest = CGPoint(x: p.x + cos(angle) * dist, y: p.y + sin(angle) * dist + 40)
            n.run(.sequence([
                .group([
                    .move(to: dest, duration: 0.7).withTiming(.easeOut),
                    .rotate(byAngle: .random(in: -1.5...1.5), duration: 0.7),
                    .sequence([.wait(forDuration: 0.35), .fadeOut(withDuration: 0.35)]),
                    .scale(to: 0.4, duration: 0.7),
                ]),
                .removeFromParent(),
            ]))
            effects.addChild(n)
        }
    }

    private func floatText(_ text: String, at p: CGPoint, critical: Bool, color: UIColor? = nil) {
        let label = labelPool.popLast() ?? SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.removeAllActions()
        label.text = text
        label.fontSize = critical ? 28 : 22
        label.fontColor = color ?? (critical ? UIColor(rgb: 0xFFE27A) : .white)
        label.position = p
        label.alpha = 1
        label.setScale(critical ? 0.6 : 0.85)
        label.zPosition = 2
        // Soft shadow so the number reads on any background.
        let shadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        shadow.text = text
        shadow.fontSize = label.fontSize
        shadow.fontColor = UIColor(rgb: 0x7A2860).withAlphaComponent(0.55)
        shadow.position = CGPoint(x: 1.5, y: -2)
        shadow.zPosition = -1
        label.removeAllChildren()
        label.addChild(shadow)
        effects.addChild(label)
        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: critical ? 110 : 80, duration: 0.9).withTiming(.easeOut),
                .scale(to: critical ? 1.15 : 1.0, duration: 0.15),
                .sequence([.wait(forDuration: 0.55), .fadeOut(withDuration: 0.35)]),
            ]),
            .removeFromParent(),
        ])) { [weak self, weak label] in
            guard let self, let label, self.labelPool.count < 24 else { return }
            self.labelPool.append(label)
        }
    }

    private func react(_ who: CharacterID?) {
        guard let who, let state else { return }
        let t = Dates.template(for: state.dateIndex)
        var targets: [SKSpriteNode] = []
        if who == t.partners.0 { targets = [leftChar] }
        else if who == t.partners.1 { targets = [rightChar] }
        else { targets = [leftChar, rightChar].shuffled().prefix(1).map { $0 } }
        for node in targets {
            node.run(.sequence([
                .moveBy(x: 0, y: 14, duration: 0.12).withTiming(.easeOut),
                .moveBy(x: 0, y: -14, duration: 0.18).withTiming(.easeIn),
            ]), withKey: "hop")
            let emote = SKSpriteNode(texture: heartTexture)
            emote.color = UIColor(rgb: 0xFF5FA8)
            emote.colorBlendFactor = 1
            emote.size = CGSize(width: 26, height: 26)
            emote.position = CGPoint(x: node.position.x + node.size.width * 0.25, y: node.position.y + node.size.height * 1.02)
            emote.setScale(0.2)
            emote.zPosition = 1
            effects.addChild(emote)
            emote.run(.sequence([
                .scale(to: 1.1, duration: 0.18).withTiming(.easeOut),
                .scale(to: 1.0, duration: 0.1),
                .moveBy(x: 0, y: 24, duration: 0.8),
                .fadeOut(withDuration: 0.3),
                .removeFromParent(),
            ]))
        }
    }

    private func celebrate() {
        for i in 0..<5 {
            run(.sequence([.wait(forDuration: Double(i) * 0.15), .run { [weak self] in
                guard let self else { return }
                let p = CGPoint(x: .random(in: self.size.width * 0.2...self.size.width * 0.8),
                                y: .random(in: self.size.height * 0.45...self.size.height * 0.7))
                self.burst(at: p, count: 14, critical: true)
            }]))
        }
        for node in [leftChar, rightChar] {
            node.run(.sequence([
                .moveBy(x: 0, y: 24, duration: 0.15).withTiming(.easeOut),
                .moveBy(x: 0, y: -24, duration: 0.2).withTiming(.easeIn),
                .moveBy(x: 0, y: 12, duration: 0.1).withTiming(.easeOut),
                .moveBy(x: 0, y: -12, duration: 0.15).withTiming(.easeIn),
            ]))
        }
    }

    // MARK: Ambient particles

    private func makeAmbient() -> SKEmitterNode? {
        let e = SKEmitterNode()
        e.particleTexture = sparkleTexture
        e.particleBirthRate = 1.6
        e.particleLifetime = 9
        e.particleLifetimeRange = 3
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = 0.4
        e.particleSpeed = 40
        e.particleSpeedRange = 20
        e.particleAlpha = 0.0
        e.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [0.0, 0.8, 0.8, 0.0].map { NSNumber(value: $0) },
                                                     times: [0.0, 0.15, 0.7, 1.0].map { NSNumber(value: $0) })
        e.particleScale = 0.18
        e.particleScaleRange = 0.12
        e.particleColor = .white
        e.particleColorBlendFactor = 1
        e.particleBlendMode = .add
        e.xAcceleration = 3
        e.advanceSimulationTime(10)
        return e
    }
}

extension SKAction {
    /// Fluent helper: `.move(to: p, duration: 0.3).withTiming(.easeOut)`
    func withTiming(_ mode: SKActionTimingMode) -> SKAction {
        timingMode = mode
        return self
    }
}

extension UIColor {
    convenience init(rgb: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255,
                  alpha: alpha)
    }
}
