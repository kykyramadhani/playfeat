//
//  KitchenHUD.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  The kitchen's counters as two metal plaques side by side on the
//  counter's front: time left (in the day, or the marathon round), and the
//  points with the tips beside them. In a marathon the second plaque counts
//  marathon coins under the marathon coin, with the last tip beside them.
//

import SwiftUI

struct KitchenHUD: View {
    let day: KitchenDay
    /// Marathon coins to spend, in a marathon; nil on a level.
    var marathonCoins: Int?

    var body: some View {
        HStack(spacing: 0) { plaques }
            .padding(.leading, 10)
            .padding(.top, 911)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var plaques: some View {
        Group {
            HUDPlaque(iconDrop: -4, plaqueDrop: 15) {
                Image("StopwatchIcon").resizable()
            } value: {
                Text(verbatim: Self.clockText(day.timeLeft))
                    .font(.atkinson(size: 32, weight: .bold))
            }
            .accessibilityLabel(Text("Time Left"))

            HUDPlaque(iconDrop: 0, plaqueDrop: 14) {
                coinIcon
            } value: {
                coins
            }
            .accessibilityLabel(marathonCoins == nil ? Text("Coins") : Text("Marathon Coins"))
        }
        .tracking(0.64)
        .foregroundStyle(Color.purple900)
    }

    @ViewBuilder
    private var coinIcon: some View {
        if marathonCoins == nil {
            Image("HUDCoinsIcon").resizable().frame(width: 73, height: 69)
        } else {
            Image("CoinsIcon").resizable()
        }
    }

    /// "150 +12": the points (or marathon coins) with the tips (or the last
    /// tip) in small type after them.
    private var coins: some View {
        HStack(spacing: 0) {
            Text(marathonCoins ?? day.points, format: .number)
                .font(.atkinson(size: 32, weight: .bold))
                .fixedSize()
                .frame(minWidth: 59)
            Text(verbatim: "+\(marathonCoins == nil ? day.tips : day.lastTip)")
                .font(.atkinson(size: 16, weight: .bold))
                .fixedSize()
                .frame(minWidth: 41, alignment: .leading)
        }
        // Marathon coins run to three or four digits; the card holds them.
        .minimumScaleFactor(0.7)
        .frame(minWidth: 98)
    }

    /// "01:30" while a minute or more is left, then just the seconds: "59"
    /// down to "00". Whole seconds, rounded up, so it reads 00 only at the end.
    static func clockText(_ seconds: TimeInterval) -> String {
        let wholeSeconds = Int(max(seconds, 0).rounded(.up))
        guard wholeSeconds >= 60 else { return String(format: "%02d", wholeSeconds) }
        return Duration.seconds(wholeSeconds).formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }
}

/// One plaque: a screwed-on metal plate holding a white card with the
/// value, and its icon overlapping the plate's left end. Sized 234×92 as in
/// the design.
private struct HUDPlaque<Icon: View, Value: View>: View {
    /// How far the icon and the plate sit below the block's top; the
    /// stopwatch's knob pokes up, so it sits a little higher.
    let iconDrop: CGFloat
    let plaqueDrop: CGFloat
    @ViewBuilder let icon: Icon
    @ViewBuilder let value: Value

    var body: some View {
        ZStack(alignment: .topLeading) {
            MetalPlate(width: 181) { value }
                .offset(x: 46, y: plaqueDrop)
            icon
                .frame(width: 92, height: 92)
                .offset(y: iconDrop)
        }
        .frame(width: 234, height: 92, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let level = try? LevelLoader.load("1-1")
    return Group {
        if let level {
            KitchenHUD(day: KitchenDay(
                storyLevel: level, openSeats: KitchenLayout.openSeats(on: level),
                tools: KitchenTools(plates: 1, glasses: 0)
            ))
            .background(Color.gray)
            .designScaled()
        }
    }
}
