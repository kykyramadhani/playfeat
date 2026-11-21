//
//  KitchenServingTests.swift
//  PlayFeatTests
//  Created by kyky on 13/11/26.
//
//  Handing dishes to customers through each position's invisible serve
//  area. Driven straight through `settle`, so no camera or hands are needed.
//

import CoreGraphics
import SpriteKit
import Testing
@testable import PlayFeat

@MainActor
struct KitchenServingTests {

    /// A kitchen with a pepper-flatbread customer and a mushroom-flatbread
    /// customer, both at the counter from the opening bell.
    private func makeScene() -> (KitchenScene, KitchenDay) {
        makeKitchenScene(level: makeLevel(
            counterSpots: 2, orderPool: [KitchenMenu.mushroomFlatbread: 1], refillDelaySec: 0
        ))
    }

    private func letGo(_ item: String, atArtPoint point: CGPoint, in scene: KitchenScene) -> KitchenBubbleNode {
        let node = KitchenBubbleNode(ingredient: item, radius: 80)
        node.position = scene.layout.scenePoint(point)
        scene.addChild(node)
        scene.bubbles.append(node)
        scene.settle(node)
        return node
    }

    private func seat(ordering dish: String, in day: KitchenDay) -> Int? {
        day.presentCustomers.first { $0.dish == dish }?.seat
    }

    @Test func aDishLetGoOverTheCustomerIsServed() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        let dish = letGo(KitchenMenu.pepperFlatbread, atArtPoint: KitchenLayout.seats[seat].alien.center, in: scene)

        #expect(!scene.bubbles.contains { $0 === dish })
        #expect(day.points == DishPricing.unupgraded.pay(for: KitchenMenu.pepperFlatbread))
        #expect(day.presentCustomers.map(\.dish) == [KitchenMenu.mushroomFlatbread])
    }

    /// A dish the customer didn't order is turned away: it hangs for a
    /// moment under the red cross, then falls.
    @Test func aWrongDishAtACustomerIsTurnedAwayAndFalls() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        let dish = letGo(KitchenMenu.slimyTentacles, atArtPoint: KitchenLayout.seats[seat].alien.center, in: scene)

        #expect(dish.isRefused(at: day.elapsed))
        #expect(day.points == 0)
        #expect(day.presentCustomers.count == 2)
    }

    /// A flatbread lifted off the plate before its topping went on is
    /// turned away like any wrong dish, rather than falling past.
    @Test func aPlateMissingItsToppingIsTurnedAwayLikeAWrongDish() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))
        let flatbread = KitchenBubbleNode(ingredient: KitchenMenu.bakedFlatbread, radius: 80)
        flatbread.liftedFrom = .plate(0)
        flatbread.position = scene.layout.scenePoint(KitchenLayout.seats[seat].alien.center)
        scene.addChild(flatbread)
        scene.bubbles.append(flatbread)

        scene.settle(flatbread)

        #expect(flatbread.isRefused(at: day.elapsed))
        #expect(day.points == 0)
        #expect(day.presentCustomers.count == 2)
    }

    /// Only dishes are handed over: an ingredient over a customer just falls.
    @Test func anIngredientOverACustomerFalls() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        let pepper = letGo(KitchenMenu.pepper, atArtPoint: KitchenLayout.seats[seat].alien.center, in: scene)

        #expect(pepper.fallingSince != nil)
        #expect(day.presentCustomers.count == 2)
    }

    /// The left alien's area and the red alien's overlap above the left
    /// alien's head; a dish let go there goes to whichever customer ordered it.
    @Test func whereServeAreasOverlapTheCustomerWhoOrderedItGetsIt() {
        let (scene, day) = makeKitchenScene(level: makeLevel(
            counterSpots: 2, firstOrder: KitchenMenu.mushroomFlatbread, angryAt: [2], refillDelaySec: 0
        ))
        let overlap = KitchenLayout.seats[0].alien.intersection(KitchenLayout.seats[2].alien)
        #expect(!overlap.isEmpty)

        _ = letGo(KitchenMenu.mushroomFlatbread, atArtPoint: overlap.center, in: scene)

        #expect(day.presentCustomers.map(\.dish) == [Planet.kepler186f.kitchen.angryOrder])
    }

    // MARK: - The serve area's shape

    @Test func aDishLetGoOverTheOrderBubbleIsServed() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        _ = letGo(KitchenMenu.pepperFlatbread, atArtPoint: KitchenLayout.seats[seat].orderSheet.center, in: scene)

        #expect(day.points == DishPricing.unupgraded.pay(for: KitchenMenu.pepperFlatbread))
    }

    /// The alien and the bubble are tested by their own shapes, not one box
    /// around both: the empty corner of the order sheet serves nothing.
    @Test func aDishLetGoInTheOrderSheetsEmptyCornerIsNotServed() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        _ = letGo(KitchenMenu.pepperFlatbread, atArtPoint: try emptyCornerOfOrderSheet(at: seat), in: scene)

        #expect(day.points == 0)
        #expect(day.presentCustomers.count == 2)
    }

    /// A corner of the seat's order sheet box that is outside both the
    /// bubble's oval and the alien.
    private func emptyCornerOfOrderSheet(at seat: Int) throws -> CGPoint {
        let place = KitchenLayout.seats[seat]
        let sheet = place.orderSheet.insetBy(dx: 1, dy: 1)
        let corners = [CGPoint(x: sheet.minX, y: sheet.minY), CGPoint(x: sheet.maxX, y: sheet.minY),
                       CGPoint(x: sheet.minX, y: sheet.maxY), CGPoint(x: sheet.maxX, y: sheet.maxY)]
        return try #require(corners.first { !place.serveAreaContains($0) })
    }
}
