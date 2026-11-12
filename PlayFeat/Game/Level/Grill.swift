//
//  Grill.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  The kitchen grill: cooks one raw flatbread at a time. It bakes after a few
//  seconds, starts to overcook (the scene warns the player with a glow) and
//  then burns if it is left on. Timed in play time, so a pause stops cooking.
//

import Foundation

nonisolated struct Grill: Equatable {
    /// How far a flatbread on the grill has cooked.
    enum Doneness: Equatable {
        /// Still raw.
        case cooking
        /// Baked and ready to take off.
        case cooked
        /// Still baked, but about to burn: the player is warned.
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

    // MARK: - Tuning

    static let cookTime: TimeInterval = 6
    static let warningTime: TimeInterval = 8
    static let burnTime: TimeInterval = 12

    // MARK: - State

    /// Play time the flatbread now on the grill was put there, if any.
    private(set) var placedAt: TimeInterval?

    var isEmpty: Bool { placedAt == nil }

    /// Only a raw flatbread, and only while the grill is free.
    func accepts(_ item: String) -> Bool {
        isEmpty && item == KitchenMenu.rawFlatbread
    }

    /// How done the flatbread on the grill is at play time `now`, or nil
    /// when the grill is empty.
    func doneness(at now: TimeInterval) -> Doneness? {
        placedAt.map { Self.doneness(after: now - $0) }
    }

    static func doneness(after secondsOnGrill: TimeInterval) -> Doneness {
        switch secondsOnGrill {
        case burnTime...: .burnt
        case warningTime...: .overcooking
        case cookTime...: .cooked
        default: .cooking
        }
    }

    // MARK: - Commands

    mutating func place(at now: TimeInterval) {
        placedAt = now
    }

    mutating func clear() {
        placedAt = nil
    }
}
