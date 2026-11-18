//
//  KitchenScene.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  The transparent SpriteKit layer of a planet kitchen: ingredient bubbles
//  drifting through the window, and the player's hands carrying them. A dish
//  let go in a customer's serve area goes to them if they ordered it, over a
//  station that takes it (the grill, a plate, a glass) it is put down there,
//  and anywhere else it falls and slides down behind the table until it is
//  gone — which is also how a wrong item is thrown away. While an
//  item is carried, the tool it would land on glows green
//  (KitchenScene/DropTargets.swift).
//
//  The art underneath is SwiftUI (KitchenBackdrop); both place things with
//  KitchenLayout, so the stations are where they are drawn.
//  Hand handling lives in KitchenScene/Hands.swift, the stations in
//  KitchenScene/Stations.swift, handing dishes over in KitchenScene/ServeAreas.swift.
//

import SpriteKit

final class KitchenScene: SKScene {

    // MARK: - Injected dependencies

    weak var day: KitchenDay?
    weak var handInput: (any HandInputSource)?
    weak var audio: (any SoundPlaying)?

    // MARK: - Tuning

    /// Bubble radius in art points (the Figma "S" bubble is 160 across).
    static let bubbleArtRadius: CGFloat = 70
    static let heldZ: CGFloat = 0
    static let handZ: CGFloat = 60
    /// A pinched item grows to this, so the player sees what they hold.
    static let heldScale: CGFloat = 1.25
    static let heldScaleDuration: TimeInterval = 0.12
    /// Parked food is drawn smaller, to sit inside its box.
    static let parkedScale: CGFloat = 0.8

    /// How wide food sits on a cooking tool and the plate, in art points:
    /// big enough to fill the grill's hot ring and most of the plate.
    static let cookwareFoodWidth: CGFloat = 118

    /// How big an item is drawn where it has been put down.
    static func placedScale(on placement: KitchenBubbleNode.Placement) -> CGFloat {
        switch placement {
        case .cooker, .plate: cookwareFoodWidth / (bubbleArtRadius * 2 * KitchenBubbleNode.foodFill)
        // Whatever is in the glass is drawn as the whole glass, already sized
        // to it (KitchenBubbleNode).
        case .glass: 1
        }
    }

    let grabSlack: CGFloat = 30
    let dragSmoothing: CGFloat = 0.5
    let releaseDelay: TimeInterval = 0.1
    let heldHandGrace: TimeInterval = 0.35

    // MARK: - State

    var bubbles: [KitchenBubbleNode] = []
    /// The day's cooking tools: the grill on Planet 1; the pot, and from
    /// 2-3 the grill, on Planet 2.
    var cookers: [CookingTool.Kind: CookingTool] = [:]
    /// One per plate and glass on the counter, left to right, matching
    /// `plateSpots` and `glassSpots`.
    var plates: [AssemblyStation] = []
    var glasses: [AssemblyStation] = []
    /// Where the plates and glasses stand, in art points.
    var plateSpots: [CGRect] = []
    var glassSpots: [CGRect] = []
    var hands: [Int: KitchenHand] = [:]
    var handCursors: [Int: HandCursorNode] = [:]
    /// The cooking ring around the item on each cooking-tool slot.
    var cookingGauges: [KitchenBubbleNode.Placement: GrillGaugeNode] = [:]
    /// Green outlines on the tools a carried item would land on.
    var dropGlows: [DropTarget: SKNode] = [:]
    var lastUpdateTime: TimeInterval = 0
    /// Loose items above the table, clipped at its back edge, so whatever
    /// drifts or falls past it slides down behind the table out of sight.
    let behindTable = SKCropNode()

    /// Decides when bubbles come and what they bring: the story day's rule
    /// or the marathon's.
    private var bubbleSupply: (any BubbleSupply)?
    private var generator = SystemRandomNumberGenerator()

    var layout: KitchenLayout { KitchenLayout(screenSize: size) }
    var bubbleRadius: CGFloat { layout.length(Self.bubbleArtRadius) }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
        addChild(behindTable)
        clipBehindTable()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Takes the day and its bubble rule, and sets out its planet's cooking
    /// tools, plates and glasses. Call once, before the scene runs.
    func prepare(for day: KitchenDay, bubbleSupply: any BubbleSupply) {
        self.day = day
        self.bubbleSupply = bubbleSupply
        cookers = kitchen?.cookingTools(on: day.level) ?? [:]
        syncTools()
    }

    /// The rules of the day's planet kitchen.
    var kitchen: PlanetKitchen? {
        day.map { PlanetCatalog.planet($0.level.planet).kitchen }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        clipBehindTable()
    }

    /// Shows `behindTable`'s items only above the table's back edge.
    private func clipBehindTable() {
        let edge = tableEdge
        let mask = SKSpriteNode(color: .white, size: CGSize(width: size.width, height: max(size.height - edge, 0)))
        mask.anchorPoint = .zero
        mask.position = CGPoint(x: 0, y: edge)
        behindTable.maskNode = mask
    }

    // MARK: - Per-frame update

    override func update(_ currentTime: TimeInterval) {
        let frameDelta = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime

        guard let day else { return }
        let before = day.elapsed
        day.tick(at: currentTime)
        let playDelta = day.elapsed - before

        syncTools()
        if day.isRunning, playDelta > 0 { spawnDueBubbles(at: day.elapsed) }
        moveLooseBubbles(by: playDelta, now: day.elapsed)
        updateCookers(now: day.elapsed)
        updateHands(now: currentTime, frameDelta: frameDelta)
        updateDropGlows()
    }

    // MARK: - Spawning

    private func spawnDueBubbles(at time: TimeInterval) {
        guard var supply = bubbleSupply, let day else { return }
        let due = supply.bubbles(at: time, in: bubbleContext(for: day), using: &generator)
        bubbleSupply = supply
        due.forEach(spawnBubble)
    }

    /// The kitchen as the bubble supply sees it this frame.
    private func bubbleContext(for day: KitchenDay) -> BubbleContext {
        let customers = day.presentCustomers.sorted { $0.seatedAt < $1.seatedAt }
        let floating = bubbles.filter(isFloating)
        let patienceLeft = customers.map { $0.secondsLeft(at: day.elapsed) }
        return BubbleContext(
            orders: customers.map(\.dish),
            kitchenItems: bubbles.filter { !isFloating($0) }.map(\.ingredient),
            bubblesOnScreen: floating.map(\.ingredient),
            pool: day.bubblePool,
            busyLanes: Set(floating.filter(isNearEntry).compactMap(\.lane)),
            averagePatienceLeft: patienceLeft.isEmpty ? nil : patienceLeft.reduce(0, +) / Double(patienceLeft.count),
            customerSpacing: day.customerSpacing
        )
    }

    /// Still a bubble drifting through the window: not carried, put down or falling.
    private func isFloating(_ node: KitchenBubbleNode) -> Bool {
        node.heldBy == nil && node.placement == nil && node.fallingSince == nil
    }

    /// Close enough to where bubbles come in that a new one would overlap it.
    private func isNearEntry(_ node: KitchenBubbleNode) -> Bool {
        guard let lane = node.lane, let entry = bubbleEntry(lane: lane) else { return false }
        return node.position.distance(to: entry) < bubbleRadius * 2.4
    }

    /// Where a bubble in `lane` comes into the window, given the day's gravity.
    private func bubbleEntry(lane: Int) -> CGPoint? {
        day?.level.gravity.direction.entryPoint(
            lane: lane, in: layout.sceneRect(KitchenLayout.window), tableClearance: bubbleRadius
        )
    }

    private func spawnBubble(_ entry: LevelData.BubbleEntry) {
        guard let position = bubbleEntry(lane: entry.lane) else { return }
        let node = KitchenBubbleNode(ingredient: entry.ingredient, radius: bubbleRadius, upgraded: upgradedIngredients)
        node.lane = entry.lane
        node.position = position
        node.setScale(0.6)
        node.run(.scale(to: 1, duration: 0.2))
        behindTable.addChild(node)
        bubbles.append(node)
    }

    // MARK: - Drifting and falling

    /// Bubbles cross the window in the level's `bubbleLifeSec` and pop as they
    /// leave it; a dropped item falls with the level's gravity until it's off
    /// screen. Past the table's back edge both carry on down behind it until
    /// they're out of sight. Both move in play time, so a pause freezes them.
    private func moveLooseBubbles(by playDelta: TimeInterval, now: TimeInterval) {
        guard playDelta > 0, let level = day?.level else { return }
        let window = layout.sceneRect(KitchenLayout.window)
        let motion = FallMotion(gravity: level.gravity, kitchenHeight: window.maxY)
        // A bubble's life is timed to when it meets the table, a radius
        // before its centre would reach the window's bottom edge.
        let drift = motion.bubbleVelocity(crossing: window.height - bubbleRadius, lifeSec: level.bubbleLifeSec)

        for node in bubbles where node.heldBy == nil && node.placement == nil {
            // A refused item's fall starts a moment ahead: until then it hangs.
            let velocity = node.fallingSince.map { motion.releasedVelocity(after: now - $0) } ?? drift
            node.position.x += velocity.dx * playDelta
            node.position.y += velocity.dy * playDelta

            let bounds = node.fallingSince == nil ? window : frame
            if isLostBehindTable(node) || !bounds.insetBy(dx: -node.radius, dy: -node.radius).contains(node.position) {
                remove(node)
            }
        }
    }

    /// The table's back edge, in scene points: the bottom of the window.
    var tableEdge: CGFloat { layout.sceneRect(KitchenLayout.window).minY }

    /// Whether a loose item touches the table from in front of its back edge.
    /// The table is drawn in front of the window, so it never shows on top
    /// of the table. Under flipped gravity items float up, away from it.
    func isOverTable(_ node: KitchenBubbleNode) -> Bool {
        guard day?.level.gravity.direction.pullsTowardTable ?? true else { return false }
        return node.position.y - node.radius <= tableEdge
    }

    /// Whether a loose item is gone: one sliding down behind the table once
    /// it has sunk out of sight, anything else (falling off a station) as
    /// soon as it meets the table.
    private func isLostBehindTable(_ node: KitchenBubbleNode) -> Bool {
        node.parent === behindTable ? node.position.y + node.radius <= tableEdge : isOverTable(node)
    }

    /// Already more than half hidden behind the table, out of reach.
    func isSinkingBehindTable(_ node: KitchenBubbleNode) -> Bool {
        node.parent === behindTable && node.position.y < tableEdge
    }

    // MARK: - Where a let-go item ends up

    /// Serves, puts down, refuses or drops `node`, depending on where it was
    /// let go, in the prototype's order: a dish at a customer first, then
    /// the grill and the plates and glasses, else it falls.
    func settle(_ node: KitchenBubbleNode) {
        node.heldBy = nil
        node.zPosition = 2
        node.run(.scale(to: 1, duration: Self.heldScaleDuration))

        if let seat = customerSeat(around: node) {
            serveOrReject(node, at: seat)
        } else if let station = station(under: node) {
            if accepts(node.ingredient, on: station) {
                put(node, on: station)
            } else {
                refuse(node, at: station)
            }
        } else {
            drop(node)
        }
    }

    /// Hangs `node` where it was let go for a moment, out of reach, while
    /// the station that turned it away shakes red; then it falls.
    func refuse(_ node: KitchenBubbleNode, at station: KitchenBubbleNode.Placement) {
        node.fallingSince = (day?.elapsed ?? 0) + KitchenRules.refuseHoldSec
        shakeRed(station)
        audio?.play(.wrongIngredient)
    }

    /// Lets `node` fall (or, under flipped gravity, float) from where it was
    /// let go, down behind the table; let go over the table itself, it goes
    /// at once.
    func drop(_ node: KitchenBubbleNode) {
        if isOverTable(node) {
            remove(node)
        } else {
            node.move(toParent: behindTable)
            node.fallingSince = day?.elapsed ?? 0
        }
    }

    /// Settles `node` onto a station: bare food, slid into place, out of
    /// reach of gravity.
    func setDown(_ node: KitchenBubbleNode, at placement: KitchenBubbleNode.Placement, position: CGPoint) {
        node.placement = placement
        node.fallingSince = nil
        node.removeAllActions()
        node.run(.group([
            .move(to: position, duration: 0.15),
            .scale(to: Self.placedScale(on: placement), duration: 0.15),
        ]))
        audio?.play(.bubblePut)
    }

    /// Lifts an item back off wherever it was put down, ready to be carried.
    func unpark(_ node: KitchenBubbleNode) {
        guard let placement = node.placement else { return }
        liftOffStation(node, at: placement)
        node.placement = nil
        node.removeAllActions()
        node.setScale(1)
    }

    /// What the shop or the marathon's cards have upgraded: drawn with
    /// their premium look.
    var upgradedIngredients: Set<String> { day?.pricing.upgradedIngredients ?? [] }

    func remove(_ node: KitchenBubbleNode) {
        bubbles.removeAll { $0 === node }
        node.pop()
    }
}
