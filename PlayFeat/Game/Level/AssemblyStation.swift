//
//  AssemblyStation.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  A spot in the kitchen where ingredients are put together into a dish: the
//  plate for flatbreads, the glass for drinks. It takes its own ingredients in
//  any order, one of each, and once they make a recipe they become that dish.
//  Remembers only what sits on it; the scene draws and moves the items.
//

nonisolated enum AssemblyStationError: Error, Equatable {
    case refused(String)
    case notThere(String)
}

nonisolated struct AssemblyStation: Equatable {
    /// The ingredients this station collects.
    let ingredients: Set<String>
    /// Finished dishes it can hold, put back down after being carried off.
    let dishes: Set<String>

    /// What sits here, in the order it was put down.
    private(set) var contents: [String] = []

    static let plate = AssemblyStation(
        ingredients: [KitchenMenu.bakedFlatbread, KitchenMenu.pepper, KitchenMenu.mushroom],
        dishes: [KitchenMenu.pepperFlatbread, KitchenMenu.mushroomFlatbread]
    )

    static let glass = AssemblyStation(
        ingredients: [KitchenMenu.slime, KitchenMenu.tentacle],
        dishes: [KitchenMenu.sunsetSorbet]
    )

    // MARK: - Queries

    /// Whether `item` can be put down here now. A dish needs the station to
    /// itself; an ingredient needs to be one of this station's, not already
    /// here, and no finished dish in the way.
    func accepts(_ item: String) -> Bool {
        if dishes.contains(item) { return contents.isEmpty }
        return ingredients.contains(item) && !contents.contains(item) && !holdsDish
    }

    /// The dish the ingredients here make, ready for `combine()`.
    var completedDish: String? {
        holdsDish ? nil : KitchenMenu.dish(madeFrom: contents)
    }

    private var holdsDish: Bool { contents.contains(where: dishes.contains) }

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
