//
//  HandCursorNode.swift
//  PlayFeat
//  Created by Owen Limantoro on 15/11/26.
//
//  The cartoon hand drawn over each tracked hand: open while the hand is
//  open, pinching while it grips. Shows players where their hand is and
//  whether the game reads it as grabbing. The art is a placeholder.
//

import SpriteKit
import Vision

final class HandCursorNode: SKNode {

    /// Open and pinching art share one layout, so the palm stays put when
    /// the picture swaps.
    static let openArt = "HandCursorOpen"
    static let pinchArt = "HandCursorPinch"
    private static let openTexture = SKTexture(imageNamed: openArt)
    private static let pinchTexture = SKTexture(imageNamed: pinchArt)

    /// The palm's centre in the art, so the palm sits on the tracked point.
    private static let palmAnchor = CGPoint(x: 0.49, y: 0.425)

    /// Where the thumb and index tips meet in the pinching art (unit
    /// coordinates, origin bottom-left). Held food is drawn here.
    private static let pinchInArt = CGPoint(x: 0.05, y: 0.6)

    /// The art's size relative to an ingredient bubble's radius: a hand a
    /// little larger than the bubble it grabs.
    static let sizePerBubbleRadius: CGFloat = 2.5

    private static let popKey = "pop"

    private let art: SKSpriteNode
    private let bubbleRadius: CGFloat
    private var chirality: VNChirality = .unknown
    private var isGrabbing = false

    /// The art is a right hand, mirrored when Vision identifies a left hand.
    /// Until the first known reading, an unknown hand uses the unmirrored art.
    init(chirality: VNChirality, bubbleRadius: CGFloat) {
        art = SKSpriteNode(texture: Self.openTexture)
        self.bubbleRadius = bubbleRadius
        super.init()

        let length = bubbleRadius * Self.sizePerBubbleRadius
        art.size = CGSize(width: length, height: length)
        art.anchorPoint = Self.palmAnchor
        addChild(art)
        setChirality(chirality)
    }

    /// Where held food goes: the drawn fingertips, not the palm. Follows
    /// the art rather than the real fingertips, so the food always sits in
    /// the cartoon hand's pinch whatever size the hand is drawn.
    var heldItemPosition: CGPoint {
        let offset = Self.pinchOffset(chirality: chirality, bubbleRadius: bubbleRadius)
        return CGPoint(x: position.x + offset.dx, y: position.y + offset.dy)
    }

    /// From the palm to the drawn pinch, mirrored for a left hand.
    static func pinchOffset(chirality: VNChirality, bubbleRadius: CGFloat) -> CGVector {
        let length = bubbleRadius * sizePerBubbleRadius
        let mirror: CGFloat = chirality == .left ? 1 : -1
        return CGVector(
            dx: (pinchInArt.x - palmAnchor.x) * length * mirror,
            dy: (pinchInArt.y - palmAnchor.y) * length
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Unknown readings preserve the previous artwork and held-food orientation.
    func setChirality(_ chirality: VNChirality) {
        guard chirality != .unknown, chirality != self.chirality else { return }
        self.chirality = chirality
        
        // Mirror the art for a left hand.
        art.xScale = chirality == .left ? 1 : -1
    }

    /// Shows the pinching art while the hand grips, the open art otherwise.
    func setGrabbing(_ grabbing: Bool) {
        guard grabbing != isGrabbing else { return }
        isGrabbing = grabbing
        art.texture = grabbing ? Self.pinchTexture : Self.openTexture

        // A quick pop on the change, so closing into a grab is felt rather
        // than just seen.
        removeAction(forKey: Self.popKey)
        run(.sequence([
            .scale(to: grabbing ? 0.9 : 1.08, duration: 0.08),
            .scale(to: 1, duration: 0.14)
        ]), withKey: Self.popKey)
    }

    func setVisible(_ visible: Bool) {
        isHidden = !visible
    }

    /// Fades away and then takes itself off the scene, for a hand that has
    /// really gone rather than one blinking through a dropped frame.
    func fadeOutAndRemove(duration: TimeInterval = 0.25) {
        removeAllActions()
        run(.sequence([
            .fadeOut(withDuration: duration),
            .removeFromParent()
        ]))
    }
}
