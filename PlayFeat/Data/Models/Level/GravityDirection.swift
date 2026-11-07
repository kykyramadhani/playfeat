//
//  GravityDirection.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  Where bubbles drift and released items fall on a level. Bubbles enter from
//  the opposite edge, so this also decides where the lanes are.
//

import CoreGraphics

nonisolated enum GravityDirection: String, Codable {
    case down
    case up
    case left
    case right
    case upRight = "up-right"

    /// Unit vector in SpriteKit space (y points up).
    var unitVector: CGVector {
        switch self {
        case .down: CGVector(dx: 0, dy: -1)
        case .up: CGVector(dx: 0, dy: 1)
        case .left: CGVector(dx: -1, dy: 0)
        case .right: CGVector(dx: 1, dy: 0)
        case .upRight: CGVector(dx: 1 / 2.squareRoot(), dy: 1 / 2.squareRoot())
        }
    }

    /// Where a bubble in `lane` (1...4) enters `bounds`: the centre of that
    /// lane on the edge gravity pulls away from.
    ///
    /// ponytail: up-right enters along the bottom edge and left/right gravity
    /// counts lanes from the top; ask the designers if a planet needs otherwise.
    func entryPoint(lane: Int, in bounds: CGRect) -> CGPoint {
        let laneCount = CGFloat(LevelData.BubbleEntry.laneCount)
        let fraction = (CGFloat(lane) - 0.5) / laneCount
        let acrossX = bounds.minX + bounds.width * fraction
        let downFromTop = bounds.maxY - bounds.height * fraction

        switch self {
        case .down: return CGPoint(x: acrossX, y: bounds.maxY)
        case .up, .upRight: return CGPoint(x: acrossX, y: bounds.minY)
        case .left: return CGPoint(x: bounds.maxX, y: downFromTop)
        case .right: return CGPoint(x: bounds.minX, y: downFromTop)
        }
    }
}
