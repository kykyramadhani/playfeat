//
//  AssemblyStation.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  A spot in the kitchen where a dish is put together: the plate for the
//  flatbreads, the glass for the dessert. What each takes follows the
//  prototype's placement table: an empty plate takes a flatbread (even a raw
//  one, which then only sits there), a topping or a finished dish; a base
//  and a topping go together in either order and make the dish. Remembers
//  only what sits on it; the scene draws and moves the items.
//

nonisolated enum AssemblyStationError: Error, Equatable {
    case refused(String)
    case notThere(String)
}

nonisolated struct AssemblyStation: Equatable {
    /// What may go on top of each thing that can sit here alone; the
    /// `emptyKey` entry is what an empty station takes.
    let placementRules: [String: Set<String>]

    /// What sits here, in the order it was put down.
    private(set) var contents: [String] = []

    static let emptyKey = ""

    static let plate = AssemblyStation(placementRules: [
        emptyKey: [
            KitchenMenu.rawFlatbread, KitchenMenu.bakedFlatbread, KitchenMenu.pepper, KitchenMenu.mushroom,
            KitchenMenu.pepperFlatbread, KitchenMenu.mushroomFlatbread,
        ],
        KitchenMenu.bakedFlatbread: [KitchenMenu.pepper, KitchenMenu.mushroom],
        KitchenMenu.pepper: [KitchenMenu.bakedFlatbread],
        KitchenMenu.mushroom: [KitchenMenu.bakedFlatbread],
    ])

    static let glass = AssemblyStation(placementRules: [
        emptyKey: [KitchenMenu.tentacle, KitchenMenu.slime, KitchenMenu.slimyTentacles],
        KitchenMenu.tentacle: [KitchenMenu.slime],
        KitchenMenu.slime: [KitchenMenu.tentacle],
    ])

    // MARK: - Queries

    /// Whether `item` can be put down here now.
    func accepts(_ item: String) -> Bool {
        guard contents.count <= 1 else { return false }
        return placementRules[contents.first ?? Self.emptyKey]?.contains(item) ?? false
    }

    /// The dish the ingredients here make, ready for `combine()`.
    var completedDish: String? {
        contents.count > 1 ? KitchenMenu.dish(madeFrom: contents) : nil
    }

    // MARK: - Commands

    mutating func add(_ item: String) throws(AssemblyStationError) {
        guard accepts(item) else { throw .refused(item) }
        contents.append(item)
    }

    mutating func remove(_ item: String) throws(AssemblyStationError) {
        guard let index = contents.firstIndex(of: item) else { throw .notThere(item) }
        contents.remove(at: index)
    }

    /// Turns the ingredients here into the dish they make. Does nothing when
    /// they don't make one yet.
    mutating func combine() {
        guard let dish = completedDish else { return }
        contents = [dish]
    }
}
