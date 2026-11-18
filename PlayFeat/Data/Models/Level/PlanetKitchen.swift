//
//  PlanetKitchen.swift
//  PlayFeat
//  Created by Owen Limantoro on 18/11/26.
//
//  What one planet's kitchen is made of: which cooking tools it has and
//  what each cooks, how fast food cooks and is ruined, the rules of its
//  main-dish and dessert stations, its customers and what they order. The
//  scene, the customer flows and the validation all read from here, so a
//  planet's kitchen is data, not code.
//

import Foundation

nonisolated struct PlanetKitchen {
    /// What each of the planet's cooking tools cooks.
    let tools: [CookingTool.Kind: [CookingRecipe]]
    let cookTiming: CookTiming
    /// Where the main dishes are put together: the plate, or the noodle bowl.
    let mainStation: AssemblyStation
    /// Where the dessert is put together: the glass, or the cookie plate.
    let dessertStation: AssemblyStation
    /// Every dish customers can order here.
    let dishes: Set<String>
    /// The dessert, whose station only comes out once it is on the menu.
    let dessert: String
    /// What an angry alien always orders.
    let angryOrder: String
    /// Who sits in the regular seats.
    let regularAlien: AlienSpecies
    /// Who sits in the angry seat.
    let angryAlien: AlienSpecies

    /// The alien drawn for a customer of `type`.
    func alien(for type: CustomerType) -> AlienSpecies {
        switch type {
        case .regular: regularAlien
        case .angry: angryAlien
        }
    }

    /// The cooking tools on the counter on `level`: the ones it lists, or
    /// all of the planet's when it lists none.
    func toolKinds(on level: LevelData) -> [CookingTool.Kind] {
        (level.tools ?? Array(tools.keys)).filter { tools[$0] != nil }.sorted()
    }

    /// The cooking tools `level` starts with, empty and ready to cook.
    func cookingTools(on level: LevelData) -> [CookingTool.Kind: CookingTool] {
        let pairs = toolKinds(on: level).map { kind in
            let tool = CookingTool(
                kind: kind, recipes: tools[kind] ?? [], timing: cookTiming, burnMultiplier: level.burnTimeMultiplier
            )
            return (kind, tool)
        }
        return Dictionary(uniqueKeysWithValues: pairs)
    }
}
