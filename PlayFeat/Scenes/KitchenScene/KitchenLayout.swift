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

    /// One seat per alien drawing. The two green aliens serve regular
    /// customers; the red one at the top left is the angry customer's.
    static let seats: [Seat] = [
        Seat(alienImage: "KitchenAlienLeft", customerType: .regular,
             alien: CGRect(x: 47, y: 248, width: 260, height: 297),
             orderSheet: CGRect(x: 262, y: 290, width: 226, height: 190)),
        Seat(alienImage: "KitchenAlienTop", customerType: .regular,
             alien: CGRect(x: 756, y: 0, width: 255, height: 255),
             orderSheet: CGRect(x: 1000, y: 120, width: 226, height: 190)),
        Seat(alienImage: "KitchenAlienRed", customerType: .angry,
             alien: CGRect(x: 287, y: 0, width: 218, height: 221),
             orderSheet: CGRect(x: 490, y: 90, width: 226, height: 190)),
    ]

    struct Seat {
        let alienImage: String
        /// Who sits here: an angry customer only ever takes the red alien's seat.
        let customerType: CustomerType
        let alien: CGRect
        let orderSheet: CGRect

        /// Where a dish is handed over: one invisible box around the alien
        /// and its order sheet, so the player only has to get the dish near
        /// the customer, not onto the drawing itself.
        var serveArea: CGRect { alien.union(orderSheet) }
    }

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
