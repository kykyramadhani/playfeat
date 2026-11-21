import SpriteKit

/// The ghost hand closes on the source, moves to the highlight, then opens.
/// Between demonstrations the outline stays in place. All timing is play time.
final class TutorialHandGuide: SKNode {
    private let sourceRing = SKShapeNode()
    private let destinationRing = SKShapeNode()
    private let trail = SKShapeNode()
    private let hand = SKSpriteNode()
    private let openHand = SKTexture(imageNamed: HandCursorNode.openArt)
    private let pinchHand = SKTexture(imageNamed: HandCursorNode.pinchArt)
    private var activeLesson: TutorialProgress.Lesson?
    private var startedAt: TimeInterval = 0

    override init() {
        super.init()
        for node in [sourceRing, destinationRing] {
            node.strokeColor = .white
            node.fillColor = UIColor(named: "Green300")?.withAlphaComponent(0.19) ?? .clear
            addChild(node)
        }
        trail.strokeColor = .white
        trail.lineCap = .round
        addChild(trail)
        hand.zPosition = 1
        addChild(hand)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func hide() {
        isHidden = true
        activeLesson = nil
    }

    func show(_ cue: KitchenTutorial.Cue?, at time: TimeInterval, scale: CGFloat, reduceMotion: Bool) {
        guard let cue else { hide(); return }
        isHidden = false
        if activeLesson != cue.lesson {
            activeLesson = cue.lesson
            startedAt = time
        }

        let phase = (time - startedAt).truncatingRemainder(dividingBy: 8)
        let pulsating = !reduceMotion && phase < 2.2
        let emphasis = pulsating ? CGFloat(0.82 + cos(phase * 8) * 0.18) : 0.74
        let frame = cue.destination.insetBy(dx: -5 * scale, dy: -5 * scale)
        let target = CGPoint(x: frame.midX, y: frame.midY)
        destinationRing.path = CGPath(roundedRect: frame, cornerWidth: 22 * scale,
                                      cornerHeight: 22 * scale, transform: nil)
        destinationRing.lineWidth = 5 * scale
        destinationRing.alpha = emphasis

        guard let start = cue.source, !cue.carrying else {
            sourceRing.isHidden = true
            trail.isHidden = true
            hand.isHidden = true
            return
        }
        sourceRing.isHidden = false
        let radius = 55 * scale
        sourceRing.path = CGPath(ellipseIn: CGRect(x: start.x - radius, y: start.y - radius,
                                                  width: radius * 2, height: radius * 2), transform: nil)
        sourceRing.lineWidth = 4 * scale
        sourceRing.alpha = emphasis

        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: target)
        trail.path = path.copy(dashingWithPhase: 0, lengths: [5 * scale, 14 * scale])
        trail.lineWidth = 4 * scale
        trail.alpha = 0.75
        trail.isHidden = false

        hand.isHidden = !pulsating
        guard pulsating else { return }
        let amount = CGFloat(min(1, max(0, (phase - 0.45) / 1.1)))
        let opens = phase < 0.25 || phase >= 1.55
        hand.texture = opens ? openHand : pinchHand
        hand.size = CGSize(width: 103 * scale, height: 128 * scale)
        hand.alpha = 0.8
        // Leave the ingredient's centre clear so the real hand still knows
        // where to aim. The stored one-hand preference mirrors the guide.
        let left = UserDefaults.standard.bool(forKey: HandInputModeSetting.isOneHandKey)
            && UserDefaults.standard.string(forKey: HandInputModeSetting.preferredHandKey) == HandSide.left.rawValue
        hand.xScale = left ? 1 : -1
        let offset: CGFloat = left ? 43 : -43
        hand.position = CGPoint(x: start.x + (target.x - start.x) * amount + offset * scale,
                                y: start.y + (target.y - start.y) * amount - 38 * scale)
    }
}
