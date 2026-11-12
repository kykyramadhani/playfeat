//
//  KitchenHUD.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  The kitchen's top-left counters: time left in the day, coins and tips.
//

import SwiftUI

struct KitchenHUD: View {
    let day: KitchenDay

    var body: some View {
        // TODO: coins and tips stay at 0 until serving a customer pays them.
        HStack(spacing: 22) {
            HUDCounter(icon: "StopwatchIcon", label: "Time Left", value: Self.clockText(day.timeLeft))
            HUDCounter(icon: "CoinsIcon", label: "Coins", value: "0")
            HUDCounter(icon: "TipsIcon", label: "Tips", value: "0")
        }
        .padding(.leading, 29)
        .padding(.top, 31)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// "01:30" — whole seconds, rounded up so the clock reads 00:00 only at the end.
    static func clockText(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds.rounded(.up))
            .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }
}
