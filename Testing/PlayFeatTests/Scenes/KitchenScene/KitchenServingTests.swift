//
//  KitchenServingTests.swift
//  PlayFeatTests
//  Created by kyky on 13/11/26.
//
//  Handing dishes to customers through each seat's invisible serve area.
//  Driven straight through `settle`, so no camera or hands are needed.
//

import CoreGraphics
import SpriteKit
import Testing
@testable import PlayFeat

@MainActor
struct KitchenServingTests {

    /// A kitchen with a pepper-flatbread customer and a mushroom-flatbread
    /// customer, both seated from the opening bell.
    private func makeScene() -> (KitchenScene, KitchenDay) {
        let scene = KitchenScene(size: KitchenLayout.artSize)
        var generator = SeededGenerator(state: 1)
        let level = makeLevel(customers: [
            .init(arriveAt: 0, type: .regular, order: KitchenMenu.pepperFlatbread, patienceSec: 45),
            .init(arriveAt: 0, type: .regular, order: KitchenMenu.mushroomFlatbread, patienceSec: 45),
        ])
        let day = KitchenDay(level: level, seatCount: 2, using: &generator)
        scene.prepare(for: day, pantry: Planet.kepler186f.pantry)
        return (scene, day)
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
        #expect(day.coins == KitchenDay.coinsPerDish)
        #expect(day.presentCustomers.map(\.dish) == [KitchenMenu.mushroomFlatbread])
    }

    @Test func aDishNobodyThereOrderedIsNotServed() throws {
        let (scene, day) = makeScene()
        let seat = try #require(seat(ordering: KitchenMenu.pepperFlatbread, in: day))

        let dish = letGo(KitchenMenu.sunsetSorbet, atArtPoint: KitchenLayout.seats[seat].orderSheet.center, in: scene)

        #expect(dish.fallingSince != nil)
        #expect(day.coins == 0)
        #expect(day.presentCustomers.count == 2)
    }

    /// The two seats' areas overlap above the first alien's head; a dish let
    /// go there goes to whichever customer ordered it.
    @Test func whereServeAreasOverlapTheCustomerWhoOrderedItGetsIt() {
        let (scene, day) = makeScene()
        let overlap = KitchenLayout.seats[0].serveArea.intersection(KitchenLayout.seats[1].serveArea)
        #expect(!overlap.isEmpty)

        _ = letGo(KitchenMenu.mushroomFlatbread, atArtPoint: overlap.center, in: scene)

        #expect(day.presentCustomers.map(\.dish) == [KitchenMenu.pepperFlatbread])
    }
}
