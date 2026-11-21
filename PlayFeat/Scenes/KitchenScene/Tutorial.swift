import SpriteKit

/// The tutorial reads the same bubbles, stations and customer seats the player
/// interacts with. Only gameplay events commit progress. Drawing stays inside
/// SpriteKit, so following a moving bubble never publishes SwiftUI state.
final class KitchenTutorial: SKNode {
    typealias Lesson = TutorialProgress.Lesson

    private(set) var progress: TutorialProgress
    private let isBuffet: Bool
    private let artwork = TutorialHandGuide()
    private let tags = SKNode()
    private let feedback = SKNode()
    private let patienceHalo = SKShapeNode()
    private let motes = SKNode()
    private var feedbackUntil: TimeInterval?
    private var feedbackSeat: Int?
    private var feedbackSymbol: String?
    private var lastAngryArrival: TimeInterval?
    private var angryUntil: TimeInterval?
    private var badges: [Int: SKLabelNode] = [:]
    private var steam: [SKShapeNode] = []
    private var dust: [SKShapeNode] = []
    private var feedbackIcon: SKSpriteNode?
    var reduceMotion = false

    init(isBuffet: Bool, progress: TutorialProgress = TutorialProgress()) {
        self.isBuffet = isBuffet
        self.progress = progress
        super.init()
        artwork.zPosition = KitchenScene.handZ - 1
        tags.zPosition = KitchenScene.handZ - 2
        feedback.zPosition = KitchenScene.handZ - 3
        motes.zPosition = -1
        for layer in [artwork, tags, feedback, motes] { addChild(layer) }
        patienceHalo.strokeColor = UIColor(named: "StarYellow") ?? .yellow
        patienceHalo.fillColor = .clear
        feedback.addChild(patienceHalo)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func placed(_ item: String, on station: KitchenBubbleNode.Placement, levelID: String) {
        switch (item, station) {
        case (KitchenMenu.rawFlatbread, .cooker(.grill, _)) where levelID == "1-1":
            progress.learn(.grillBread)
        case (KitchenMenu.bakedFlatbread, .plate) where levelID == "1-1":
            progress.learn(.plateBread)
        case (KitchenMenu.rawNoodles, .cooker(.pot, _)):
            progress.learn(.boilNoodles)
        case (KitchenMenu.boiledNoodles, .plate):
            progress.learn(.bowlNoodles)
        case (KitchenMenu.rawClam, .cooker(.grill, _)):
            progress.learn(.grillClam)
        default:
            break
        }
    }

    func assembled(_ dish: String, levelID: String) {
        if levelID == "1-1", dish == KitchenMenu.pepperFlatbread {
            progress.learn(.addPepper)
            progress.learn(.plateBread)
        }
        if dish == KitchenMenu.slimyTentacles { progress.learn(.fillGlass) }
    }

    func served(_ dish: String, to customer: SeatedCustomer) {
        progress.serve(dish)
        if customer.type == .angry { progress.learn(.angryCustomer) }
        if dish == KitchenMenu.pepperFlatbread {
            // Handle completing the recipe before cues can appear, including
            // a topping-first order of assembly.
            progress.learn(.grillBread)
            progress.learn(.plateBread)
            progress.learn(.addPepper)
            progress.learn(.servePepper)
        }
        if dish == KitchenMenu.starCookie { progress.learn(.buildCookie) }
        if dish == KitchenMenu.slimyTentacles { progress.learn(.fillGlass) }
    }

    func discardedBurntBread() { progress.learn(.discardBurnt) }

    func refused(_ item: String, at station: KitchenBubbleNode.Placement, in scene: KitchenScene) {
        guard let day = scene.day, day.isRunning, day.level.id == "2-1",
              item == KitchenMenu.rawNoodles, case .plate = station,
              !progress.hasLearned(.rawNoodleRefusal) else { return }
        progress.learn(.rawNoodleRefusal)
        feedbackSeat = nil
        patienceHalo.isHidden = true
        showFeedback(texture: "KitchenPot", at: scene.centre(of: station), in: scene, until: day.elapsed + 2)
    }

    func update(in scene: KitchenScene) {
        guard let day = scene.day, day.isRunning, !day.isOver, !day.isRoundOver else {
            artwork.isHidden = true
            tags.isHidden = true
            feedback.isHidden = true
            motes.isHidden = true
            return
        }
        artwork.show(cue(in: scene, day: day), at: day.elapsed, scale: scene.layout.scale,
                     reduceMotion: reduceMotion)
        updateCustomers(day, in: scene)
        updateMotes(day, in: scene)
    }

    struct Cue {
        let lesson: Lesson
        let source: CGPoint?
        let destination: CGRect
        var carrying = false
        var serves = false
    }

    /// Resolve live targets each frame, including a replacement bubble after a
    /// miss. Prefer the next usable step when food has already moved ahead.
    func cue(in scene: KitchenScene, day: KitchenDay) -> Cue? {
        let level = day.level.id
        if level == "1-1",
           let customer = day.presentCustomers.first(where: { $0.dish == KitchenMenu.pepperFlatbread }) {
            let spot = scene.layout.sceneRect(scene.layout.seat(at: customer.seat).serveArea)
            if let cue = move(.servePepper, item: KitchenMenu.pepperFlatbread, to: spot, in: scene,
                              serves: true) { return cue }
            let breadOnPlate = scene.plates.firstIndex { $0.contents.contains(KitchenMenu.bakedFlatbread) }
            if let index = breadOnPlate {
                return move(.addPepper, item: KitchenMenu.pepper, to: .plate(index), in: scene)
            }
            if let cue = move(.plateBread, item: KitchenMenu.bakedFlatbread, toward: .plate(0), in: scene) {
                return cue
            }
            if !scene.cookers.values.contains(where: { $0.slots.contains { $0 != nil } }) {
                return move(.grillBread, item: KitchenMenu.rawFlatbread, toward: .cooker(.grill, slot: 0), in: scene)
            }
        }
        if level == "1-2", !progress.hasLearned(.discardBurnt),
           let burnt = available(KitchenMenu.burntFlatbread, in: scene) {
            let window = scene.layout.sceneRect(KitchenLayout.window)
            let point = CGPoint(x: min(max(burnt.position.x, window.minX + scene.bubbleRadius),
                                        window.maxX - scene.bubbleRadius),
                                y: window.minY + scene.bubbleRadius * 1.8)
            return Cue(lesson: .discardBurnt, source: burnt.position,
                       destination: CGRect(x: point.x - 26, y: point.y - 26, width: 52, height: 52),
                       carrying: burnt.heldBy != nil)
        }
        if level == "2-1" {
            if let cue = move(.bowlNoodles, item: KitchenMenu.boiledNoodles, toward: .plate(0), in: scene) {
                return cue
            }
            if scene.cookers[.pot]?.slots.first.flatMap({ $0 }) == nil {
                return move(.boilNoodles, item: KitchenMenu.rawNoodles, toward: .cooker(.pot, slot: 0), in: scene)
            }
        }
        if (level == "1-4" || isBuffet),
           day.presentCustomers.contains(where: { $0.dish == KitchenMenu.slimyTentacles }) {
            return move(.fillGlass, item: KitchenMenu.tentacle, toward: .glass(0), in: scene)
                ?? move(.fillGlass, item: KitchenMenu.slime, toward: .glass(0), in: scene)
                ?? highlight(.fillGlass, station: .glass(0), in: scene)
        }
        if (level == "2-3" || isBuffet),
           day.presentCustomers.contains(where: { $0.dish == KitchenMenu.clamNoodles }) {
            return move(.grillClam, item: KitchenMenu.rawClam, toward: .cooker(.grill, slot: 0), in: scene)
                ?? highlight(.grillClam, station: .cooker(.grill, slot: 0), in: scene)
        }
        if (level == "2-4" || isBuffet),
           day.presentCustomers.contains(where: { $0.dish == KitchenMenu.starCookie }),
           available(KitchenMenu.starCookie, in: scene) == nil {
            return move(.buildCookie, item: KitchenMenu.seaCookie, toward: .glass(0), in: scene)
                ?? move(.buildCookie, item: KitchenMenu.starfishSugar, toward: .glass(0), in: scene)
                ?? highlight(.buildCookie, station: .glass(0), in: scene)
        }
        return nil
    }

    private func available(_ item: String, in scene: KitchenScene) -> KitchenBubbleNode? {
        scene.bubbles.first {
            $0.ingredient == item && $0.heldBy != nil
        } ?? scene.bubbles.first {
            $0.ingredient == item && !$0.isRefused(at: scene.day?.elapsed ?? 0)
                && !scene.isSinkingBehindTable($0) && scene.frame.contains($0.position)
        }
    }

    private func move(_ lesson: Lesson, item: String, toward station: KitchenBubbleNode.Placement,
                      in scene: KitchenScene) -> Cue? {
        guard !progress.hasLearned(lesson),
              let destination = scene.stations.first(where: {
                  ($0 == station || $0.isForAssembly && station.isForAssembly && sameVessel($0, station))
                      && scene.accepts(item, on: $0)
              }) else { return nil }
        return move(lesson, item: item, to: destination, in: scene)
    }

    private func sameVessel(_ lhs: KitchenBubbleNode.Placement, _ rhs: KitchenBubbleNode.Placement) -> Bool {
        switch (lhs, rhs) {
        case (.plate, .plate), (.glass, .glass): true
        default: false
        }
    }

    private func move(_ lesson: Lesson, item: String, to station: KitchenBubbleNode.Placement,
                      in scene: KitchenScene) -> Cue? {
        guard scene.stations.contains(station), scene.accepts(item, on: station),
              let node = available(item, in: scene), node.placement != station else { return nil }
        return move(lesson, item: item, to: scene.layout.sceneRect(scene.artRect(of: station)), in: scene)
    }

    private func move(_ lesson: Lesson, item: String, to rect: CGRect, in scene: KitchenScene,
                      serves: Bool = false) -> Cue? {
        guard !progress.hasLearned(lesson), let node = available(item, in: scene) else { return nil }
        return Cue(lesson: lesson, source: node.position, destination: rect,
                   carrying: node.heldBy != nil, serves: serves)
    }

    private func highlight(_ lesson: Lesson, station: KitchenBubbleNode.Placement,
                           in scene: KitchenScene) -> Cue? {
        guard !progress.hasLearned(lesson), scene.stations.contains(station) else { return nil }
        return Cue(lesson: lesson, source: nil, destination: scene.layout.sceneRect(scene.artRect(of: station)))
    }

    private static let newDishLevels: [String: String] = [
        KitchenMenu.mushroomFlatbread: "1-3", KitchenMenu.slimyTentacles: "1-4",
        KitchenMenu.urchinNoodles: "2-2", KitchenMenu.clamNoodles: "2-3", KitchenMenu.starCookie: "2-4",
    ]

    private func updateCustomers(_ day: KitchenDay, in scene: KitchenScene) {
        tags.isHidden = false
        let scale = scene.layout.scale
        var tagged: Set<Int> = []
        for customer in day.presentCustomers {
            let sheet = scene.layout.sceneRect(scene.layout.seat(at: customer.seat).orderSheet)
            let isNewDish = Self.newDishLevels[customer.dish].map { $0 == day.level.id || isBuffet } ?? false
            let isNewAngry = isBuffet && customer.type == .angry && !progress.hasLearned(.angryCustomer)
            if (isNewDish && !progress.hasServed(customer.dish)) || isNewAngry {
                tagged.insert(customer.seat)
                let badge = badges[customer.seat] ?? makeBadge(at: customer.seat)
                badge.setScale(scale)
                badge.position = CGPoint(x: sheet.midX + 55 * scale, y: sheet.maxY - 19 * scale)
            }
            if day.level.id == "1-1", !progress.hasLearned(.patience),
               KitchenRules.PatienceZone(patienceLeft: day.patienceShown(for: customer)) == .yellow {
                progress.learn(.patience)
                feedbackSeat = customer.seat
                let barY = sheet.maxY - 38 * scale
                let bar = CGRect(x: sheet.midX - 71 * scale, y: barY - 9 * scale,
                                 width: 142 * scale, height: 18 * scale)
                patienceHalo.path = CGPath(roundedRect: bar, cornerWidth: 9 * scale,
                                           cornerHeight: 9 * scale, transform: nil)
                patienceHalo.lineWidth = 3 * scale
                patienceHalo.isHidden = false
                showFeedback(texture: "StopwatchIcon",
                             at: CGPoint(x: sheet.maxX - 21 * scale, y: barY),
                             in: scene, until: day.elapsed + 2)
            }
            if customer.type == .angry, customer.seatedAt != lastAngryArrival {
                lastAngryArrival = customer.seatedAt
                angryUntil = day.elapsed + 2
            }
            if customer.type == .angry {
                updateSteam(above: scene.layout.sceneRect(scene.layout.seat(at: customer.seat).alien),
                            at: day.elapsed, scale: scale)
            }
        }
        for seat in badges.keys where !tagged.contains(seat) { badges[seat]?.isHidden = true }
        for seat in tagged { badges[seat]?.isHidden = false }
        if !day.presentCustomers.contains(where: { $0.type == .angry }) {
            steam.forEach { $0.isHidden = true }
        }
        let showingFeedback = feedbackUntil.map { $0 > day.elapsed } ?? false
        let seatStillPresent = feedbackSeat.map { seat in day.presentCustomers.contains { $0.seat == seat } } ?? true
        feedback.isHidden = !showingFeedback || !seatStillPresent
        if !feedback.isHidden, let until = feedbackUntil {
            feedbackIcon?.alpha = reduceMotion ? 1 : 0.72 + 0.28 * cos((until - day.elapsed) * 8)
            patienceHalo.alpha = feedbackIcon?.alpha ?? 1
        }
        if !showingFeedback { feedbackSeat = nil }
    }

    private func makeBadge(at seat: Int) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: Atkinson.bold)
        label.text = AppLocalization.string("New")
        label.fontSize = 22
        label.fontColor = UIColor(named: "Purple900") ?? .black
        label.verticalAlignmentMode = .center
        let pill = SKShapeNode(rectOf: CGSize(width: 72, height: 33), cornerRadius: 16)
        pill.fillColor = UIColor(named: "StarYellow") ?? .yellow
        pill.strokeColor = .white
        pill.lineWidth = 2
        pill.zPosition = -1
        label.addChild(pill)
        tags.addChild(label)
        badges[seat] = label
        return label
    }

    private func showFeedback(texture: String, at position: CGPoint, in scene: KitchenScene, until: TimeInterval) {
        let icon = feedbackIcon ?? SKSpriteNode()
        if feedbackIcon == nil {
            feedback.addChild(icon)
            feedbackIcon = icon
        }
        if feedbackSymbol != texture {
            icon.texture = SKTexture(imageNamed: texture)
            feedbackSymbol = texture
        }
        let size = scene.layout.length(44)
        icon.size = CGSize(width: size, height: size)
        icon.position = position
        feedbackUntil = until
    }

    private func updateSteam(above alien: CGRect, at elapsed: TimeInterval, scale: CGFloat) {
        guard let until = angryUntil, elapsed < until else {
            steam.forEach { $0.isHidden = true }
            return
        }
        if steam.isEmpty {
            steam = (0..<3).map { _ in
                let puff = SKShapeNode(circleOfRadius: 10)
                puff.fillColor = .white.withAlphaComponent(0.85)
                puff.strokeColor = .clear
                tags.addChild(puff)
                return puff
            }
        }
        let age = CGFloat(2 - (until - elapsed))
        for (index, puff) in steam.enumerated() {
            let lane = CGFloat(index)
            puff.isHidden = false
            puff.setScale(scale)
            puff.position = CGPoint(x: alien.midX + (55 + lane * 18) * scale,
                                    y: alien.midY + (22 + lane * 14 + (reduceMotion ? 0 : age * 36)) * scale)
            puff.alpha = reduceMotion ? 0.85 : min(1, (2 - age) * 1.2)
        }
    }

    private func updateMotes(_ day: KitchenDay, in scene: KitchenScene) {
        motes.isHidden = reduceMotion
        guard !reduceMotion else { return }
        if dust.isEmpty {
            dust = (0..<10).map { index in
                let dot = SKShapeNode(circleOfRadius: index.isMultiple(of: 3) ? 3 : 2)
                dot.fillColor = .white.withAlphaComponent(0.32)
                dot.strokeColor = .clear
                motes.addChild(dot)
                return dot
            }
        }
        let window = scene.layout.sceneRect(KitchenLayout.window)
        guard window.height > 0 else { return }
        let motion = FallMotion(gravity: day.level.gravity, kitchenHeight: window.maxY)
        let speed = abs(motion.releasedVelocity(after: 1).dy)
        for (index, node) in dust.enumerated() {
            let travel = (CGFloat(day.elapsed) * speed + CGFloat(index) / CGFloat(dust.count) * window.height)
                .truncatingRemainder(dividingBy: window.height)
            let y = day.level.gravity.direction.pullsTowardTable ? window.maxY - travel : window.minY + travel
            node.position = CGPoint(x: window.minX + (CGFloat(index) + 0.5) / CGFloat(dust.count) * window.width, y: y)
            node.setScale(scene.layout.scale)
        }
    }
}
