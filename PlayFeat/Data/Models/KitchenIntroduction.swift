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

    /// What `levelID` brings into the kitchen, in the order it is shown:
    /// level 1 opens with the grill and the two flatbreads, level 4 adds the
    /// glass and its dessert.
    /// ponytail: kept in code until the level files list what they introduce.
    static func introduced(byLevel levelID: String) -> [KitchenIntroduction] {
        switch levelID {
        case "1-1": [sunGrill, pepperFlatbread, mushroomFlatbread]
        case "1-4": [glass, slimyTentacles]
        default: []
        }
    }
}
