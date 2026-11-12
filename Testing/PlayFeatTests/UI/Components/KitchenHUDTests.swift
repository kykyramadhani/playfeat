//
//  KitchenHUDTests.swift
//  PlayFeatTests
//  Created by kyky on 12/11/26.
//

import Testing
@testable import PlayFeat

struct KitchenHUDTests {

    @Test func theDayClockReadsMinutesAndSecondsRoundedUp() {
        #expect(KitchenHUD.clockText(90) == "01:30")
        #expect(KitchenHUD.clockText(0.4) == "00:01")
        #expect(KitchenHUD.clockText(0) == "00:00")
    }
}
