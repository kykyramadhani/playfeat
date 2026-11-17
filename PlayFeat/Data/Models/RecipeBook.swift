//
//  RecipeBook.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  What the recipe book shows: every dish (and the baked flatbread it starts
//  from), with a short description and how it is made — two things that
//  together make it. The recipes themselves live in KitchenMenu and the
//  grill; RecipeBookTests keeps this list in step with them.
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
    /// The two things that together make `item`.
    let madeFrom: [Term]

    var id: String { item }
}

nonisolated enum RecipeBook {
    /// How many tiles the book has; the ones past `entries` show as locked.
    static let tileCount = 6

    // ponytail: placeholder text until the writers send the real descriptions.
    private static let loremIpsum: LocalizedStringResource =
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor."

    static let entries: [RecipeBookEntry] = [
        RecipeBookEntry(
            item: KitchenMenu.bakedFlatbread, name: "Baked Flatbread", description: loremIpsum,
            madeFrom: [.item(KitchenMenu.rawFlatbread), .tool(image: "KitchenGrill")]
        ),
        RecipeBookEntry(
            item: KitchenMenu.pepperFlatbread, name: "Pepper Flatbread", description: loremIpsum,
            madeFrom: [.item(KitchenMenu.bakedFlatbread), .item(KitchenMenu.pepper)]
        ),
        RecipeBookEntry(
            item: KitchenMenu.mushroomFlatbread, name: "Mushroom Flatbread", description: loremIpsum,
            madeFrom: [.item(KitchenMenu.bakedFlatbread), .item(KitchenMenu.mushroom)]
        ),
        RecipeBookEntry(
            item: KitchenMenu.slimyTentacles, name: "Slimy Tentacles", description: loremIpsum,
            madeFrom: [.item(KitchenMenu.tentacle), .item(KitchenMenu.slime)]
        ),
    ]
}
