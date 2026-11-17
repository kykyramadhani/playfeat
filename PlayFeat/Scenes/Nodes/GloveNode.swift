//
//  GloveNode.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  The space glove drawn over each tracked hand in a planet kitchen: open
//  while the hand is free, pinching while it grabs. The art is a right
//  hand; it is flipped for the player's left hand, as the body pose tells
//  them apart (see HandSideAssigner), wherever on screen the hand is.
//

import SpriteKit

final class GloveNode: SKSpriteNode {
    private static let openTexture = SKTexture(imageNamed: "GloveOpen")
    private static let pinchTexture = SKTexture(imageNamed: "GlovePinch")

    /// The glove is drawn this many times the bubble radius tall.
    private static let heightPerRadius: CGFloat = 1.6

    private let gloveHeight: CGFloat

    init(bubbleRadius: CGFloat) {
        gloveHeight = bubbleRadius * Self.heightPerRadius
        super.init(texture: Self.openTexture, color: .clear, size: .zero)
        resize(to: Self.openTexture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Whether the right-hand art has to be flipped for the hand on `side`.
    static func isMirrored(for side: HandSide) -> Bool {
        side == .left
    }

    /// A hand the body hasn't placed yet keeps whichever way the glove faced.
    func show(pinching: Bool, side: HandSide?) {
        isHidden = false
        let texture = pinching ? Self.pinchTexture : Self.openTexture
        if self.texture !== texture { resize(to: texture) }
        if let side { xScale = Self.isMirrored(for: side) ? -1 : 1 }
    }

    /// Fades away and leaves the scene, for a hand that has really gone.
    func fadeOutAndRemove(duration: TimeInterval = 0.25) {
        removeAllActions()
        run(.sequence([.fadeOut(withDuration: duration), .removeFromParent()]))
    }

    private func resize(to texture: SKTexture) {
        self.texture = texture
        let art = texture.size()
        size = CGSize(width: gloveHeight * art.width / max(art.height, 1), height: gloveHeight)
    }
}
