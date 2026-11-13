//
//  KitchenLayout.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  The kitchen art is one 1366×1024 picture that fills the screen, cropped
//  evenly when the screen is a different shape. Everything placed on it —
//  props, customers, the trash hole, the storage boxes — is measured in that
//  picture's points (origin top-left) and mapped onto the screen here, so the
//  SwiftUI art and the SpriteKit hit areas always line up.
//

import CoreGraphics

nonisolated struct KitchenLayout {
    static let artSize = CGSize(width: 1366, height: 1024)

    let screenSize: CGSize

    /// Aspect-fill: the art covers the screen and the overflow is cut off
    /// equally on both sides.
    var scale: CGFloat {
        max(screenSize.width / Self.artSize.width, screenSize.height / Self.artSize.height)
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
    /// The dark hole in the counter's bottom-left corner.
    static let trashHole = CGRect(x: 0, y: 870, width: 300, height: 154)

    /// The pink boxes in the bottom-right corner, where one item each can be parked.
    static let storageBoxes: [CGRect] = [
        CGRect(x: 1049, y: 732, width: 414, height: 332),
        CGRect(x: 1122, y: 797, width: 414, height: 332),
    ]

    /// Where a parked item sits in each box — the middle of the visible tray.
    static let storageSlots: [CGPoint] = [
        CGPoint(x: 1245, y: 901),
        CGPoint(x: 1318, y: 966),
    ]

    /// The window bubbles drift through, top to counter.
    static let window = CGRect(x: 108, y: 95, width: 1150, height: 705)

    static let plate = CGRect(x: 308, y: 899, width: 188, height: 83)
    static let grill = CGRect(x: 570, y: 846, width: 345, height: 189)
    static let glass = CGRect(x: 989, y: 891, width: 110, height: 99)

    /// One seat per customer art: the alien and its order sheet.
    static let seats: [Seat] = [
        Seat(alienImage: "KitchenAlienGreen",
             alien: CGRect(x: 52, y: 202, width: 253, height: 318),
             orderSheet: CGRect(x: 259, y: 262, width: 226, height: 190)),
        Seat(alienImage: "KitchenAlienRed",
             alien: CGRect(x: 357, y: -9, width: 326, height: 357),
             orderSheet: CGRect(x: 630, y: 157, width: 226, height: 190)),
    ]

    struct Seat {
        let alienImage: String
        let alien: CGRect
        let orderSheet: CGRect

        /// Where a dish is handed over: one invisible box around the alien
        /// and its order sheet, so the player only has to get the dish near
        /// the customer, not onto the drawing itself.
        var serveArea: CGRect { alien.union(orderSheet) }
    }
}

extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
