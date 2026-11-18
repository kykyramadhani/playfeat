//
//  DropTargets.swift
//  PlayFeat
//  Created by kyky on 13/11/26.
//
//  Where a carried item would end up if the hand opened right now, and the
//  green glow that shows it. Release (`settle`) and the glow ask the same
//  question here, so a lit tool always means the item really lands there —
//  and when the hit areas change, both move together.
//
//  The glow follows each tool's drawn shape, not its hit area. Customers'
//  serve areas count as targets but are never lit: they stay invisible, so
//  the drawing of the alien is the only cue.
//

import SpriteKit

extension KitchenScene {

    enum DropTarget: Hashable {
        case customer(seat: Int)
        case station(KitchenBubbleNode.Placement)
    }

    /// Where `node` lands if let go where it is now; nil if it would drop.
    /// A dish for a customer comes first, then the stations.
    func dropTarget(for node: KitchenBubbleNode) -> DropTarget? {
        if let day, let seat = seat(wanting: node.ingredient, around: node.position, in: day) {
            return .customer(seat: seat)
        }
        return station(taking: node).map(DropTarget.station)
    }

    // MARK: - Glow

    /// Above the tool art and below anything sitting on it, so a glowing
    /// grill still shows the flatbread on top.
    static let dropGlowZ: CGFloat = 1
    private static let dropGlowColor = UIColor(named: "Green500") ?? .green
    private static let refusalColor = UIColor(named: "PatienceLow") ?? .red
    /// Green silhouettes of a tool's art, each a little larger and fainter,
    /// so the glow spreads out from the tool's own outline.
    private static let haloLayers: [(scale: CGFloat, alpha: CGFloat)] = [(1.12, 0.2), (1.07, 0.4), (1.03, 0.7)]
    /// How green the tool itself turns while lit.
    private static let tintAlpha: CGFloat = 0.3

    /// The tools lit this frame, one per target under an item in a hand.
    var litTargets: Set<DropTarget> { Set(dropGlows.keys) }

    /// Lights every tool a carried item is over, and puts out the rest.
    func updateDropGlows() {
        let targets = Set(hands.values.compactMap(\.held).compactMap(dropTarget(for:)))

        for (target, glow) in dropGlows where !targets.contains(target) {
            glow.removeFromParent()
            dropGlows[target] = nil
        }
        for target in targets where dropGlows[target] == nil {
            guard let glow = makeDropGlow(for: target) else { continue }
            glow.zPosition = Self.dropGlowZ
            glow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.6, duration: 0.4),
                .fadeAlpha(to: 1, duration: 0.4),
            ])))
            addChild(glow)
            dropGlows[target] = glow
        }
    }

    /// The glow in the shape of `target`'s drawing. Nil for a customer: their
    /// serve area stays invisible.
    private func makeDropGlow(for target: DropTarget) -> SKNode? {
        switch target {
        case .customer: nil
        case .station(let station): artGlow(Self.image(of: station), in: artRect(of: station), color: Self.dropGlowColor)
        }
    }

    // MARK: - Refusal

    /// The station that turned an item away glows red and shakes for as
    /// long as the item hangs there.
    func shakeRed(_ station: KitchenBubbleNode.Placement) {
        let glow = artGlow(Self.image(of: station), in: artRect(of: station), color: Self.refusalColor)
        glow.zPosition = Self.dropGlowZ
        addChild(glow)
        let nudge = bubbleRadius * 0.08
        let shake = SKAction.sequence([.moveBy(x: nudge, y: 0, duration: 0.04), .moveBy(x: -nudge * 2, y: 0, duration: 0.08),
                                       .moveBy(x: nudge, y: 0, duration: 0.04)])
        glow.run(.sequence([
            .group([.repeat(shake, count: 2), .fadeOut(withDuration: KitchenRules.refuseHoldSec)]),
            .removeFromParent(),
        ]))
    }

    private static func image(of station: KitchenBubbleNode.Placement) -> String {
        switch station {
        case .cooker(let kind, _): KitchenArt.image(of: kind)
        case .plate: "KitchenPlate"
        case .glass: "KitchenGlass"
        }
    }

    /// A halo in `color` cut from the tool's own image, with the tool
    /// redrawn on top of it in a tint of that colour. The scene sits over the
    /// SwiftUI art, so the tool has to be redrawn or the halo would cover it.
    private func artGlow(_ image: String, in artRect: CGRect, color: UIColor) -> SKNode {
        let frame = layout.sceneRect(artRect)
        let glow = SKNode()
        glow.position = frame.center
        guard let silhouette = Self.silhouette(of: image, in: color) else { return glow }

        // Depths are explicit: the scene ignores sibling order, so equal
        // depths would draw the halo over the tool at random.
        for layer in Self.haloLayers {
            let size = CGSize(width: frame.width * layer.scale, height: frame.height * layer.scale)
            glow.addChild(sprite(silhouette, size: size, alpha: layer.alpha, z: 0))
        }
        glow.addChild(sprite(SKTexture(imageNamed: image), size: frame.size, alpha: 1, z: 0.1))
        glow.addChild(sprite(silhouette, size: frame.size, alpha: Self.tintAlpha, z: 0.2))
        return glow
    }

    private func sprite(_ texture: SKTexture, size: CGSize, alpha: CGFloat, z: CGFloat) -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: texture, size: size)
        sprite.alpha = alpha
        sprite.zPosition = z
        return sprite
    }

    // MARK: - Silhouettes

    private static var silhouettes: [String: SKTexture] = [:]

    /// The tool's image filled solid `color`, keeping its outline. A sprite's
    /// colour blend multiplies, which turns a red grill or pink box near
    /// black, so the silhouette is painted once here instead and cached.
    private static func silhouette(of image: String, in color: UIColor) -> SKTexture? {
        let key = "\(image)|\(color.description)"
        if let cached = silhouettes[key] { return cached }
        guard let art = UIImage(named: image) else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = art.scale
        let filled = UIGraphicsImageRenderer(size: art.size, format: format).image { context in
            art.draw(at: .zero)
            color.setFill()
            context.fill(CGRect(origin: .zero, size: art.size), blendMode: .sourceIn)
        }
        let texture = SKTexture(image: filled)
        silhouettes[key] = texture
        return texture
    }
}
