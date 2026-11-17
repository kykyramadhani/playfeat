//
//  HandSideAssigner.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  Works out which of the player's hands is the left and which the right,
//  from the body pose's wrists rather than from where a hand is on screen or
//  how it is turned: a right hand reaching across to the left side is still
//  the right hand. Pure, so it can be tested without a camera.
//

import CoreGraphics

nonisolated enum HandSideAssigner {
    typealias BodyCandidate = HumanBodyPoseManager.BodyCandidate

    /// The side of each hand whose wrist is at `handWrists`, or nil for a hand
    /// the body can't place. No two hands get the same side.
    ///
    /// Two hands against two body wrists are paired as a whole, whichever way
    /// round puts both nearer their wrist. The body pose runs a few frames
    /// behind the hands, and comparing the two pairings is robust to that lag
    /// where matching each hand on its own is not. Otherwise each hand takes
    /// the nearest body wrist within `reach`, and with two hands, one placed
    /// hand settles the other.
    static func sides(ofHandsAt handWrists: [CGPoint], body: BodyCandidate, reach: CGFloat) -> [HandSide?] {
        if handWrists.count == 2, let left = body.leftWrist, let right = body.rightWrist {
            return pairedSides(of: handWrists, leftWrist: left, rightWrist: right)
        }
        let nearest = nearestSides(of: handWrists, body: body, reach: reach)
        return handWrists.count == 2 ? settlingTheOther(nearest) : nearest
    }

    // MARK: - Two hands, two wrists

    private static func pairedSides(of hands: [CGPoint], leftWrist: CGPoint, rightWrist: CGPoint) -> [HandSide?] {
        let asSeen = hands[0].distance(to: leftWrist) + hands[1].distance(to: rightWrist)
        let swapped = hands[0].distance(to: rightWrist) + hands[1].distance(to: leftWrist)
        return asSeen <= swapped ? [.left, .right] : [.right, .left]
    }

    // MARK: - Fewer wrists or hands

    /// Each hand takes the nearest unclaimed body wrist within `reach`,
    /// closest pairs first.
    private static func nearestSides(of hands: [CGPoint], body: BodyCandidate, reach: CGFloat) -> [HandSide?] {
        let pairs = hands.indices.flatMap { hand in
            HandSide.allCases.compactMap { side -> (hand: Int, side: HandSide, distance: CGFloat)? in
                guard let wrist = body.wrist(on: side) else { return nil }
                let distance = hands[hand].distance(to: wrist)
                return distance <= reach ? (hand, side, distance) : nil
            }
        }
        var sides = [HandSide?](repeating: nil, count: hands.count)
        for pair in pairs.sorted(by: { $0.distance < $1.distance })
        where sides[pair.hand] == nil && !sides.contains(pair.side) {
            sides[pair.hand] = pair.side
        }
        return sides
    }

    /// The player has two hands: once one is placed, the other is the other.
    private static func settlingTheOther(_ sides: [HandSide?]) -> [HandSide?] {
        let placed = sides.compactMap { $0 }
        guard placed.count == 1, let side = placed.first else { return sides }
        return sides.map { $0 ?? side.opposite }
    }
}
