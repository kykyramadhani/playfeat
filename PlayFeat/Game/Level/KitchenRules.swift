//
//  KitchenRules.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  The kitchen's shared numbers, as set in the playtest prototype's common
//  config (github.com/yosephadi/PlayFeat-Playtest). One place to retune them.
//

import Foundation

nonisolated enum KitchenRules {
    /// Taken off the score, never below zero, for every customer who leaves.
    static let lostCustomerPenalty = 10

    /// Seconds a raw flatbread takes to bake.
    static let bakeSec: TimeInterval = 6
    /// After baking: when the flatbread starts glowing as a warning, and
    /// when it burns. Both are stretched by a level's burn multiplier.
    static let glowAfterBakedSec: TimeInterval = 8
    static let burnAfterBakedSec: TimeInterval = 12
    /// The warning sign goes up this long before a flatbread burns.
    static let burnWarningSec: TimeInterval = 3

    /// A refused item hangs where it was let go this long, then falls.
    static let refuseHoldSec: TimeInterval = 0.3

    /// How long a served dish takes to be drawn into the alien and vanish.
    /// The customer stays until it is gone; then their order sheet vanishes,
    /// and a beat later they leave.
    static let handOverSec: TimeInterval = 1.1
    static let pauseBeforeLeavingSec: TimeInterval = 0.2

    /// A bubble something still needs comes at least this often.
    static let maxUsefulWaitSec: TimeInterval = 6

    /// Story tips, by how much patience the customer had left.
    enum PatienceZone {
        case green, yellow, red

        static let greenAbove = 0.5
        static let redBelow = 0.2

        init(patienceLeft fraction: Double) {
            self = fraction > Self.greenAbove ? .green : fraction >= Self.redBelow ? .yellow : .red
        }

        var tip: Int {
            switch self {
            case .green: 5
            case .yellow: 2
            case .red: 0
            }
        }
    }

    /// An angry alien's story tip counts double.
    static let angryTipMultiplier = 2
}
