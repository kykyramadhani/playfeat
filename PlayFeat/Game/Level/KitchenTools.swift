//
//  KitchenTools.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  How many plates and glasses stand on the counter. On a story day the
//  player owns one of each to start and can buy a second in the shop;
//  glasses only come out on a level that has them. The marathon sets its
//  own as the run goes on.
//

nonisolated struct KitchenTools: Equatable {
    let plates: Int
    let glasses: Int

    init(plates: Int, glasses: Int) {
        self.plates = plates
        self.glasses = glasses
    }

    init(for level: LevelData, ownedPlates: Int, ownedGlasses: Int) {
        self.init(plates: ownedPlates, glasses: level.cups ? ownedGlasses : 0)
    }
}
