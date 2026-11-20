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

        let counters = PlanetCatalog.all.flatMap { [$0.kitchen.counter] + $0.kitchen.earlyCounters }
        let lowestEdge = counters.flatMap { counter in
            CookingTool.Kind.allCases.map { counter.area(of: $0) }.filter { !$0.isNull }
                + counter.mainStationSpots(count: counter.maxMainStations)
                + counter.dessertStationSpots(count: counter.maxDessertStations)
        }.map(\.maxY).max() ?? 0

        #expect(lowestEdge > 0)
        #expect(layout.viewPoint(CGPoint(x: 0, y: lowestEdge)).y <= macBook.height)
    }

    /// A screen taller than the art fits its width instead, with no margins.
    @Test func aTallerScreenFitsTheWidthWithNoSideMargin() {
        let layout = KitchenLayout(screenSize: CGSize(width: 683, height: 1024))

        #expect(layout.scale == 0.5)
        #expect(layout.sideMargin == 0)
    }

    // MARK: - Truck

    /// On a screen the art's shape nothing moves: the bands tile the art and
    /// each draws its layer exactly over the art.
    @Test func onTheArtsShapeTheTruckBandsTileTheArt() {
        let bands = KitchenLayout(screenSize: KitchenLayout.artSize).truckBands

        #expect(bands.map(\.screenRect.minX) == [0, 400, 966])
        #expect(bands.map(\.screenRect.maxX) == [400, 966, 1366])
        #expect(bands.allSatisfy { $0.layerRect == CGRect(origin: .zero, size: KitchenLayout.artSize) })
    }

    /// A wider screen keeps the walls' drawn shape at the screen's edges and
    /// widens only the plain middle.
    @Test func onAWiderScreenTheWallsStickToTheScreensEdges() {
        let bands = KitchenLayout(screenSize: CGSize(width: 1366, height: 512)).truckBands

        #expect(bands[0].screenRect == CGRect(x: 0, y: 0, width: 200, height: 512))
        #expect(bands[2].screenRect == CGRect(x: 1166, y: 0, width: 200, height: 512))
        #expect(bands[1].screenRect == CGRect(x: 200, y: 0, width: 966, height: 512))
        #expect(bands[0].layerRect.width == 683)
    }

    /// A taller screen fits the art's width, so the bands tile it unwidened,
    /// centred top to bottom like the art.
    @Test func onATallerScreenTheTruckSitsWithTheArt() {
        let bands = KitchenLayout(screenSize: CGSize(width: 683, height: 1024)).truckBands

        #expect(bands.map(\.screenRect.minX) == [0, 200, 483])
        #expect(bands.allSatisfy { $0.screenRect.minY == 256 && $0.screenRect.height == 512 })
    }

    // MARK: - Seats

    /// On a screen the art's shape every customer stands where it's drawn.
    @Test func onTheArtsShapeEverySeatStaysWhereItIsDrawn() {
        let layout = KitchenLayout(screenSize: KitchenLayout.artSize)

        for index in KitchenLayout.seats.indices {
            #expect(layout.seat(at: index).serveArea == KitchenLayout.seats[index].serveArea)
        }
    }

    /// On a wider screen the walls move out to the screen's edges, and each
    /// customer moves with the wall on its side: the left-wall and top-left
    /// seats to the left, the top-right seat to the right.
    @Test func onAWiderScreenEachSeatFollowsTheWallOnItsSide() {
        let wide = KitchenLayout(screenSize: CGSize(width: 1366, height: 512))
        let shifts = KitchenLayout.seats.indices.map { index in
            wide.seat(at: index).alien.minX - KitchenLayout.seats[index].alien.minX
        }

        #expect(shifts == [-683, 683, -683])
    }

    /// The alien, its order sheet and the serve area the hands are tested
    /// against all move together, so serving lines up with the drawing.
    @Test func aMovedSeatKeepsItsAlienAndOrderSheetTogether() {
        let original = KitchenLayout.seats[0]
        let moved = KitchenLayout(screenSize: CGSize(width: 1366, height: 512)).seat(at: 0)

        #expect(moved.orderSheet == original.orderSheet.offsetBy(dx: -683, dy: 0))
        #expect(moved.alienPose.center.x == original.alienPose.center.x - 683)
        #expect(moved.serveArea == original.serveArea.offsetBy(dx: -683, dy: 0))
    }

    /// Each customer slides until its whole picture is past its wall: left
    /// off the art from the left wall, up off it from the ceiling.
    @Test func everyCustomerSlidesPastItsWallToLeave() {
        for index in KitchenLayout.seats.indices {
            let seat = KitchenLayout.seats[index]
            let slide = KitchenLayout.offstageOffset(ofSeatAt: index)
            let gone = seat.alienPose.drawnBounds.offsetBy(dx: slide.width, dy: slide.height)

            switch seat.entersFrom {
            case .left: #expect(gone.maxX <= 0)
            case .top: #expect(gone.maxY <= 0)
            }
        }
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

    /// The two green aliens take regular customers; the red one is the angry alien's.
    @Test func theRedAliensPositionIsTheAngryCustomers() {
        #expect(KitchenLayout.positionTypes == [.regular, .regular, .angry])
    }
}
