//
//  KitchenLayoutTests.swift
//  PlayFeatTests
//  Created by kyky on 12/11/26.
//

import CoreGraphics
import Testing
@testable import PlayFeat

struct KitchenLayoutTests {

    @Test func onAScreenTheArtsShapeTheArtMapsOneToOne() {
        let layout = KitchenLayout(screenSize: KitchenLayout.artSize)

        #expect(layout.viewPoint(CGPoint(x: 100, y: 200)) == CGPoint(x: 100, y: 200))
    }

    /// An 11" iPad is wider for its height than the art, so the art is
    /// scaled to the width and cropped evenly top and bottom.
    @Test func aWiderScreenCropsTheArtEvenlyTopAndBottom() {
        let layout = KitchenLayout(screenSize: CGSize(width: 1366, height: 900))

        #expect(layout.scale == 1)
        #expect(layout.viewPoint(.zero) == CGPoint(x: 0, y: -62))
        #expect(layout.viewPoint(CGPoint(x: 1366, y: 1024)) == CGPoint(x: 1366, y: 962))
    }

    @Test func scenePointsFlipToSpriteKitsYUpSpace() {
        let layout = KitchenLayout(screenSize: CGSize(width: 683, height: 512))

        #expect(layout.scale == 0.5)
        #expect(layout.scenePoint(CGPoint(x: 100, y: 1024)) == CGPoint(x: 50, y: 0))
    }

    /// The trash hole hugs the bottom-left corner, so in SpriteKit space its
    /// rectangle starts at the scene's origin.
    @Test func theTrashHoleSitsInTheScenesBottomLeftCorner() {
        let layout = KitchenLayout(screenSize: KitchenLayout.artSize)
        let hole = layout.sceneRect(KitchenLayout.trashHole)

        #expect(hole.origin == .zero)
        #expect(hole.size == KitchenLayout.trashHole.size)
    }
}
