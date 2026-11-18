//
//  GrillGaugeNode.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  The ring drawn around a flatbread on the grill, copied from the playtest
//  prototype: a dark track with an arc filling clockwise from the top,
//  yellow while the flatbread bakes, red as it heads for burning, solid
//  black once burnt; and a pulsing yellow warning sign at its top right
//  in the last seconds before it burns. Sizes are the prototype's, moved
//  from its 1024-wide canvas onto the 1366-wide kitchen art.
//

import SpriteKit

final class GrillGaugeNode: SKNode {
    /// The prototype's ring (54 × 40, line 7 on a 1024-wide canvas), in art points.
    private static let artRadii = CGSize(width: 72, height: 53.4)
    private static let artLineWidth: CGFloat = 9.3
    /// Where the warning sign sits from the ring's centre, and its size.
    private static let artSignOffset = CGPoint(x: 72, y: 69.4)
    private static let artSignRadius: CGFloat = 32
    private static let arcSegments = 64

    private static let trackColor = UIColor.black.withAlphaComponent(0.4)
    private static let bakingColor = UIColor(named: "GrillBaking") ?? .yellow
    private static let burningColor = UIColor(named: "GrillBurning") ?? .red
    private static let signColor = UIColor(named: "WarningSign") ?? .yellow
    private static let inkColor = UIColor(named: "WarningInk") ?? .black

    private let radii: CGSize
    private let arc = SKShapeNode()
    private let sign: SKNode
    private var shownGauge: CookingTool.Gauge?

    /// - Parameter scale: scene points per art point.
    init(scale: CGFloat) {
        radii = CGSize(width: Self.artRadii.width * scale, height: Self.artRadii.height * scale)
        sign = Self.warningSign(radius: Self.artSignRadius * scale, lineWidth: 4 * scale)
        super.init()

        let lineWidth = Self.artLineWidth * scale
        let track = SKShapeNode(ellipseOf: CGSize(width: radii.width * 2, height: radii.height * 2))
        track.strokeColor = Self.trackColor
        track.lineWidth = lineWidth
        addChild(track)

        arc.lineWidth = lineWidth
        arc.lineCap = .butt
        arc.zPosition = 0.1
        addChild(arc)

        sign.position = CGPoint(x: Self.artSignOffset.x * scale, y: Self.artSignOffset.y * scale)
        sign.zPosition = 0.2
        sign.isHidden = true
        addChild(sign)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ gauge: CookingTool.Gauge) {
        guard gauge != shownGauge else { return }
        shownGauge = gauge
        arc.path = Self.arcPath(radii: radii, fraction: gauge.fraction)
        arc.strokeColor = switch gauge.phase {
        case .baking: Self.bakingColor
        case .baked: Self.burningColor
        case .burnt: .black
        }
        sign.isHidden = !gauge.isAboutToBurn
    }

    /// The part of the ellipse from the top, clockwise on screen, `fraction` of the way round.
    private static func arcPath(radii: CGSize, fraction: Double) -> CGPath {
        let path = CGMutablePath()
        let steps = max(Int((Double(arcSegments) * fraction.clamped(to: 0...1)).rounded(.up)), 1)
        for step in 0...steps {
            let angle = Double.pi / 2 - 2 * Double.pi * fraction * Double(step) / Double(steps)
            let point = CGPoint(x: radii.width * cos(angle), y: radii.height * sin(angle))
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }

    /// The prototype's yellow triangle with an "!", pulsing.
    private static func warningSign(radius: CGFloat, lineWidth: CGFloat) -> SKNode {
        let triangle = CGMutablePath()
        triangle.move(to: CGPoint(x: 0, y: radius))
        triangle.addLine(to: CGPoint(x: radius * 1.05, y: -radius * 0.8))
        triangle.addLine(to: CGPoint(x: -radius * 1.05, y: -radius * 0.8))
        triangle.closeSubpath()

        let sign = SKNode()
        let shadow = SKShapeNode(path: triangle)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -lineWidth)
        shadow.glowWidth = lineWidth
        sign.addChild(shadow)

        let face = SKShapeNode(path: triangle)
        face.fillColor = signColor
        face.strokeColor = inkColor
        face.lineWidth = lineWidth
        face.lineJoin = .round
        face.zPosition = 0.1
        sign.addChild(face)

        let mark = SKLabelNode(text: "!")
        mark.fontName = Atkinson.bold
        mark.fontSize = radius * 1.25
        mark.fontColor = inkColor
        mark.verticalAlignmentMode = .center
        mark.position = CGPoint(x: 0, y: -radius * 0.18)
        mark.zPosition = 0.2
        sign.addChild(mark)

        sign.run(.repeatForever(.sequence([
            .scale(to: 1.12, duration: 0.14),
            .scale(to: 0.88, duration: 0.28),
            .scale(to: 1, duration: 0.14),
        ])))
        return sign
    }
}
