//
//  Hands.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  The kitchen's hand handling: a cartoon hand follows every hand, a fist grabs
//  the nearest bubble (or item put down) it touches and it grows a little
//  while held, a dish carried near the
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
            let cursor = convertPoint(fromView: handInput.cursor(for: hand, in: viewSize))
            updateHandCursor(for: hand, at: cursor)
        }
        retireVanishedHandCursors(stillLive: liveIDs)

        guard let day, day.isRunning, !day.isOver, !day.isRoundOver else {
            letGoOfEverythingHeld()
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
            let pinch = handCursors[hand.id]?.heldItemPosition ?? cursor
            carry(tracked, toward: pinch, frameDelta: frameDelta)
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
        node.liftedFrom = node.placement
        unpark(node)
        node.move(toParent: self)
        node.heldBy = handID
        node.fallingSince = nil
        node.isFrozenInAir = false
        node.zPosition = Self.heldZ
        node.removeAllActions()
        node.run(.scale(to: Self.heldScale, duration: Self.heldScaleDuration))
        hand.held = node
        audio?.play(.bubbleGrab)
    }

    /// Held food sits in the drawn hand's pinch, not on the palm.
    private func carry(_ hand: KitchenHand, toward pinch: CGPoint, frameDelta: TimeInterval) {
        guard let node = hand.held else { return }
        let target = GameScene.clamped(pinch, radius: node.radius, in: size)
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

        audio?.play(.bubblePut) // The bubble pops on an intentional release.
        settle(node)
        hand.held = nil
        hand.openSince = nil
    }

    /// The nearest free bubble or put-down item any joint of the hand touches.
    private func grabCandidate(touchedBy joints: [CGPoint]) -> KitchenBubbleNode? {
        var best: (node: KitchenBubbleNode, distance: CGFloat)?
        let now = day?.elapsed ?? 0
        for node in bubbles where node.heldBy == nil && !node.isRefused(at: now) && !isSinkingBehindTable(node) {
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

    /// Play stopped mid-carry. When a marathon round ends, everything held
    /// hangs where it is while the player picks a card, ready to be taken
    /// up again next round; otherwise it is let go where it is.
    func letGoOfEverythingHeld() {
        if let day, day.isRoundOver, !day.isOver {
            freezeEverythingHeld()
        } else {
            dropEverythingHeld()
        }
    }

    private func dropEverythingHeld() {
        for hand in hands.values {
            if let node = hand.held { settle(node) }
        }
        hands.removeAll()
    }

    private func freezeEverythingHeld() {
        for hand in hands.values {
            guard let node = hand.held else { continue }
            node.heldBy = nil
            node.isFrozenInAir = true
            node.run(.scale(to: 1, duration: Self.heldScaleDuration))
        }
        hands.removeAll()
    }

    // MARK: - Hand cursors

    private func updateHandCursor(for hand: HandData, at position: CGPoint) {
        let cursor = handCursors[hand.id] ?? {
            let node = HandCursorNode(chirality: hand.chirality, bubbleRadius: bubbleRadius)
            node.zPosition = Self.handZ
            addChild(node)
            handCursors[hand.id] = node
            return node
        }()
        cursor.setVisible(true)
        cursor.position = position
        cursor.setChirality(hand.chirality)
        cursor.setGrabbing(hand.isClosedFist)
    }

    private func retireVanishedHandCursors(stillLive: Set<Int>) {
        for (id, cursor) in handCursors where !stillLive.contains(id) {
            cursor.fadeOutAndRemove()
            handCursors[id] = nil
        }
    }
}
