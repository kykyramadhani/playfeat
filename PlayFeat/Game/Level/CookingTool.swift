//
//  CookingTool.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  A kitchen tool that cooks, as in the prototype: the grill (a flatbread on
//  Planet 1, a Lantern Clam on Planet 2) and the pot (Tide Noodles). A raw
//  item cooks in `cookSec`; once done it keeps cooking, starts glowing as a
//  warning after a while and then is ruined. A done item can be put back on
//  and carries on from where it was. Putting an item on a taken slot
//  replaces what was there. One slot to start; the marathon can add a
//  second. Timed in play time, so a pause stops cooking.
//

import Foundation

nonisolated struct CookingTool: Equatable {
    enum Kind: String, Codable, CaseIterable, Comparable {
        case grill
        case pot

        static func < (lhs: Kind, rhs: Kind) -> Bool {
            allCases.firstIndex(of: lhs) ?? 0 < allCases.firstIndex(of: rhs) ?? 0
        }
    }

    /// How far an item on the tool has cooked.
    enum Doneness: Equatable {
        /// Still raw.
        case cooking
        /// Done and ready to take off.
        case cooked
        /// Still done, but glowing: about to be ruined.
        case overcooking
        /// Burnt or mushy, and no use for any dish.
        case ruined

        /// What an item cooked by `recipe` is by now.
        func item(of recipe: CookingRecipe) -> String {
            switch self {
            case .cooking: recipe.raw
            case .cooked, .overcooking: recipe.cooked
            case .ruined: recipe.ruined
            }
        }

        var needsWarning: Bool { self == .overcooking }
    }

    /// An item on a slot: what it is, when it went on, and how long it had
    /// cooked before.
    struct Slot: Equatable {
        let recipe: CookingRecipe
        let placedAt: TimeInterval
        let cookedBefore: TimeInterval
    }

    /// What the ring around an item on the tool shows, as in the prototype:
    /// filling yellow while it cooks, then red towards ruin, all black once
    /// ruined; and the warning sign just before that.
    struct Gauge: Equatable {
        enum Phase: Equatable { case baking, baked, burnt }

        let phase: Phase
        /// How much of the ring is filled, 0...1.
        let fraction: Double
        let isAboutToBurn: Bool
    }

    // MARK: - Tuning

    let kind: Kind
    /// What this tool cooks.
    let recipes: [CookingRecipe]
    let timing: CookTiming
    /// Seconds to cook; the marathon's faster-tool cards shorten it.
    var cookSec: TimeInterval
    /// Stretches the time before glowing and ruin (a level's `burnTimeMultiplier`).
    let burnMultiplier: Double

    var glowAt: TimeInterval { cookSec + timing.warnAfterDoneSec * burnMultiplier }
    var burnAt: TimeInterval { cookSec + timing.ruinAfterDoneSec * burnMultiplier }

    // MARK: - State

    private(set) var slots: [Slot?]

    init(kind: Kind, recipes: [CookingRecipe], timing: CookTiming, burnMultiplier: Double = 1, slotCount: Int = 1) {
        self.kind = kind
        self.recipes = recipes
        self.timing = timing
        cookSec = timing.cookSec
        self.burnMultiplier = burnMultiplier
        slots = Array(repeating: nil, count: max(slotCount, 1))
    }

    // MARK: - Queries

    /// A raw or done item this tool cooks, on any slot: a taken one swaps its item out.
    func accepts(_ item: String) -> Bool {
        recipe(of: item) != nil
    }

    func isTaken(_ slot: Int) -> Bool {
        slots.indices.contains(slot) && slots[slot] != nil
    }

    /// Seconds the item on `slot` has cooked by `now`, or nil when the slot is empty.
    func cookedSeconds(onSlot slot: Int, at now: TimeInterval) -> TimeInterval? {
        guard slots.indices.contains(slot), let item = slots[slot] else { return nil }
        return item.cookedBefore + now - item.placedAt
    }

    func doneness(onSlot slot: Int, at now: TimeInterval) -> Doneness? {
        cookedSeconds(onSlot: slot, at: now).map(doneness(afterCooking:))
    }

    /// What the item on `slot` has become by `now`, or nil when the slot is empty.
    func item(onSlot slot: Int, at now: TimeInterval) -> String? {
        guard slots.indices.contains(slot), let recipe = slots[slot]?.recipe else { return nil }
        return doneness(onSlot: slot, at: now)?.item(of: recipe)
    }

    func gauge(onSlot slot: Int, at now: TimeInterval) -> Gauge? {
        cookedSeconds(onSlot: slot, at: now).map(gauge(afterCooking:))
    }

    func gauge(afterCooking seconds: TimeInterval) -> Gauge {
        guard seconds >= cookSec else {
            return Gauge(phase: .baking, fraction: cookSec > 0 ? seconds / cookSec : 1, isAboutToBurn: false)
        }
        guard seconds < burnAt else { return Gauge(phase: .burnt, fraction: 1, isAboutToBurn: false) }
        let sinceDone = seconds - cookSec
        let ruinAfter = burnAt - cookSec
        return Gauge(
            phase: .baked,
            fraction: sinceDone / ruinAfter,
            isAboutToBurn: sinceDone >= ruinAfter - timing.warningSignSec
        )
    }

    func doneness(afterCooking seconds: TimeInterval) -> Doneness {
        switch seconds {
        case burnAt...: .ruined
        case glowAt...: .overcooking
        case cookSec...: .cooked
        default: .cooking
        }
    }

    /// How long `item` has cooked, for putting it on the tool: none if raw,
    /// just done if it comes off nowhere else.
    func cookedBefore(_ item: String, remembered: TimeInterval?) -> TimeInterval {
        recipe(of: item)?.raw == item ? 0 : max(remembered ?? cookSec, cookSec)
    }

    private func recipe(of item: String) -> CookingRecipe? {
        recipes.first { $0.raw == item || $0.cooked == item }
    }

    // MARK: - Commands

    /// Puts `item` on `slot`. Does nothing for an item this tool doesn't cook.
    mutating func place(_ item: String, onSlot slot: Int, at now: TimeInterval, cookedBefore: TimeInterval) {
        guard slots.indices.contains(slot), let recipe = recipe(of: item) else { return }
        slots[slot] = Slot(recipe: recipe, placedAt: now, cookedBefore: cookedBefore)
    }

    mutating func clear(_ slot: Int) {
        guard slots.indices.contains(slot) else { return }
        slots[slot] = nil
    }

    /// The marathon's Second Grill Spot.
    mutating func growSlots(to count: Int) {
        while slots.count < count { slots.append(nil) }
    }
}
