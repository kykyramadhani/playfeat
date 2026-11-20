//
//  KitchenIntroduction.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  A tool or dish shown to the player the first time a level brings it into
//  the kitchen, in a "New Tools" or "New Menu" popup before the countdown.
//

import Foundation

nonisolated struct KitchenIntroduction: Identifiable, Equatable {
    enum Kind: Equatable {
        case tool(image: String)
        /// A dish, drawn from its KitchenMenu id.
        case menu(item: String)
    }

    /// Remembered once seen, so each introduction plays only once.
    let id: String
    let kind: Kind
    let name: LocalizedStringResource
    let description: LocalizedStringResource
}

nonisolated extension KitchenIntroduction {
    static let sunGrill = KitchenIntroduction(
        id: "tool.grill", kind: .tool(image: "KitchenGrill"), name: "Sun Grill",
        description: "Use the great power of the sun to grill your food!"
    )
    static let glass = KitchenIntroduction(
        id: "tool.glass", kind: .tool(image: "KitchenGlass"), name: "Glass",
        description: "Desserts are put together in the glass."
    )

    // MARK: - Recipes, each with how to cook it

    static let pepperFlatbread = KitchenIntroduction(
        id: "menu.\(KitchenMenu.pepperFlatbread)", kind: .menu(item: KitchenMenu.pepperFlatbread),
        name: "Pepper Flatbread",
        description: "Bake a flatbread on the grill, put it on the plate, then add a pepper."
    )
    static let mushroomFlatbread = KitchenIntroduction(
        id: "menu.\(KitchenMenu.mushroomFlatbread)", kind: .menu(item: KitchenMenu.mushroomFlatbread),
        name: "Mushroom Flatbread",
        description: "Bake a flatbread on the grill, put it on the plate, then add a mushroom."
    )
    static let slimyTentacles = KitchenIntroduction(
        id: "menu.\(KitchenMenu.slimyTentacles)", kind: .menu(item: KitchenMenu.slimyTentacles),
        name: "Slimy Tentacles",
        description: "Put a tentacle in the glass, then pour green slime over it."
    )

    // MARK: - Planet 2

    static let pot = KitchenIntroduction(
        id: "tool.pot", kind: .tool(image: "KitchenPot"), name: "Pot",
        description: "Boil the noodles in the pot before they go in the bowl."
    )

    static let noodleBowl = KitchenIntroduction(
        id: "tool.bowl", kind: .tool(image: "NoodleBowl"), name: "Noodle Bowl",
        description: "Noodle dishes are put together in the bowl."
    )

    static let cookiePlate = KitchenIntroduction(
        id: "tool.cookiePlate", kind: .tool(image: "KitchenPlate"), name: "Cookie Plate",
        description: "The Star Cookie is put together on the cookie plate."
    )

    static let coralNoodles = KitchenIntroduction(
        id: "menu.\(KitchenMenu.coralNoodles)", kind: .menu(item: KitchenMenu.coralNoodles),
        name: "Coral Noodles",
        description: "Boil noodles in the pot, put them in the bowl, then add a coral leaf."
    )

    static let urchinNoodles = KitchenIntroduction(
        id: "menu.\(KitchenMenu.urchinNoodles)", kind: .menu(item: KitchenMenu.urchinNoodles),
        name: "Urchin Noodles",
        description: "Boil noodles in the pot, put them in the bowl, then add a bubble urchin."
    )

    static let clamNoodles = KitchenIntroduction(
        id: "menu.\(KitchenMenu.clamNoodles)", kind: .menu(item: KitchenMenu.clamNoodles),
        name: "Clam Noodles",
        description: "Boil noodles, put them in the bowl, then grill a lantern clam and add it."
    )

    static let starCookie = KitchenIntroduction(
        id: "menu.\(KitchenMenu.starCookie)", kind: .menu(item: KitchenMenu.starCookie),
        name: "Star Cookie",
        description: "Put a sea cookie on the cookie plate, then add starfish sugar on top."
    )

    /// What `levelID` brings into the kitchen, in the order it is shown:
    /// level 1 opens with the grill and the two flatbreads, level 4 adds the
    /// glass and its dessert. On Planet 2, 2-1 opens with the pot, the bowl
    /// and Coral Noodles, then each day adds its dish (the grill on 2-3 is
    /// Planet 1's, already met), and 2-4 the cookie plate and Star Cookie.
    /// ponytail: kept in code until the level files list what they introduce.
    static func introduced(byLevel levelID: String) -> [KitchenIntroduction] {
        switch levelID {
        case "1-1": [sunGrill, pepperFlatbread, mushroomFlatbread]
        case "1-4": [glass, slimyTentacles]
        case "2-1": [pot, noodleBowl, coralNoodles]
        case "2-2": [urchinNoodles]
        case "2-3": [clamNoodles]
        case "2-4": [cookiePlate, starCookie]
        default: []
        }
    }
}
