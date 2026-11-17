//
//  KitchenSceneFixtures.swift
//  PlayFeatTests
//  Created by kyky on 16/11/26.
//
//  A kitchen scene ready to play `level` at the art's own size, with the
//  counter's positions and the plates and glasses a player owns.
//

import Foundation
@testable import PlayFeat

@MainActor
func makeKitchenScene(
    level: LevelData = makeLevel(),
    ownedPlates: Int = 1,
    ownedGlasses: Int = 1
) -> (scene: KitchenScene, day: KitchenDay) {
    let scene = KitchenScene(size: KitchenLayout.artSize)
    let day = makeDay(level, plates: ownedPlates, glasses: ownedGlasses)
    scene.prepare(for: day, bubbleSupply: StoryBubbleSupply(level: level))
    scene.grill = Grill(burnMultiplier: level.burnTimeMultiplier)
    return (scene, day)
}
