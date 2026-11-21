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
    /// scaled to the height and centred, with equal margins left and right.
    @Test func aWiderScreenKeepsTheWholeArtHeightAndCentresIt() {
        let layout = KitchenLayout(screenSize: CGSize(width: 1366, height: 512))

        #expect(layout.scale == 0.5)
        #expect(layout.sideMargin == 341.5)
        #expect(layout.viewPoint(.zero) == CGPoint(x: 341.5, y: 0))
        #expect(layout.viewPoint(CGPoint(x: 1366, y: 1024)) == CGPoint(x: 1024.5, y: 512))
    }

    /// On a MacBook's 16:10 screen the stations at the bottom of the counter
    /// stay on screen, where the hands can reach them.
    @Test func theCountersStationsStayOnScreenOnAMacBook() {
        let macBook = CGSize(width: 1512, height: 945)
        let layout = KitchenLayout(screenSize: macBook)

        #expect(layout.viewPoint(CGPoint(x: 0, y: KitchenLayout.grill.maxY)).y <= macBook.height)
        #expect(layout.viewPoint(CGPoint(x: 0, y: KitchenLayout.pot.maxY)).y <= macBook.height)
    }

    /// A screen taller than the art fits its width instead, with no margins.
    @Test func aTallerScreenFitsTheWidthWithNoSideMargin() {
        let layout = KitchenLayout(screenSize: CGSize(width: 683, height: 1024))

        #expect(layout.scale == 0.5)
        #expect(layout.sideMargin == 0)
    }

    @Test func scenePointsFlipToSpriteKitsYUpSpace() {
        let layout = KitchenLayout(screenSize: CGSize(width: 683, height: 512))

        #expect(layout.scale == 0.5)
        #expect(layout.scenePoint(CGPoint(x: 100, y: 1024)) == CGPoint(x: 50, y: 0))
    }

    /// The window starts at the top of the art, so in SpriteKit space its
    /// top edge is the scene's top.
    @Test func theWindowReachesTheScenesTop() {
        let layout = KitchenLayout(screenSize: KitchenLayout.artSize)

        #expect(layout.sceneRect(KitchenLayout.window).maxY == KitchenLayout.artSize.height)
    }

    /// One plate stands beside the grill; a second goes further left, and
    /// never more than the counter has spots for.
    @Test func plateSpotsKeepTheFirstPlateBesideTheGrill() {
        let one = KitchenLayout.plates(1)
        let two = KitchenLayout.plates(2)

        #expect(one.count == 1)
        #expect(two.last == one.first)
        #expect(two[0].maxX < two[1].minX)
        #expect(KitchenLayout.plates(5).count == KitchenLayout.maxPlates)
    }

    @Test func glassSpotsKeepTheFirstGlassBesideTheGrill() {
        let two = KitchenLayout.glasses(2)

        #expect(KitchenLayout.glasses(1) == [two[0]])
        #expect(two[0].maxX < two[1].minX)
        #expect(KitchenLayout.glasses(0).isEmpty)
    }

    /// The first level keeps its customers to the left wall while the player learns.
    @Test func theFirstLevelsCustomersOnlyComeFromTheLeft() throws {
        let level = try LevelLoader.load("1-1")
        let seats = KitchenLayout.openSeats(on: level)

        #expect(!seats.isEmpty)
        #expect(seats.allSatisfy { KitchenLayout.seats[$0].entersFrom == .left })
    }

    /// Later levels open every edge: left, top and right.
    @Test func laterLevelsOpenEverySide() throws {
        let level = try LevelLoader.load("1-2")
        let sides = Set(KitchenLayout.openSeats(on: level).map { KitchenLayout.seats[$0].entersFrom })

        #expect(sides == Set(CustomerSide.allCases))
    }

    /// An alien coming in from the right slides off past the right edge.
    @Test func aRightSideAlienLeavesPastTheRightEdge() throws {
        let seat = try #require(KitchenLayout.seats.first { $0.entersFrom == .right })
        let drawn = seat.alienPose.drawnBounds.offsetBy(dx: seat.offstageOffset.width, dy: seat.offstageOffset.height)

        #expect(drawn.minX >= KitchenLayout.artSize.width)
    }

    @Test func twoGrillSlotsSitEitherSideOfTheRing() {
        let slots = KitchenLayout.grillSlots(2)

        #expect(KitchenLayout.grillSlots(1) == [KitchenLayout.grillRing])
        #expect(slots[0].x < KitchenLayout.grillRing.x && KitchenLayout.grillRing.x < slots[1].x)
    }
}
