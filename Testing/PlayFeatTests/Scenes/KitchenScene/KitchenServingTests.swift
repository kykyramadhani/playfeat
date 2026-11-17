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

    /// Below the order sheet and right of the alien: inside the serve area
    /// without touching either drawing.
    @Test func aDishNearTheCustomerIsServedWithoutTouchingThem() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))
        let area = KitchenLayout.seats[seat].serveArea
        let corner = CGPoint(x: area.maxX - 10, y: area.maxY - 10)
        #expect(!KitchenLayout.seats[seat].alien.contains(corner) || !KitchenLayout.seats[seat].orderSheet.contains(corner))

        let dish = letGo(KitchenMenu.pepperFlatbread, atArtPoint: corner, in: scene)

        #expect(!scene.bubbles.contains { $0 === dish })
        #expect(day.points == DishPricing.unupgraded.pay(for: KitchenMenu.pepperFlatbread))
        #expect(day.presentCustomers.map(\.dish) == [KitchenMenu.mushroomFlatbread])
    }

    /// As in the prototype, a dish the customer didn't order is turned away
    /// and lost.
    @Test func aWrongDishAtACustomerIsTurnedAwayAndLost() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        let dish = letGo(KitchenMenu.slimyTentacles, atArtPoint: KitchenLayout.seats[seat].orderSheet.center, in: scene)

        #expect(!scene.bubbles.contains { $0 === dish })
        #expect(day.points == 0)
        #expect(day.presentCustomers.count == 2)
    }

    /// Only dishes are handed over: an ingredient over a customer just falls.
    @Test func anIngredientOverACustomerFalls() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        let pepper = letGo(KitchenMenu.pepper, atArtPoint: KitchenLayout.seats[seat].orderSheet.center, in: scene)

        #expect(pepper.fallingSince != nil)
        #expect(day.presentCustomers.count == 2)
    }

    /// The left alien's area and the red alien's overlap above the left
    /// alien's head; a dish let go there goes to whichever customer ordered it.
    @Test func whereServeAreasOverlapTheCustomerWhoOrderedItGetsIt() {
        let (scene, day) = makeKitchenScene(level: makeLevel(
            counterSpots: 2, firstOrder: KitchenMenu.mushroomFlatbread, angryAt: [2], refillDelaySec: 0
        ))
        let overlap = KitchenLayout.seats[0].serveArea.intersection(KitchenLayout.seats[2].serveArea)
        #expect(!overlap.isEmpty)

        _ = letGo(KitchenMenu.mushroomFlatbread, atArtPoint: overlap.center, in: scene)

        #expect(day.presentCustomers.map(\.dish) == [KitchenMenu.angryOrder])
    }
}
