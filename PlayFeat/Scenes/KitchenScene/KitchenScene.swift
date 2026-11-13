//
//  KitchenScene.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  The transparent SpriteKit layer of a planet kitchen: ingredient bubbles
//  drifting through the window, and the player's hands carrying them. A dish
//  let go in a customer's serve area goes to them if they ordered it, a
//  bubble let go over the trash hole is thrown away, over a station that
//  takes it (grill, plate, glass) it is put down there, over a storage box it
//  is parked, and anywhere else it falls out of the kitchen.
//
//  The art underneath is SwiftUI (KitchenBackdrop); both place things with
//  KitchenLayout, so the boxes and the hole are where they are drawn.
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
    static let bubbleArtRadius: CGFloat = 80
    static let heldZ: CGFloat = 100
    static let glowZ: CGFloat = 60
    /// Parked food is drawn smaller, to sit inside its box.
    static let parkedScale: CGFloat = 0.7

    let grabSlack: CGFloat = 30
    let dragSmoothing: CGFloat = 0.5
    let releaseDelay: TimeInterval = 0.18
    let heldHandGrace: TimeInterval = 0.35

    // MARK: - State

    var bubbles: [KitchenBubbleNode] = []
    var storage = StorageTable<KitchenBubbleNode>(slotCount: 0)
    var grill = Grill()
    var plate = AssemblyStation.plate
    var glass = AssemblyStation.glass
    var hands: [Int: KitchenHand] = [:]
    var glows: [Int: HandGlowNode] = [:]
    var lastUpdateTime: TimeInterval = 0

    private var pantry: Set<String> = []
    private var pendingBubbles: [LevelData.BubbleEntry] = []
    private var spawnTimes: [TimeInterval] = []
    private var spawner: BubbleSpawner?
    private var generator = SystemRandomNumberGenerator()

    var layout: KitchenLayout { KitchenLayout(screenSize: size) }
    var bubbleRadius: CGFloat { layout.length(Self.bubbleArtRadius) }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Loads the day's bubble schedule. Call once, before the scene runs.
    func prepare(for day: KitchenDay, pantry: Set<String>) {
        self.day = day
        self.pantry = pantry
        let spawner = BubbleSpawner(level: day.level)
        self.spawner = spawner
        pendingBubbles = spawner.starterBubbles
        spawnTimes = spawner.spawnTimes
        let slotCount = min(day.level.storageSlots, KitchenLayout.storageSlots.count)
        storage = StorageTable(slotCount: slotCount)
    }

    // MARK: - Per-frame update

    override func update(_ currentTime: TimeInterval) {
        let frameDelta = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime

        guard let day else { return }
        let before = day.elapsed
        day.tick(at: currentTime)
        let playDelta = day.elapsed - before

        if day.isRunning { spawnDueBubbles(at: day.elapsed) }
        moveLooseBubbles(by: playDelta, now: day.elapsed)
        updateGrill(now: day.elapsed)
        updateHands(now: currentTime, frameDelta: frameDelta)
    }

    // MARK: - Spawning

    private func spawnDueBubbles(at time: TimeInterval) {
        while let next = pendingBubbles.first, next.at <= time {
            pendingBubbles.removeFirst()
            spawnBubble(next)
        }
        while let next = spawnTimes.first, next <= time, let spawner {
            spawnTimes.removeFirst()
            // ponytail: dish recipes don't exist yet, so every pantry item
            // counts as useful; pass the open orders' ingredients once they do.
            spawnBubble(spawner.spawnedBubble(at: next, needed: pantry, pantry: pantry, using: &generator))
        }
    }

    private func spawnBubble(_ entry: LevelData.BubbleEntry) {
        guard let day else { return }
        let node = KitchenBubbleNode(ingredient: entry.ingredient, radius: bubbleRadius)
        let window = layout.sceneRect(KitchenLayout.window)
        node.position = day.level.gravity.direction.entryPoint(lane: entry.lane, in: window)
        node.setScale(0.6)
        node.run(.scale(to: 1, duration: 0.2))
        addChild(node)
        bubbles.append(node)
    }

    // MARK: - Drifting and falling

    /// Bubbles cross the window in the level's `bubbleLifeSec` and pop as they
    /// leave it; a dropped item falls with the level's gravity until it's off
    /// screen. Both move in play time, so a pause freezes them.
    private func moveLooseBubbles(by playDelta: TimeInterval, now: TimeInterval) {
        guard playDelta > 0, let level = day?.level else { return }
        let window = layout.sceneRect(KitchenLayout.window)
        let motion = FallMotion(gravity: level.gravity, kitchenHeight: window.maxY)
        let drift = motion.bubbleVelocity(crossing: window.height, lifeSec: level.bubbleLifeSec)

        for node in bubbles where node.heldBy == nil && node.placement == nil {
            let velocity = node.fallingSince.map { motion.releasedVelocity(after: now - $0) } ?? drift
            node.position.x += velocity.dx * playDelta
            node.position.y += velocity.dy * playDelta

            let bounds = node.fallingSince == nil ? window : frame
            if !bounds.insetBy(dx: -node.radius, dy: -node.radius).contains(node.position) {
                remove(node)
            }
        }
    }

    // MARK: - Where a let-go item ends up

    /// Parks, trashes or drops `node`, depending on where it was let go.
    func settle(_ node: KitchenBubbleNode) {
        node.heldBy = nil
        node.zPosition = 2

        if serve(node) {
            return
        } else if layout.sceneRect(KitchenLayout.trashHole).contains(node.position) {
            audio?.play(.reset)
            remove(node)
        } else if let station = station(taking: node) {
            put(node, on: station)
        } else if let slot = freeStorageSlot(near: node.position) {
            park(node, in: slot)
        } else {
            node.fallingSince = day?.elapsed ?? 0
        }
    }

    private func freeStorageSlot(near point: CGPoint) -> Int? {
        storage.slots.indices.first { slot in
            storage.slots[slot] == nil
                && layout.sceneRect(KitchenLayout.storageBoxes[slot]).contains(point)
        }
    }

    private func park(_ node: KitchenBubbleNode, in slot: Int) {
        do {
            try storage.place(node, in: slot)
        } catch {
            node.fallingSince = day?.elapsed ?? 0
            return
        }
        setDown(node, at: .storage(slot: slot),
                 position: layout.scenePoint(KitchenLayout.storageSlots[slot]))
    }

    /// Settles `node` into a box or onto a station: bare food, slid into
    /// place, out of reach of gravity.
    func setDown(_ node: KitchenBubbleNode, at placement: KitchenBubbleNode.Placement, position: CGPoint) {
        node.placement = placement
        node.fallingSince = nil
        node.removeAllActions()
        node.run(.group([
            .move(to: position, duration: 0.15),
            .scale(to: Self.parkedScale, duration: 0.15),
        ]))
        audio?.play(.bubblePut)
    }

    /// Lifts an item back off wherever it was put down, ready to be carried.
    func unpark(_ node: KitchenBubbleNode) {
        guard let placement = node.placement else { return }
        switch placement {
        case .storage(let slot): _ = try? storage.take(from: slot)
        case .grill, .plate, .glass: liftOffStation(node, at: placement)
        }
        node.placement = nil
        node.removeAllActions()
        node.setScale(1)
    }

    func remove(_ node: KitchenBubbleNode) {
        bubbles.removeAll { $0 === node }
        node.pop()
    }
}
