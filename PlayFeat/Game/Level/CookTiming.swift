//
//  CookTiming.swift
//  PlayFeat
//  Created by Owen Limantoro on 18/11/26.
//
//  How long a planet's tools take: to cook an item, then, once it is done,
//  to start warning and to ruin it. Planet 2 ruins food sooner than Planet 1,
//  so the numbers belong to the planet, not to the tool.
//

import Foundation

nonisolated struct CookTiming: Equatable {
    /// Seconds from raw to done.
    let cookSec: TimeInterval
    /// After done: when the item starts glowing as a warning.
    let warnAfterDoneSec: TimeInterval
    /// After done: when the item is ruined (burnt, mushy).
    let ruinAfterDoneSec: TimeInterval
    /// The warning sign goes up this long before the item is ruined.
    let warningSignSec: TimeInterval

    /// Kepler-186f, as in the prototype: done at 6 s, glowing 8 s later,
    /// burnt 12 s later.
    static let keplerKitchen = CookTiming(cookSec: 6, warnAfterDoneSec: 8, ruinAfterDoneSec: 12, warningSignSec: 3)
    /// K2-332 b: as on Planet 1, but ruined 10 s after done (Adi, 18 Nov).
    static let underwaterKitchen = CookTiming(cookSec: 6, warnAfterDoneSec: 6, ruinAfterDoneSec: 10, warningSignSec: 3)
}
