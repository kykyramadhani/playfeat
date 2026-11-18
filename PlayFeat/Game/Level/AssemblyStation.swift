//
//  AssemblyStation.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  A spot in the kitchen where a dish is put together: on Planet 1 the
//  plate for the flatbreads and the glass for the dessert, on Planet 2 the
//  noodle bowl and the cookie plate. What each takes follows the design's
//  placement table: an empty plate takes a flatbread (even a raw one, which
//  then only sits there), a topping or a finished dish; the bowl refuses
//  raw noodles and a raw clam; a base and a topping go together in either
//  order and make the dish. Remembers only what sits on it; the scene draws
//  and moves the items.
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

    /// Planet 2's noodle bowl: boiled noodles, a topping, or a finished
    /// noodle dish. Noodles must be boiled and a clam grilled first.
    static let bowl = AssemblyStation(placementRules: [
        emptyKey: [
            KitchenMenu.boiledNoodles, KitchenMenu.coral, KitchenMenu.urchin, KitchenMenu.grilledClam,
            KitchenMenu.coralNoodles, KitchenMenu.urchinNoodles, KitchenMenu.clamNoodles,
        ],
        KitchenMenu.boiledNoodles: [KitchenMenu.coral, KitchenMenu.urchin, KitchenMenu.grilledClam],
        KitchenMenu.coral: [KitchenMenu.boiledNoodles],
        KitchenMenu.urchin: [KitchenMenu.boiledNoodles],
        KitchenMenu.grilledClam: [KitchenMenu.boiledNoodles],
    ])

    /// Planet 2's cookie plate: a sea cookie, starfish sugar or a finished
    /// Star Cookie.
    static let cookiePlate = AssemblyStation(placementRules: [
        emptyKey: [KitchenMenu.seaCookie, KitchenMenu.starfishSugar, KitchenMenu.starCookie],
        KitchenMenu.seaCookie: [KitchenMenu.starfishSugar],
        KitchenMenu.starfishSugar: [KitchenMenu.seaCookie],
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
