//
//  KitchenBubbleNode.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  One planet-kitchen item: food inside the glassy cyan bubble while it
//  drifts or is carried, bare food once put down in a storage box or on a
//  station (grill, plate, glass). What it is can change while it sits there:
//  the grill bakes and burns a flatbread, the plate turns ingredients into a dish.
//

import SpriteKit

final class KitchenBubbleNode: SKNode {
    /// Where an item has been put down.
    enum Placement: Equatable {
        case storage(slot: Int)
        case grill
        case plate
        case glass
    }

    private(set) var ingredient: String
    let radius: CGFloat

    /// `HandData.id` of the hand carrying this, if any.
    var heldBy: Int?
    /// Play time it was let go mid-air, while it falls. Nil otherwise.
    var fallingSince: TimeInterval?
    /// Where it has been put down, if anywhere. Put-down items show as bare food.
    var placement: Placement? {
        didSet { shell?.isHidden = placement != nil }
    }

    /// The storage box it sits in, if parked.
    var parkedIn: Int? {
        guard case .storage(let slot) = placement else { return nil }
        return slot
    }

    private var shell: SKSpriteNode?
    private let food = SKNode()
    private var warningGlow: SKShapeNode?

    /// The food fills at most this share of the bubble, as the Figma
    /// component asks ("keep food centered inside 60% diameter").
    private static let foodFill: CGFloat = 0.6
    /// The bubble art is 200×206 around a glass circle of radius 77 centred
    /// at (100, 100); these turn that into sizes for `radius`.
    private static let artWidthPerRadius: CGFloat = 200 / 77
    private static let artAspect: CGFloat = 206.3 / 200
    private static let glassCentreDrop: CGFloat = 3.15 / 77

    private static let warningColor = UIColor(named: "SolarOrange") ?? .orange
    private static let warningPulse: TimeInterval = 0.35

    init(ingredient: String, radius: CGFloat) {
        self.ingredient = ingredient
        self.radius = radius
        super.init()

        addChild(food)
        drawFood()

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

    // MARK: - What it is

    /// Turns this item into another one in place, such as a flatbread baking.
    func become(_ newIngredient: String) {
        guard newIngredient != ingredient else { return }
        ingredient = newIngredient
        drawFood()
    }

    private func drawFood() {
        food.removeAllChildren()
        let darkening = KitchenArt.darkening(of: ingredient)
        for (depth, name) in KitchenArt.layers(for: ingredient).enumerated() {
            guard let texture = TrimmedArt.texture(named: name) else { continue }
            let layer = SKSpriteNode(texture: texture)
            layer.size = IngredientNode.aspectFit(texture.size(), into: radius * 2 * Self.foodFill)
            layer.zPosition = CGFloat(depth) * 0.01
            layer.color = .black
            layer.colorBlendFactor = darkening
            food.addChild(layer)
        }
    }

    // MARK: - Warning

    /// A pulsing glow around the food, for a flatbread about to burn.
    func setWarning(_ isOn: Bool) {
        if isOn {
            showWarningGlow()
        } else {
            warningGlow?.removeFromParent()
            warningGlow = nil
        }
    }

    private func showWarningGlow() {
        guard warningGlow == nil else { return }
        let glow = SKShapeNode(circleOfRadius: radius * Self.foodFill)
        glow.fillColor = Self.warningColor.withAlphaComponent(0.35)
        glow.strokeColor = Self.warningColor
        glow.lineWidth = 4
        glow.glowWidth = radius * 0.2
        glow.zPosition = -1
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.3, duration: Self.warningPulse),
            .fadeAlpha(to: 1, duration: Self.warningPulse),
        ])))
        addChild(glow)
        warningGlow = glow
    }

    // MARK: - Leaving

    /// Shrinks to nothing and goes, for the trash hole and bubbles that drift out.
    func pop() {
        removeAllActions()
        run(.sequence([
            .group([.scale(to: 0.1, duration: 0.2), .fadeOut(withDuration: 0.2)]),
            .removeFromParent(),
        ]))
    }
}
