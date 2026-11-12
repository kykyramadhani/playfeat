//
//  KitchenSceneTests.swift
//  PlayFeatTests
//  Created by kyky on 12/11/26.
//
//  Where a let-go ingredient ends up: the trash hole, a storage box, or the
//  floor. Driven straight through `settle`, so no camera or hands are needed.
//

import CoreGraphics
import SpriteKit
import Testing
@testable import PlayFeat

@MainActor
struct KitchenSceneTests {

    private func makeScene() -> KitchenScene {
        let scene = KitchenScene(size: KitchenLayout.artSize)
        var generator = SeededGenerator(state: 1)
        let day = KitchenDay(level: makeLevel(), seatCount: 2, using: &generator)
        scene.prepare(for: day, pantry: Planet.kepler186f.pantry)
        return scene
    }

    private func letGo(_ ingredient: String, atArtPoint point: CGPoint, in scene: KitchenScene) -> KitchenBubbleNode {
        let node = KitchenBubbleNode(ingredient: ingredient, radius: 80)
        node.position = scene.layout.scenePoint(point)
        scene.addChild(node)
        scene.bubbles.append(node)
        scene.settle(node)
        return node
    }

    @Test func anItemLetGoOverTheTrashHoleIsThrownAway() {
        let scene = makeScene()

        _ = letGo("emberPepper", atArtPoint: KitchenLayout.trashHole.center, in: scene)

        #expect(scene.bubbles.isEmpty)
    }

    @Test func anItemLetGoOverAStorageBoxIsParkedThere() {
        let scene = makeScene()

        let node = letGo("duskFlatbread", atArtPoint: KitchenLayout.storageSlots[0], in: scene)

        #expect(node.parkedIn == 0)
        #expect(scene.storage.slots[0] === node)
    }

    /// One item per box: a second one let go over a full box falls instead.
    @Test func aFullBoxTurnsTheNextItemAway() {
        let scene = makeScene()
        _ = letGo("duskFlatbread", atArtPoint: KitchenLayout.storageSlots[0], in: scene)

        let second = letGo("emberPepper", atArtPoint: CGPoint(x: 1100, y: 800), in: scene)

        #expect(second.parkedIn == nil)
        #expect(second.fallingSince != nil)
    }

    @Test func anItemLetGoInMidAirFalls() {
        let scene = makeScene()

        let node = letGo("duskMushroom", atArtPoint: CGPoint(x: 683, y: 400), in: scene)

        #expect(node.fallingSince != nil)
        #expect(scene.bubbles.contains { $0 === node })
    }
}
