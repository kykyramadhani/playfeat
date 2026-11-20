//
//  KitchenLayout.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  The kitchen art is one 1366×1024 picture fitted whole to the screen and
//  centred, never cropped, so the counter's stations stay within reach on
//  a wide MacBook screen too. Everything placed on it — the counter's tools
//  and stations (each planet's CounterLayout) and the customers — is
//  measured in that picture's points (origin top-left) and
//  mapped onto the screen here, so the SwiftUI art and the SpriteKit hit
//  areas always line up. The truck around it is the exception: its walls
//  stick to the screen's edges (`truckBands`), so a wider screen just opens
//  a wider window.
//

import CoreGraphics

nonisolated struct KitchenLayout {
    static let artSize = CGSize(width: 1366, height: 1024)

    let screenSize: CGSize

    /// Aspect-fit: the whole art shows. On a screen wider than the art (every
    /// Mac and most iPads) it fills the height and leaves a margin each side,
    /// which the truck's walls and counter reach across (`truckBands`).
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

    /// How wide the counter glass's mug is drawn, without its handle; what's
    /// put in the glass is drawn to match it.
    static let glassMugWidth: CGFloat = 144

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

        /// Where a dish is handed over: one invisible box around the alien
        /// and its order sheet, so the player only has to get the dish near
        /// the customer, not onto the drawing itself.
        var serveArea: CGRect { alien.union(orderSheet) }

        /// This seat moved `distance` art points to the right (left if
        /// negative), its alien and order sheet together.
        func movedSideways(by distance: CGFloat) -> Seat {
            let pose = AlienPose(
                center: CGPoint(x: alienPose.center.x + distance, y: alienPose.center.y),
                isMirrored: alienPose.isMirrored,
                turnDegrees: alienPose.turnDegrees
            )
            return Seat(
                customerType: customerType,
                entersFrom: entersFrom,
                alien: alien.offsetBy(dx: distance, dy: 0),
                alienPose: pose,
                orderSheet: orderSheet.offsetBy(dx: distance, dy: 0)
            )
        }
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

// MARK: - The truck around the art

nonisolated extension KitchenLayout {
    /// The truck art's plain middle, in art points. Inside it the window's
    /// edges and the counter's front edge run level, so it can be widened
    /// without bending anything; outside it the walls, the counter's slanted
    /// ends and the chains keep their drawn shape.
    static let truckStretchBand: ClosedRange<CGFloat> = 400...966

    /// One upright band of a truck layer and where it lands on screen.
    struct TruckBand: Equatable {
        /// The band's left and right edges on the art.
        let artSpan: ClosedRange<CGFloat>
        /// Where the band is drawn, in view points.
        let screenRect: CGRect

        /// Where the whole layer is drawn so this band lands on `screenRect`.
        /// Clip it to `screenRect` to show only the band.
        var layerRect: CGRect {
            let widthScale = screenRect.width / (artSpan.upperBound - artSpan.lowerBound)
            return CGRect(
                x: screenRect.minX - artSpan.lowerBound * widthScale,
                y: screenRect.minY,
                width: KitchenLayout.artSize.width * widthScale,
                height: screenRect.height
            )
        }
    }

    /// The truck's left and right bands stuck to the screen's edges at the
    /// art's scale, and the middle band widened to meet them. On a screen
    /// the art's shape the three bands tile the art exactly.
    var truckBands: [TruckBand] {
        let top = viewPoint(.zero).y
        let height = Self.artSize.height * scale
        let middle = Self.truckStretchBand
        let leftWidth = middle.lowerBound * scale
        let rightWidth = (Self.artSize.width - middle.upperBound) * scale

        let left = CGRect(x: 0, y: top, width: leftWidth, height: height)
        let right = CGRect(x: screenSize.width - rightWidth, y: top, width: rightWidth, height: height)
        let centre = CGRect(x: left.maxX, y: top, width: right.minX - left.maxX, height: height)
        return [
            TruckBand(artSpan: 0...middle.lowerBound, screenRect: left),
            TruckBand(artSpan: middle, screenRect: centre),
            TruckBand(artSpan: middle.upperBound...Self.artSize.width, screenRect: right),
        ]
    }

    /// The seat at `index` as placed on this screen. The walls stand at the
    /// screen's edges, not the art's, so on a wider screen each seat moves
    /// out with the wall on its side of the art, keeping its customer leaning
    /// on that wall (and sliding all the way behind it to leave).
    func seat(at index: Int) -> Seat {
        let seat = Self.seats[index]
        let wallShift = sideMargin / scale
        let isOnTheLeft = seat.alien.midX < Self.artSize.width / 2
        return seat.movedSideways(by: isOnTheLeft ? -wallShift : wallShift)
    }

    /// How far the customer at seat `index` slides to be out of sight behind
    /// its wall, in art points: until the far edge of its whole picture
    /// passes the art's edge. Taken from the seat as drawn: a seat moved out
    /// with its wall (`seat(at:)`) has just as far to go.
    static func offstageOffset(ofSeatAt index: Int) -> CGSize {
        let seat = seats[index]
        let drawn = seat.alienPose.drawnBounds
        return switch seat.entersFrom {
        case .left: CGSize(width: -drawn.maxX, height: 0)
        case .top: CGSize(width: 0, height: -drawn.maxY)
        }
    }
}
