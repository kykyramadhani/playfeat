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

    /// The order sheet reaches over the counter, so a dish carried past it
    /// on the way to a plate must not be handed over.
    @Test func aDishLetGoOverTheOrderSheetAloneIsNotServed() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        _ = letGo(KitchenMenu.pepperFlatbread, atArtPoint: try orderSheetPointOutOfReach(of: seat), in: scene)

        #expect(day.points == 0)
        #expect(day.presentCustomers.count == 2)
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
        let overlap = KitchenLayout.seats[0].serveArea.intersection(KitchenLayout.seats[2].serveArea)
        #expect(!overlap.isEmpty)

        _ = letGo(KitchenMenu.mushroomFlatbread, atArtPoint: overlap.center, in: scene)

        #expect(day.presentCustomers.map(\.dish) == [Planet.kepler186f.kitchen.angryOrder])
    }

    // MARK: - Magnet

    /// A dish placed at `point` (art points), as if a hand were carrying it.
    private func carried(_ item: String, atArtPoint point: CGPoint, in scene: KitchenScene) -> KitchenBubbleNode {
        let node = KitchenBubbleNode(ingredient: item, radius: 80)
        node.position = scene.layout.scenePoint(point)
        node.heldBy = 0
        return node
    }

    /// Just outside the serve area, within the magnet's reach.
    private func nearServeArea(of seat: Int) -> CGPoint {
        let area = KitchenLayout.seats[seat].serveArea
        return CGPoint(x: area.midX, y: area.maxY + KitchenLayout.serveMagnetReach / 2)
    }

    @Test func aCustomerPullsInTheDishTheyOrderedWhenItComesNear() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        let dish = carried(KitchenMenu.pepperFlatbread, atArtPoint: nearServeArea(of: seat), in: scene)

        #expect(scene.magnetSeat(for: dish) == seat)
    }

    @Test func aCustomerDoesntPullInADishTheyDidntOrder() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        let dish = carried(KitchenMenu.slimyTentacles, atArtPoint: nearServeArea(of: seat), in: scene)

        #expect(scene.magnetSeat(for: dish) == nil)
    }

    @Test func aDishCarriedOverTheOrderSheetAloneIsntPulledIn() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        let dish = carried(KitchenMenu.pepperFlatbread, atArtPoint: try orderSheetPointOutOfReach(of: seat), in: scene)

        #expect(scene.magnetSeat(for: dish) == nil)
    }

    /// A corner of the seat's order sheet beyond the alien's serve area and
    /// the magnet's reach around it.
    private func orderSheetPointOutOfReach(of seat: Int) throws -> CGPoint {
        let reach = KitchenLayout.serveMagnetReach
        let pulledIn = KitchenLayout.seats[seat].serveArea.insetBy(dx: -reach, dy: -reach)
        let sheet = KitchenLayout.seats[seat].orderSheet.insetBy(dx: 1, dy: 1)
        let corners = [CGPoint(x: sheet.minX, y: sheet.minY), CGPoint(x: sheet.maxX, y: sheet.minY),
                       CGPoint(x: sheet.minX, y: sheet.maxY), CGPoint(x: sheet.maxX, y: sheet.maxY)]
        return try #require(corners.first { !pulledIn.contains($0) })
    }

    @Test func aDishFarFromTheCustomerIsntPulledIn() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))
        let area = KitchenLayout.seats[seat].serveArea

        let far = CGPoint(x: area.midX, y: area.maxY + KitchenLayout.serveMagnetReach * 2)
        let dish = carried(KitchenMenu.pepperFlatbread, atArtPoint: far, in: scene)

        #expect(scene.magnetSeat(for: dish) == nil)
    }
}
