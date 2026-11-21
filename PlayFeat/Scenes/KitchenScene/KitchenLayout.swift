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

    /// The places a customer can stand, each an alien leaning in from a
    /// screen edge as the design draws them: tilted out of the left and
    /// right walls, and hanging from the ceiling with only the head and neck
    /// in view. Any customer, angry or not, can take any of them; which one
    /// is picked at random (Counter).
    static let seats: [Seat] = [
        Seat(entersFrom: .left,
             alien: CGRect(x: 108, y: 230, width: 206, height: 367),
             alienPose: AlienPose(center: CGPoint(x: 144, y: 483), isMirrored: true, turnDegrees: -20),
             orderSheet: CGRect(x: 295, y: 330, width: 226, height: 190), orderSheetPointsRight: false),
        Seat(entersFrom: .top,
             alien: CGRect(x: 634, y: 0, width: 315, height: 271),
             alienPose: AlienPose(center: CGPoint(x: 734, y: 33), isMirrored: true, turnDegrees: 90),
             orderSheet: CGRect(x: 530, y: 110, width: 226, height: 190), orderSheetPointsRight: true),
        Seat(entersFrom: .top,
             alien: CGRect(x: 311, y: 0, width: 299, height: 265),
             alienPose: AlienPose(center: CGPoint(x: 526, y: 28), isMirrored: false, turnDegrees: -90),
             orderSheet: CGRect(x: 115, y: 60, width: 226, height: 190), orderSheetPointsRight: true),
        // The left seat mirrored onto the right wall.
        Seat(entersFrom: .right,
             alien: CGRect(x: 1051, y: 230, width: 208, height: 369),
             alienPose: AlienPose(center: CGPoint(x: 1222, y: 483), isMirrored: false, turnDegrees: 20),
             orderSheet: CGRect(x: 840, y: 330, width: 226, height: 190), orderSheetPointsRight: true),
    ]

    /// The seats customers may take on `level`: those on the edges it
    /// lists, or all of them.
    static func openSeats(on level: LevelData) -> [Int] {
        let sides = Set(level.refill?.customerSides ?? CustomerSide.allCases)
        return seats.indices.filter { sides.contains(seats[$0].entersFrom) }
    }

    struct Seat {
        /// The screen edge the alien leans in from, slides in from, and
        /// slides back out to.
        let entersFrom: CustomerSide
        /// Where the alien's head and shoulders show: half of where a dish
        /// can be handed over.
        let alien: CGRect
        let alienPose: AlienPose
        let orderSheet: CGRect
        /// The order sheet stands left of the alien, so its tail points right.
        let orderSheetPointsRight: Bool

        /// How far the alien moves to be just off screen on its side, in art
        /// points: past the far edge of the whole drawn picture.
        var offstageOffset: CGSize {
            let drawn = alienPose.drawnBounds
            return switch entersFrom {
            case .left: CGSize(width: -drawn.maxX, height: 0)
            case .top: CGSize(width: 0, height: -drawn.maxY)
            case .right: CGSize(width: KitchenLayout.artSize.width - drawn.minX, height: 0)
            }
        }

        /// Where a dish is handed over: one invisible box around the alien
        /// and its order sheet, so the player only has to get the dish near
        /// the customer, not onto the drawing itself.
        var serveArea: CGRect { alien.union(orderSheet) }
    }

    /// How a seat's alien is drawn. Every alien picture is in one pose,
    /// head at the top left and body reaching right to a cut end at the
    /// canvas's right edge, with its three moods lined up on the body, so
    /// only the face changes with the mood. The picture is mirrored, then
    /// turned about its centre so that cut end sits past the wall or the
    /// ceiling, and centred on `center`.
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
    static let alienCanvas = CGSize(width: 475, height: 432)

    /// How far outside a customer's serve area a carried dish they ordered
    /// is pulled in, as if by a magnet.
    static let serveMagnetReach: CGFloat = 60
}

extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
