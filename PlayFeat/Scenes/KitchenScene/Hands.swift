//
//  Hands.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  The kitchen's hand handling: a cartoon hand follows every hand, a fist grabs
//  the nearest bubble (or parked item) it touches, and a hand that stays open
//  lets go. Same feel as the classic board — same easing, release debounce
//  and dropout grace — so a player moving between modes notices no change.
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
            updateHandCursor(for: hand.id, at: cursor, isFist: hand.isClosedFist)
        }
        retireVanishedHandCursors(stillLive: liveIDs)

        guard let day, day.isRunning, !day.isOver else {
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
            let pinch = handCursors[hand.id]?.heldItemPosition ?? cursor
            carry(tracked, toward: pinch, frameDelta: frameDelta)
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

    /// Held food sits in the drawn hand's pinch, not on the palm.
    private func carry(_ hand: KitchenHand, toward pinch: CGPoint, frameDelta: TimeInterval) {
        guard let node = hand.held else { return }
        let target = GameScene.clamped(pinch, radius: node.radius, in: size)
        node.position = node.position.eased(
            toward: target,
            by: GameScene.easing(base: dragSmoothing, delta: frameDelta)
        )
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

    /// The nearest free bubble or parked item any joint of the hand touches.
    private func grabCandidate(touchedBy joints: [CGPoint]) -> KitchenBubbleNode? {
        var best: (node: KitchenBubbleNode, distance: CGFloat)?
        for node in bubbles where node.heldBy == nil {
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

    // MARK: - Hand cursors

    private func updateHandCursor(for id: Int, at position: CGPoint, isFist: Bool) {
        let cursor = handCursors[id] ?? {
            let side = HandCursorNode.side(at: position, in: frame)
            let node = HandCursorNode(side: side, bubbleRadius: bubbleRadius)
            node.zPosition = Self.handZ
            addChild(node)
            handCursors[id] = node
            return node
        }()
        cursor.setVisible(true)
        cursor.position = position
        cursor.setGrabbing(isFist)
    }

    private func retireVanishedHandCursors(stillLive: Set<Int>) {
        for (id, cursor) in handCursors where !stillLive.contains(id) {
            cursor.fadeOutAndRemove()
            handCursors[id] = nil
        }
    }
}
