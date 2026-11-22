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
//  glass, the pot or the noodle bowl they are drawn as the whole station
//  with them in it, at the counter station's size.
//

import SpriteKit

final class KitchenBubbleNode: SKNode {
    /// Where an item has been put down.
    enum Placement: Hashable {
        /// A cooking tool (grill, pot); one can hold more than one item, and
        /// `slot` counts them.
        case cooker(CookingTool.Kind, slot: Int)
        /// The counter can hold more than one plate or glass; the index
        /// counts them in the order they came out. On Planet 2 the plate is the noodle
        /// bowl and the glass the cookie plate: same roles, other rules
        /// (`PlanetKitchen`).
        case plate(Int)
        case glass(Int)

        /// A plate or glass, where a dish is put together, rather than a
        /// cooking tool.
        var isForAssembly: Bool {
            if case .cooker = self { false } else { true }
        }
    }

    private(set) var ingredient: String
    let radius: CGFloat
    /// Ingredients upgraded in the shop or by a marathon card, drawn premium.
    private let upgraded: Set<String>

    /// `HandData.id` of the hand carrying this, if any.
    var heldBy: Int?
    /// Cleared if the player catches the discarded item before it disappears.
    var isTutorialDiscard = false
    /// Play time it was let go mid-air, while it falls. Nil otherwise. A
    /// refused item gets a time just ahead: it hangs where it was let go,
    /// out of reach, until then.
    var fallingSince: TimeInterval?
    /// The lane a bubble came in on; nil for anything that didn't.
    var lane: Int?
    /// The station the hand last lifted it off; nil if it was grabbed out
    /// of the air. A finished dish let go away from the customers goes back
    /// there, and anything off a plate or glass counts as a dish to them.
    var liftedFrom: Placement?
    /// Left where a hand held it when a marathon round ended: it hangs
    /// there, out of gravity's reach, until a hand grabs it again.
    var isFrozenInAir = false
    /// How long this item has cooked on a cooking tool (grill, pot), raw or
    /// done, so one taken off and put back on carries on from there.
    var cookedSeconds: TimeInterval?
    /// The inside of the station it is put down in, if that station holds
    /// food in (the noodle bowl): food then sits down in it, cut off at its rim.
    var interior: KitchenArt.StationInterior? {
        didSet { drawFood() }
    }
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
        if placement != nil { setScale(placedScale) }
    }

    /// How big this is drawn where it has been put down: food grows to fill
    /// the cookware, while a picture of the whole station is already its size.
    var placedScale: CGFloat {
        isDrawnAsWholeStation ? 1 : KitchenScene.cookwareFoodScale
    }

    /// Whether it shows as the whole station it sits in (`KitchenArt.wholeStationScale`).
    private(set) var isDrawnAsWholeStation = false

    private func drawFood() {
        food.removeAllChildren()
        let name = pictureName
        let artPointsPerPixel = wholeStationScale(of: name)
        isDrawnAsWholeStation = artPointsPerPixel != nil
        if let artPointsPerPixel {
            food.addChild(wholeStationSprite(name, artPointsPerPixel: artPointsPerPixel))
        } else if let texture = TrimmedArt.texture(named: name) {
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = Self.aspectFit(texture.size(), into: radius * 2 * Self.foodFill)
            if placement != nil, let interior {
                food.addChild(sittingInside(interior, sprite))
            } else {
                food.addChild(sprite)
            }
        }
    }

    /// `sprite` moved down into the station and cut off at its rim. Node
    /// units shrink by `placedScale`, which the node is drawn at once put down.
    private func sittingInside(_ interior: KitchenArt.StationInterior, _ sprite: SKSpriteNode) -> SKNode {
        let pixelsToNode = interior.artPointsPerPixel * radius / KitchenScene.bubbleArtRadius / placedScale
        func nodePoint(_ pixelOffset: CGVector) -> CGPoint {
            CGPoint(x: pixelOffset.dx * pixelsToNode, y: -pixelOffset.dy * pixelsToNode)
        }
        sprite.position = nodePoint(interior.foodCentre)

        let mask = SKSpriteNode(imageNamed: interior.maskImage)
        mask.size = CGSize(width: mask.size.width * pixelsToNode, height: mask.size.height * pixelsToNode)
        mask.position = nodePoint(interior.maskCentre)

        let crop = SKCropNode()
        crop.maskNode = mask
        crop.addChild(sprite)
        return crop
    }

    /// What it looks like where it is: in a bubble, cooking, or put down.
    private var pictureName: String {
        switch placement {
        case nil: KitchenArt.image(of: ingredient, upgraded: upgraded)
        case .cooker(let tool, _): KitchenArt.image(of: ingredient, cookingOn: tool, upgraded: upgraded)
        case .plate, .glass: KitchenArt.placedImage(of: ingredient, upgraded: upgraded)
        }
    }

    /// How many art points a pixel of `name` covers when it is drawn as the
    /// whole station. Put down, every station picture is; in a bubble only
    /// the glass's, as Planet 1's dessert was designed. The bowl's and pot's
    /// are framed for the counter, so in a bubble they are trimmed to fit.
    private func wholeStationScale(of name: String) -> CGFloat? {
        guard placement != nil || KitchenArt.glassStateImages.contains(name) else { return nil }
        return KitchenArt.wholeStationScale(of: name)
    }

    /// A picture of a whole station, untrimmed so the station stays
    /// centred, at the scale that makes it as big as the counter's.
    private func wholeStationSprite(_ name: String, artPointsPerPixel: CGFloat) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: name)
        let scenePerArtPoint = radius / KitchenScene.bubbleArtRadius
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(
            width: texture.size().width * artPointsPerPixel * scenePerArtPoint,
            height: texture.size().height * artPointsPerPixel * scenePerArtPoint
        )
        return sprite
    }

    /// Scales `size` so its longest edge is `maxDimension`, preserving the
    /// aspect ratio. Squashing art into a square would turn the bubble into
    /// an ellipse.
    private static func aspectFit(_ size: CGSize, into maxDimension: CGFloat) -> CGSize {
        guard size.width > 0, size.height > 0 else {
            return CGSize(width: maxDimension, height: maxDimension)
        }
        let scale = maxDimension / max(size.width, size.height)
        return CGSize(width: size.width * scale, height: size.height * scale)
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
