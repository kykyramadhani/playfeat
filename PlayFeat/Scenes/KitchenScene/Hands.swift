//
//  Hands.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  The kitchen's hand handling: a glove follows every hand, a fist grabs
//  the nearest bubble (or item put down) it touches, a dish carried near the
//  customer who ordered it is pulled in, and a hand that stays open lets go.
//  Same feel as the classic board — same easing, release debounce and
//  dropout grace — so a player moving between modes notices no change.
//

import SpriteKit

/// What the kitchen remembers about one hand between frames.
struct KitchenHand {
    var previousState: HandState = .unknown
    var held: KitchenBubbleNode?
    var lastSeen: TimeInterval = 0
    var openSince: TimeInterval?
}

extension KitchenScene {

    func updateHands(now: TimeInterval, frameDelta: TimeInterval) {
        guard let view, let handInput else { return }
        let viewSize = view.bounds.size
        let liveIDs = Set(handInput.hands.map(\.id))

        for hand in handInput.hands {
            updateGlove(for: hand, at: convertPoint(fromView: handInput.cursor(for: hand, in: viewSize)))
        }
        retireVanishedGloves(stillLive: liveIDs)

        guard let day, day.isRunning, !day.isOver, !day.isRoundOver else {
            dropEverythingHeld()
            return
        }
        retireVanishedHands(stillLive: liveIDs, now: now)

        for hand in handInput.hands {
            let cursor = convertPoint(fromView: handInput.cursor(for: hand, in: viewSize))
            let joints = handInput.jointPoints(for: hand, in: viewSize).map(convertPoint(fromView:)) + [cursor]
            let state: HandState = hand.isClosedFist ? .fist : hand.isOpenHand ? .open : .unknown

            var tracked = hands[hand.id] ?? KitchenHand()
            tracked.lastSeen = now
            grabIfClosing(&tracked, handID: hand.id, state: state, joints: joints)
            carry(tracked, toward: cursor, frameDelta: frameDelta)
            pullToCustomer(&tracked)
            releaseIfOpen(&tracked, state: state, now: now)
            tracked.previousState = state
            hands[hand.id] = tracked
        }
    }

    // MARK: - Grab, carry, release

    private func grabIfClosing(_ hand: inout KitchenHand, handID: Int, state: HandState, joints: [CGPoint]) {
        guard state == .fist, hand.previousState != .fist, hand.held == nil,
              let node = grabCandidate(touchedBy: joints) else { return }
        unpark(node)
        node.heldBy = handID
        node.fallingSince = nil
        node.zPosition = Self.heldZ
        hand.held = node
        audio?.play(.bubbleGrab)
    }

    private func carry(_ hand: KitchenHand, toward cursor: CGPoint, frameDelta: TimeInterval) {
        guard let node = hand.held else { return }
        let target = GameScene.clamped(cursor, radius: node.radius, in: size)
        node.position = node.position.eased(
            toward: target,
            by: GameScene.easing(base: dragSmoothing, delta: frameDelta)
        )
    }

    /// A dish carried close to the customer who ordered it is pulled in and
    /// served at once; the hand doesn't have to open.
    private func pullToCustomer(_ hand: inout KitchenHand) {
        guard let node = hand.held, let seat = magnetSeat(for: node) else { return }
        hand.held = nil
        hand.openSince = nil
        node.heldBy = nil
        node.zPosition = 2
        serveOrReject(node, at: seat)
    }

    /// Lets go only once the hand has stayed open, so one misread frame
    /// doesn't drop what the player is carrying.
    private func releaseIfOpen(_ hand: inout KitchenHand, state: HandState, now: TimeInterval) {
        guard let node = hand.held else { return }
        guard state == .open else {
            hand.openSince = nil
            return
        }
        let openedAt = hand.openSince ?? now
        hand.openSince = openedAt
        guard now - openedAt >= releaseDelay else { return }

        settle(node)
        hand.held = nil
        hand.openSince = nil
    }

    /// The nearest free bubble or put-down item any joint of the hand touches.
    private func grabCandidate(touchedBy joints: [CGPoint]) -> KitchenBubbleNode? {
        var best: (node: KitchenBubbleNode, distance: CGFloat)?
        let now = day?.elapsed ?? 0
        for node in bubbles where node.heldBy == nil && !node.isRefused(at: now) {
            guard let nearest = joints.map({ $0.distance(to: node.position) }).min(),
                  nearest <= node.radius + grabSlack,
                  nearest < best?.distance ?? .infinity else { continue }
            best = (node, nearest)
        }
        return best?.node
    }

    // MARK: - Hands that come and go

    /// A hand Vision lost lets go of what it held, after a short grace period
    /// so a brief dropout doesn't drop the item.
    private func retireVanishedHands(stillLive: Set<Int>, now: TimeInterval) {
        for (id, hand) in hands where !stillLive.contains(id) {
            if hand.held != nil, now - hand.lastSeen <= heldHandGrace { continue }
            if let node = hand.held { settle(node) }
            hands[id] = nil
        }
    }

    /// The day paused or ended mid-carry: everything in a hand drops where it is.
    private func dropEverythingHeld() {
        for hand in hands.values {
            if let node = hand.held { settle(node) }
        }
        hands.removeAll()
    }

    // MARK: - Gloves

    private func updateGlove(for hand: HandData, at position: CGPoint) {
        let glove = gloves[hand.id] ?? {
            let node = GloveNode(bubbleRadius: bubbleRadius)
            node.zPosition = Self.glowZ
            addChild(node)
            gloves[hand.id] = node
            return node
        }()
        glove.position = position
        glove.show(pinching: hand.isClosedFist, side: hand.side)
    }

    private func retireVanishedGloves(stillLive: Set<Int>) {
        for (id, glove) in gloves where !stillLive.contains(id) {
            glove.fadeOutAndRemove()
            gloves[id] = nil
        }
    }
}
