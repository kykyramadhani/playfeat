//
//  KitchenBubbleNode.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  One planet-kitchen item: food inside the glassy cyan bubble while it
//  drifts or is carried, bare food once put down on a station (grill, a
//  plate, a glass). What it is can change while it sits there:
//  the grill bakes and burns a flatbread, the plate turns ingredients into a
//  dish. Some items look different once put down (see KitchenArt): in the
//  glass they are drawn as the whole glass, at the counter glass's size.
//

import SpriteKit

final class KitchenBubbleNode: SKNode {
    /// Where an item has been put down.
    enum Placement: Hashable {
        /// The grill can hold more than one flatbread; the index counts its slots.
        case grill(Int)
        /// The counter can hold more than one plate or glass; the index
        /// counts them from the left.
        case plate(Int)
        case glass(Int)
    }

    private(set) var ingredient: String
    let radius: CGFloat
    /// Ingredients upgraded in the shop or by a marathon card, drawn premium.
    private let upgraded: Set<String>

    /// `HandData.id` of the hand carrying this, if any.
    var heldBy: Int?
    /// Play time it was let go mid-air, while it falls. Nil otherwise. A
    /// refused item gets a time just ahead: it hangs where it was let go,
    /// out of reach, until then.
    var fallingSince: TimeInterval?
    /// The lane a bubble came in on; nil for anything that didn't.
    var lane: Int?
    /// How long a flatbread has cooked on the grill, so one put back on
    /// carries on from there.
    var cookedSeconds: TimeInterval?
    /// Where it has been put down, if anywhere. Put-down items show as bare food.
    var placement: Placement? {
        didSet {
            shell?.isHidden = placement != nil
            drawFood()
        }
    }

    private var shell: SKSpriteNode?
    private let food = SKNode()
    private var warningGlow: SKShapeNode?

    /// The food fills at most this share of the bubble, as the Figma
    /// component asks ("keep food centered inside 60% diameter").
    static let foodFill: CGFloat = 0.6
    /// The bubble art is 200×206 around a glass circle of radius 77 centred
    /// at (100, 100); these turn that into sizes for `radius`.
    private static let artWidthPerRadius: CGFloat = 200 / 77
    private static let artAspect: CGFloat = 206.3 / 200
    private static let glassCentreDrop: CGFloat = 3.15 / 77

    private static let warningColor = UIColor(named: "SolarOrange") ?? .orange
    private static let warningPulse: TimeInterval = 0.35

    init(ingredient: String, radius: CGFloat, upgraded: Set<String> = []) {
        self.ingredient = ingredient
        self.radius = radius
        self.upgraded = upgraded
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

    /// Still hanging where it was refused at play time `now`.
    func isRefused(at now: TimeInterval) -> Bool {
        fallingSince.map { $0 > now } ?? false
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
        let name = placement == nil
            ? KitchenArt.image(of: ingredient, upgraded: upgraded)
            : KitchenArt.placedImage(of: ingredient, upgraded: upgraded)
        if KitchenArt.glassStateImages.contains(name) {
            food.addChild(glassSprite(name))
        } else if let texture = TrimmedArt.texture(named: name) {
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = IngredientNode.aspectFit(texture.size(), into: radius * 2 * Self.foodFill)
            food.addChild(sprite)
        }
    }

    /// A picture of the whole glass, untrimmed so its mug stays centred, at
    /// the scale that makes its mug as wide as the counter glass's.
    private func glassSprite(_ name: String) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: name)
        let artPointsPerPixel = KitchenLayout.glassMugWidth / KitchenArt.glassMugPixels
        let scenePerArtPoint = radius / KitchenScene.bubbleArtRadius
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(
            width: texture.size().width * artPointsPerPixel * scenePerArtPoint,
            height: texture.size().height * artPointsPerPixel * scenePerArtPoint
        )
        return sprite
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

    /// Shrinks to nothing and goes, for bubbles that drift out or slip behind the table.
    func pop() {
        removeAllActions()
        run(.sequence([
            .group([.scale(to: 0.1, duration: 0.2), .fadeOut(withDuration: 0.2)]),
            .removeFromParent(),
        ]))
    }
}
