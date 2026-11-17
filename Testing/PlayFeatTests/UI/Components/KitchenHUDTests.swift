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
        #expect(KitchenHUD.clockText(60) == "01:00")
    }

    /// Under a minute the clock drops the minutes and shows two digits.
    @Test func underAMinuteOnlyTheSecondsShow() {
        #expect(KitchenHUD.clockText(58.4) == "59")
        #expect(KitchenHUD.clockText(0.4) == "01")
        #expect(KitchenHUD.clockText(0) == "00")
    }
}
