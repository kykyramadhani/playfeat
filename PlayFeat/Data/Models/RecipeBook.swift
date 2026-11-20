//
//  RecipeBook.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  What each planet's recipe book shows: every dish (and what a tool cooks
//  for it, such as the baked flatbread), with a short description and how
//  it is made — two things that together make it — and then each raw
//  ingredient, with the dishes it goes in. A page stays hidden until the
//  kitchen has introduced it ("New Menu", or the tool that cooks it). The
//  recipes themselves live in KitchenMenu and the cooking tools;
//  RecipeBookTests keeps these lists in step with them.
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
    /// `planet`'s pages, dishes first.
    static func entries(on planet: Planet.ID) -> [RecipeBookEntry] {
        switch planet {
        case .kepler186f: keplerEntries
        case .k2332b: k2332bEntries
        }
    }

    /// The book's dishes that `item` goes straight into.
    static func dishes(using item: String) -> [RecipeBookEntry] {
        (keplerEntries + k2332bEntries).filter { $0.madeFrom.contains(.item(item)) }
    }

    private static let keplerEntries: [RecipeBookEntry] = [
        RecipeBookEntry(
            item: KitchenMenu.bakedFlatbread, name: "Baked Flatbread",
            description: "Ooh, that smells like bread—hold on, I actually made bread!",
            madeFrom: [.item(KitchenMenu.rawFlatbread), .tool(image: "KitchenGrill")],
            unlockedBy: KitchenIntroduction.sunGrill.id
        ),
        RecipeBookEntry(
            item: KitchenMenu.pepperFlatbread, name: "Pepper Flatbread",
            description: "Mmm… hoo, hoo, HOT—why did I take such a big bite?",
            madeFrom: [.item(KitchenMenu.bakedFlatbread), .item(KitchenMenu.pepper)],
            unlockedBy: KitchenIntroduction.pepperFlatbread.id
        ),
        RecipeBookEntry(
            item: KitchenMenu.mushroomFlatbread, name: "Mushroom Flatbread",
            description: "Whoa, even with the bread on top I can still see the mushrooms glowing!",
            madeFrom: [.item(KitchenMenu.bakedFlatbread), .item(KitchenMenu.mushroom)],
            unlockedBy: KitchenIntroduction.mushroomFlatbread.id
        ),
        RecipeBookEntry(
            item: KitchenMenu.slimyTentacles, name: "Slimy Tentacles",
            description: "Eww, it wobbles when I move the glass—wait, let me do that again.",
            madeFrom: [.item(KitchenMenu.tentacle), .item(KitchenMenu.slime)],
            unlockedBy: KitchenIntroduction.slimyTentacles.id
        ),
        ingredient(
            KitchenMenu.rawFlatbread, name: "Raw Flatbread",
            description: "Oop, it folded over my hand like a tiny blanket.",
            unlockedBy: .sunGrill
        ),
        ingredient(
            KitchenMenu.pepper, name: "Pepper",
            description: "Phew, my nose is tingling and I haven’t even bitten it yet!",
            unlockedBy: .pepperFlatbread
        ),
        ingredient(
            KitchenMenu.mushroom, name: "Mushroom",
            description: "Oooh, look at you glowing in my cupboard like a tiny night-light!",
            unlockedBy: .mushroomFlatbread
        ),
        ingredient(
            KitchenMenu.tentacle, name: "Tentacle",
            description: "Ah!—oh, that’s my own hand making it wave.",
            unlockedBy: .slimyTentacles
        ),
        ingredient(
            KitchenMenu.slime, name: "Slime",
            description: "Eugh, it went ‘blorp’—I wonder if it’ll do that again.",
            unlockedBy: .slimyTentacles
        ),
    ]

    private static let k2332bEntries: [RecipeBookEntry] = [
        RecipeBookEntry(
            item: KitchenMenu.boiledNoodles, name: "Boiled Noodles",
            description: "Slurp—hold on, am I still eating the same noodle?",
            madeFrom: [.item(KitchenMenu.rawNoodles), .tool(image: "KitchenPot")],
            unlockedBy: KitchenIntroduction.pot.id
        ),
        RecipeBookEntry(
            item: KitchenMenu.grilledClam, name: "Grilled Clam",
            description: "Ooh, it opened up—hello in there, you smell surprisingly good!",
            madeFrom: [.item(KitchenMenu.rawClam), .tool(image: "KitchenGrill")],
            unlockedBy: KitchenIntroduction.clamNoodles.id
        ),
        RecipeBookEntry(
            item: KitchenMenu.coralNoodles, name: "Coral Noodles",
            description: "Crunch! Oh, that was the coral—I was worried I’d eaten a bit of the bowl.",
            madeFrom: [.item(KitchenMenu.boiledNoodles), .item(KitchenMenu.coral)],
            unlockedBy: KitchenIntroduction.coralNoodles.id
        ),
        RecipeBookEntry(
            item: KitchenMenu.urchinNoodles, name: "Urchin Noodles",
            description: "Pop! Hehe, I’m trying to eat quietly but the bubbles aren’t helping.",
            madeFrom: [.item(KitchenMenu.boiledNoodles), .item(KitchenMenu.urchin)],
            unlockedBy: KitchenIntroduction.urchinNoodles.id
        ),
        RecipeBookEntry(
            item: KitchenMenu.clamNoodles, name: "Clam Noodles",
            description: "Mmm… I ate the clam first and now I’m checking its shell for bonus noodles.",
            madeFrom: [.item(KitchenMenu.boiledNoodles), .item(KitchenMenu.grilledClam)],
            unlockedBy: KitchenIntroduction.clamNoodles.id
        ),
        RecipeBookEntry(
            item: KitchenMenu.starCookie, name: "Star Cookie",
            description: "Ooh, a cookie covered in tiny stars—I’m going to eat a constellation!",
            madeFrom: [.item(KitchenMenu.seaCookie), .item(KitchenMenu.starfishSugar)],
            unlockedBy: KitchenIntroduction.starCookie.id
        ),
        ingredient(
            KitchenMenu.rawNoodles, name: "Tide Noodles",
            description: "Huh, I tried to untangle these and somehow made a smaller, tighter tangle.",
            unlockedBy: .pot
        ),
        ingredient(
            KitchenMenu.coral, name: "Coral Leaf",
            description: "Crunch, crunch… ooh, I can hear myself eating inside my helmet!",
            unlockedBy: .coralNoodles
        ),
        ingredient(
            KitchenMenu.urchin, name: "Bubble Urchin",
            description: "Ooh, bubbles—I’ll poke just one before we start cooking… okay, two.",
            unlockedBy: .urchinNoodles
        ),
        ingredient(
            KitchenMenu.rawClam, name: "Lantern Clam",
            description: "Whoa, look inside—it’s like a tiny lunchbox someone packed for me!",
            unlockedBy: .clamNoodles
        ),
        ingredient(
            KitchenMenu.seaCookie, name: "Sea Cookie",
            description: "Sniff, sniff… smells like a cookie, looks like a sand dollar, going in my mouth.",
            unlockedBy: .starCookie
        ),
        ingredient(
            KitchenMenu.starfishSugar, name: "Starfish Sugar",
            description: "Aww, tiny stars—I’ve spent so long arranging them that I forgot to taste one!",
            unlockedBy: .starCookie
        ),
    ]

    /// A raw ingredient's page, found once the first dish using it is.
    private static func ingredient(
        _ item: String, name: LocalizedStringResource, description: LocalizedStringResource,
        unlockedBy introduction: KitchenIntroduction
    ) -> RecipeBookEntry {
        RecipeBookEntry(item: item, name: name, description: description, madeFrom: [], unlockedBy: introduction.id)
    }
}
