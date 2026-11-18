//
//  KitchenLayout.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  The kitchen art is one 1366×1024 picture fitted whole to the screen and
//  centred, never cropped, so the counter's stations stay within reach on
//  a wide MacBook screen too. Everything placed on it — props and
//  customers — is measured in that picture's points (origin top-left) and
//  mapped onto the screen here, so the SwiftUI art and the SpriteKit hit
//  areas always line up.
//

import CoreGraphics

nonisolated struct KitchenLayout {
    static let artSize = CGSize(width: 1366, height: 1024)

    let screenSize: CGSize

    /// Aspect-fit: the whole art shows. On a screen wider than the art (every
    /// Mac and most iPads) it fills the height and leaves a margin each side,
    /// which `KitchenBackdrop` fills by stretching the truck's walls.
    var scale: CGFloat {
        min(screenSize.width / Self.artSize.width, screenSize.height / Self.artSize.height)
    }

    /// The screen width left over on each side of the art.
    var sideMargin: CGFloat {
        max(0, (screenSize.width - Self.artSize.width * scale) / 2)
    }

    /// Screen point (y-down, SwiftUI) of a point on the art.
    func viewPoint(_ artPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: (screenSize.width - Self.artSize.width * scale) / 2 + artPoint.x * scale,
            y: (screenSize.height - Self.artSize.height * scale) / 2 + artPoint.y * scale
        )
    }

    /// Scene point (y-up, SpriteKit) of a point on the art.
    func scenePoint(_ artPoint: CGPoint) -> CGPoint {
        let point = viewPoint(artPoint)
        return CGPoint(x: point.x, y: screenSize.height - point.y)
    }

    func length(_ artLength: CGFloat) -> CGFloat { artLength * scale }

    /// Scene rectangle (y-up, SpriteKit) of a rectangle on the art.
    func sceneRect(_ artRect: CGRect) -> CGRect {
        let bottomLeft = scenePoint(CGPoint(x: artRect.minX, y: artRect.maxY))
        return CGRect(origin: bottomLeft, size: CGSize(width: length(artRect.width), height: length(artRect.height)))
    }
}

// MARK: - Landmarks, in art points

nonisolated extension KitchenLayout {
    /// The window bubbles drift through: the gap in the counter art, from
    /// the top of the screen down to the table's back edge.
    static let window = CGRect(x: 108, y: 0, width: 1151, height: 697)

    static let grill = CGRect(x: 551, y: 755, width: 305, height: 166)
    /// The middle of the grill's hot ring, where food cooks. The grill is
    /// drawn in perspective, so it sits up and left of the box's centre.
    static let grillRing = CGPoint(x: 719, y: 813)
    /// How far apart two flatbreads sit when the grill holds two.
    static let grillSlotGap: CGFloat = 110

    /// ponytail: a stand-in spot for Planet 2's pot, at the far right of the
    /// counter, until the positions in the team's design file are drawn in.
    /// It covers the second glass spot.
    static let pot = CGRect(x: 1110, y: 745, width: 200, height: 180)

    /// Where `tool` stands on the counter.
    static func area(of tool: CookingTool.Kind) -> CGRect {
        switch tool {
        case .grill: grill
        case .pot: pot
        }
    }

    /// Where each of `count` items cooks on `tool`, left to right.
    static func cookingSpots(on tool: CookingTool.Kind, count: Int) -> [CGPoint] {
        switch tool {
        case .grill: grillSlots(count)
        case .pot: [CGPoint(x: pot.midX, y: pot.midY)]
        }
    }

    /// Where each of `count` flatbreads cooks, left to right.
    static func grillSlots(_ count: Int) -> [CGPoint] {
        guard count > 1 else { return [grillRing] }
        let start = grillRing.x - grillSlotGap * CGFloat(count - 1) / 2
        return (0..<count).map { CGPoint(x: start + grillSlotGap * CGFloat($0), y: grillRing.y) }
    }

    /// Plate spots, left to right. A single plate takes the one beside the
    /// grill; a second, bought in the shop, goes further left.
    private static let plateSpots = [
        CGRect(x: 42, y: 778, width: 205, height: 117),
        CGRect(x: 284, y: 778, width: 205, height: 117),
    ]

    /// How wide the counter glass's mug is drawn, without its handle; what's
    /// put in the glass is drawn to match it.
    static let glassMugWidth: CGFloat = 144

    /// Glass spots, left to right: the first beside the grill, a second further right.
    private static let glassSpots = [
        CGRect(x: 933, y: 769, width: 150, height: 137),
        CGRect(x: 1130, y: 769, width: 150, height: 137),
    ]

    static let maxPlates = plateSpots.count
    static let maxGlasses = glassSpots.count

    /// Where `count` plates stand, left to right.
    static func plates(_ count: Int) -> [CGRect] {
        Array(plateSpots.suffix(min(max(count, 0), maxPlates)))
    }

    /// Where `count` glasses stand, left to right.
    static func glasses(_ count: Int) -> [CGRect] {
        Array(glassSpots.prefix(min(max(count, 0), maxGlasses)))
    }

    /// The three places a customer stands. The two regular seats are the
    /// one leaning in from the left wall and the one hanging from the top
    /// right; the angry customer hangs from the top left.
    static let seats: [Seat] = [
        Seat(customerType: .regular, entersFrom: .left,
             alien: CGRect(x: 47, y: 248, width: 260, height: 297),
             alienPose: AlienPose(center: CGPoint(x: 166, y: 420), isMirrored: true, turnDegrees: 0),
             orderSheet: CGRect(x: 262, y: 290, width: 226, height: 190)),
        Seat(customerType: .regular, entersFrom: .top,
             alien: CGRect(x: 756, y: 0, width: 259, height: 255),
             alienPose: AlienPose(center: CGPoint(x: 936, y: 93), isMirrored: false, turnDegrees: -95),
             orderSheet: CGRect(x: 1000, y: 120, width: 226, height: 190)),
        Seat(customerType: .angry, entersFrom: .top,
             alien: CGRect(x: 287, y: 0, width: 224, height: 280),
             alienPose: AlienPose(center: CGPoint(x: 392, y: 65), isMirrored: true, turnDegrees: 105),
             orderSheet: CGRect(x: 490, y: 90, width: 226, height: 190)),
    ]

    struct Seat {
        enum Side { case left, top }

        /// Who sits here: an angry customer only ever takes the top-left seat.
        let customerType: CustomerType
        /// The screen edge the alien slides in from, and back out to.
        let entersFrom: Side
        /// Where the alien's head and shoulders show: half of where a dish
        /// can be handed over.
        let alien: CGRect
        let alienPose: AlienPose
        let orderSheet: CGRect

        /// How far the alien moves to be just off screen on its side, in art
        /// points: past the far edge of the whole drawn picture.
        var offstageOffset: CGSize {
            let drawn = alienPose.drawnBounds
            return switch entersFrom {
            case .left: CGSize(width: -drawn.maxX, height: 0)
            case .top: CGSize(width: 0, height: -drawn.maxY)
            }
        }

        /// Where a dish is handed over: one invisible box around the alien
        /// and its order sheet, so the player only has to get the dish near
        /// the customer, not onto the drawing itself.
        var serveArea: CGRect { alien.union(orderSheet) }
    }

    /// How a seat's alien is drawn. Every alien picture is in one pose,
    /// head at the top left and body trailing down to the right, on the
    /// same canvas with its three moods lined up, so only the face changes
    /// with the mood. The picture is mirrored, then turned about its centre
    /// so the body reaches back to the wall or the ceiling, and centred on
    /// `center`.
    struct AlienPose {
        let center: CGPoint
        let isMirrored: Bool
        /// Clockwise.
        let turnDegrees: Double

        /// The box around the whole picture once turned, in art points.
        var drawnBounds: CGRect {
            let half = CGSize(width: KitchenLayout.alienCanvas.width / 2, height: KitchenLayout.alienCanvas.height / 2)
            let angle = turnDegrees * .pi / 180
            let reach = CGSize(
                width: abs(half.width * cos(angle)) + abs(half.height * sin(angle)),
                height: abs(half.width * sin(angle)) + abs(half.height * cos(angle))
            )
            return CGRect(x: center.x - reach.width, y: center.y - reach.height,
                          width: reach.width * 2, height: reach.height * 2)
        }
    }

    /// The canvas every alien picture is drawn on, in art points.
    static let alienCanvas = CGSize(width: 357, height: 455)

    /// How far outside a customer's serve area a carried dish they ordered
    /// is pulled in, as if by a magnet.
    static let serveMagnetReach: CGFloat = 60

    /// Who each counter position takes: the regular aliens' first, then the
    /// angry alien's. How many stand there at once is the level's call.
    static let positionTypes: [CustomerType] = seats.map(\.customerType)
}

extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
