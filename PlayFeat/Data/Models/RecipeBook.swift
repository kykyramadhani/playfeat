//
//  RecipeBook.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  What the recipe book shows: every dish (and the baked flatbread it starts
//  from), with a short description and how it is made — two things that
//  together make it — and then each raw ingredient, with the dishes it goes
//  in. A page stays hidden until the kitchen has introduced
//  it ("New Menu", or the grill for the baked flatbread). The recipes
//  themselves live in KitchenMenu and the grill; RecipeBookTests keeps this
//  list in step with them.
//

import Foundation

nonisolated struct RecipeBookEntry: Identifiable, Equatable {
    /// One side of a "how to cook" sum: an item, or the tool it goes on.
    enum Term: Equatable {
        case item(String)
        case tool(image: String)
    }

    /// The KitchenMenu id of what this makes.
    let item: String
    let name: LocalizedStringResource
    let description: LocalizedStringResource
    /// The two things that together make `item`; empty for a raw ingredient.
    let madeFrom: [Term]
    /// The kitchen introduction that reveals this page once it's been seen.
    let unlockedBy: KitchenIntroduction.ID

    var id: String { item }

    var isIngredient: Bool { madeFrom.isEmpty }

    func isUnlocked(afterSeeing seenIntroductions: Set<String>) -> Bool {
        seenIntroductions.contains(unlockedBy)
    }
}

nonisolated enum RecipeBook {
    // ponytail: placeholder text until the writers send the real descriptions.
    private static let loremIpsum: LocalizedStringResource =
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor."

    static let entries: [RecipeBookEntry] = [
        RecipeBookEntry(
            item: KitchenMenu.bakedFlatbread, name: "Baked Flatbread", description: loremIpsum,
            madeFrom: [.item(KitchenMenu.rawFlatbread), .tool(image: "KitchenGrill")],
            unlockedBy: KitchenIntroduction.sunGrill.id
        ),
        RecipeBookEntry(
            item: KitchenMenu.pepperFlatbread, name: "Pepper Flatbread", description: loremIpsum,
            madeFrom: [.item(KitchenMenu.bakedFlatbread), .item(KitchenMenu.pepper)],
            unlockedBy: KitchenIntroduction.pepperFlatbread.id
        ),
        RecipeBookEntry(
            item: KitchenMenu.mushroomFlatbread, name: "Mushroom Flatbread", description: loremIpsum,
            madeFrom: [.item(KitchenMenu.bakedFlatbread), .item(KitchenMenu.mushroom)],
            unlockedBy: KitchenIntroduction.mushroomFlatbread.id
        ),
        RecipeBookEntry(
            item: KitchenMenu.slimyTentacles, name: "Slimy Tentacles", description: loremIpsum,
            madeFrom: [.item(KitchenMenu.tentacle), .item(KitchenMenu.slime)],
            unlockedBy: KitchenIntroduction.slimyTentacles.id
        ),
        ingredient(KitchenMenu.rawFlatbread, name: "Raw Flatbread", unlockedBy: .sunGrill),
        ingredient(KitchenMenu.pepper, name: "Pepper", unlockedBy: .pepperFlatbread),
        ingredient(KitchenMenu.mushroom, name: "Mushroom", unlockedBy: .mushroomFlatbread),
        ingredient(KitchenMenu.tentacle, name: "Tentacle", unlockedBy: .slimyTentacles),
        ingredient(KitchenMenu.slime, name: "Slime", unlockedBy: .slimyTentacles),
    ]

    /// The book's dishes that `item` goes straight into.
    static func dishes(using item: String) -> [RecipeBookEntry] {
        entries.filter { $0.madeFrom.contains(.item(item)) }
    }

    /// A raw ingredient's page, found once the first dish using it is.
    private static func ingredient(
        _ item: String, name: LocalizedStringResource, unlockedBy introduction: KitchenIntroduction
    ) -> RecipeBookEntry {
        RecipeBookEntry(item: item, name: name, description: loremIpsum, madeFrom: [], unlockedBy: introduction.id)
    }
}
