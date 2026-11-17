//
//  Grill.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  The kitchen grill, as in the prototype. A raw flatbread bakes in
//  `bakeSec`; once baked it keeps cooking, starts glowing as a warning
//  after a while and then burns. A baked flatbread can be put back on and
//  carries on from where it was. Putting a flatbread on a taken slot
//  replaces what was there. One slot to start; the marathon can add a
//  second. Timed in play time, so a pause stops cooking.
//

import Foundation

nonisolated struct Grill: Equatable {
    /// How far a flatbread on the grill has cooked.
    enum Doneness: Equatable {
        /// Still raw.
        case cooking
        /// Baked and ready to take off.
        case cooked
        /// Still baked, but glowing: about to burn.
        case overcooking
        /// Burnt, and no use for any dish.
        case burnt

        /// What the flatbread is by now.
        var item: String {
            switch self {
            case .cooking: KitchenMenu.rawFlatbread
            case .cooked, .overcooking: KitchenMenu.bakedFlatbread
            case .burnt: KitchenMenu.burntFlatbread
            }
        }

        var needsWarning: Bool { self == .overcooking }
    }

    /// A flatbread on a slot: when it went on, and how long it had cooked before.
    struct Slot: Equatable {
        let placedAt: TimeInterval
        let cookedBefore: TimeInterval
    }

    /// What the ring around a flatbread on the grill shows, as in the
    /// prototype: filling yellow while it bakes, then red towards burning,
    /// all black once burnt; and the warning sign just before it burns.
    struct Gauge: Equatable {
        enum Phase: Equatable { case baking, baked, burnt }

        let phase: Phase
        /// How much of the ring is filled, 0...1.
        let fraction: Double
        let isAboutToBurn: Bool
    }

    // MARK: - Tuning

    /// Seconds to bake; the marathon's Faster Grill cards shorten it.
    var bakeSec: TimeInterval
    /// Stretches the time before glowing and burning (a level's
    /// `burnTimeMultiplier`).
    let burnMultiplier: Double

    var glowAt: TimeInterval { bakeSec + KitchenRules.glowAfterBakedSec * burnMultiplier }
    var burnAt: TimeInterval { bakeSec + KitchenRules.burnAfterBakedSec * burnMultiplier }

    // MARK: - State

    private(set) var slots: [Slot?]

    init(bakeSec: TimeInterval = KitchenRules.bakeSec, burnMultiplier: Double = 1, slotCount: Int = 1) {
        self.bakeSec = bakeSec
        self.burnMultiplier = burnMultiplier
        slots = Array(repeating: nil, count: max(slotCount, 1))
    }

    /// A raw or baked flatbread, on any slot: a taken one swaps its flatbread out.
    func accepts(_ item: String) -> Bool {
        item == KitchenMenu.rawFlatbread || item == KitchenMenu.bakedFlatbread
    }

    func isTaken(_ slot: Int) -> Bool {
        slots.indices.contains(slot) && slots[slot] != nil
    }

    /// Seconds the flatbread on `slot` has cooked by `now`, or nil when the slot is empty.
    func cookedSeconds(onSlot slot: Int, at now: TimeInterval) -> TimeInterval? {
        guard slots.indices.contains(slot), let flatbread = slots[slot] else { return nil }
        return flatbread.cookedBefore + now - flatbread.placedAt
    }

    func doneness(onSlot slot: Int, at now: TimeInterval) -> Doneness? {
        cookedSeconds(onSlot: slot, at: now).map(doneness(afterCooking:))
    }

    func gauge(onSlot slot: Int, at now: TimeInterval) -> Gauge? {
        cookedSeconds(onSlot: slot, at: now).map(gauge(afterCooking:))
    }

    func gauge(afterCooking seconds: TimeInterval) -> Gauge {
        guard seconds >= bakeSec else {
            return Gauge(phase: .baking, fraction: bakeSec > 0 ? seconds / bakeSec : 1, isAboutToBurn: false)
        }
        guard seconds < burnAt else { return Gauge(phase: .burnt, fraction: 1, isAboutToBurn: false) }
        let sinceBaked = seconds - bakeSec
        let burnAfter = burnAt - bakeSec
        return Gauge(
            phase: .baked,
            fraction: sinceBaked / burnAfter,
            isAboutToBurn: sinceBaked >= burnAfter - KitchenRules.burnWarningSec
        )
    }

    func doneness(afterCooking seconds: TimeInterval) -> Doneness {
        switch seconds {
        case burnAt...: .burnt
        case glowAt...: .overcooking
        case bakeSec...: .cooked
        default: .cooking
        }
    }

    /// How long a flatbread that is `item` has cooked, for putting it on the
    /// grill: none if raw, just baked if it comes off nowhere else.
    func cookedBefore(_ item: String, remembered: TimeInterval?) -> TimeInterval {
        item == KitchenMenu.rawFlatbread ? 0 : max(remembered ?? bakeSec, bakeSec)
    }

    // MARK: - Commands

    mutating func place(onSlot slot: Int, at now: TimeInterval, cookedBefore: TimeInterval) {
        guard slots.indices.contains(slot) else { return }
        slots[slot] = Slot(placedAt: now, cookedBefore: cookedBefore)
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
