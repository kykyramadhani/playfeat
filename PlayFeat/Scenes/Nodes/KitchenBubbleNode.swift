//
//  KitchenBubbleNode.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  One planet-kitchen ingredient: food inside the glassy cyan bubble while
//  it drifts or is carried, bare food once parked in a storage box.
//

import SpriteKit

final class KitchenBubbleNode: SKNode {
    let ingredient: String
    let radius: CGFloat

    /// `HandData.id` of the hand carrying this, if any.
    var heldBy: Int?
    /// Play time it was let go mid-air, while it falls. Nil otherwise.
    var fallingSince: TimeInterval?
    /// The storage box it sits in, if parked.
    var parkedIn: Int? {
        didSet { shell?.isHidden = parkedIn != nil }
    }

    private var shell: SKSpriteNode?

    /// The food fills at most this share of the bubble, as the Figma
    /// component asks ("keep food centered inside 60% diameter").
    private static let foodFill: CGFloat = 0.6
    /// The bubble art is 200×206 around a glass circle of radius 77 centred
    /// at (100, 100); these turn that into sizes for `radius`.
    private static let artWidthPerRadius: CGFloat = 200 / 77
    private static let artAspect: CGFloat = 206.3 / 200
    private static let glassCentreDrop: CGFloat = 3.15 / 77

    init(ingredient: String, radius: CGFloat) {
        self.ingredient = ingredient
        self.radius = radius
        super.init()

        if let texture = TrimmedArt.texture(named: KitchenArt.ingredientImage(ingredient)) {
            let food = SKSpriteNode(texture: texture)
            food.size = IngredientNode.aspectFit(texture.size(), into: radius * 2 * Self.foodFill)
            addChild(food)
        }

        let shell = SKSpriteNode(imageNamed: "KitchenBubble")
        let width = radius * Self.artWidthPerRadius
        shell.size = CGSize(width: width, height: width * Self.artAspect)
        // The art's centre sits a little below the glass circle's.
        shell.position.y = -radius * Self.glassCentreDrop
        shell.zPosition = 1
        addChild(shell)
        self.shell = shell

        zPosition = 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shrinks to nothing and goes, for the trash hole and bubbles that drift out.
    func pop() {
        removeAllActions()
        run(.sequence([
            .group([.scale(to: 0.1, duration: 0.2), .fadeOut(withDuration: 0.2)]),
            .removeFromParent(),
        ]))
    }
}
