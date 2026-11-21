//
//  MarathonHUD.swift
//  PlayFeat
//  Created by kyky on 19/11/26.
//
//  What a marathon adds over the kitchen HUD, as in the design: the round
//  being played at the top left, a gauge up the right wall filling towards
//  the dishes that bring out the second plate and the second glass, and a
//  plaque at the bottom right crossing off each customer lost (the run ends
//  at three).
//

import SwiftUI

struct MarathonHUD: View {
    let session: MarathonSession

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundBadge(round: session.round)
                .offset(x: 29, y: 35)
            UnlockGauge(
                served: session.dishesServed,
                milestones: [MarathonSession.secondPlateAtDishes, MarathonSession.secondGlassAtDishes]
            )
            .offset(x: 1287, y: 470)
            LostCustomersPlaque(lost: session.day.ordersMissed, allowed: MarathonFlow.lostCustomersToEnd)
                .offset(x: 1054, y: 921)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

/// "ROUND 1" on a white pill.
private struct RoundBadge: View {
    let round: Int

    var body: some View {
        Text("Round \(round)")
            .font(.atkinson(size: 24, weight: .bold))
            .tracking(0.48)
            .textCase(.uppercase)
            .foregroundStyle(Color.purple900)
            .frame(width: 208, height: 64)
            .background(.white, in: Capsule())
    }
}

/// A vertical track filling green with dishes served, an orange tag at each
/// milestone. The top of the track is the last milestone.
private struct UnlockGauge: View {
    let served: Int
    let milestones: [Int]

    private static let trackSize = CGSize(width: 29, height: 268)
    private static let fillInset: CGFloat = 3.5
    private static let tagSize = CGSize(width: 51, height: 34)

    private var top: Int { milestones.max() ?? 1 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule().fill(Color.gaugeTrack)
            Capsule()
                .fill(Color.green500)
                .padding(Self.fillInset)
                .frame(height: Self.trackSize.height * fraction(served))
                .animation(.easeOut(duration: 0.4), value: served)
        }
        .frame(width: Self.trackSize.width, height: Self.trackSize.height)
        .overlay(alignment: .bottom) {
            ForEach(milestones, id: \.self) { milestone in
                tag(milestone)
                    .offset(y: -Self.trackSize.height * fraction(milestone) + Self.tagSize.height / 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Dishes served: \(served)"))
    }

    private func fraction(_ dishes: Int) -> CGFloat {
        CGFloat(min(max(dishes, 0), top)) / CGFloat(max(top, 1))
    }

    private func tag(_ milestone: Int) -> some View {
        Text(milestone, format: .number)
            .font(.atkinson(size: 20, weight: .bold))
            .foregroundStyle(Color.purple900)
            .frame(width: Self.tagSize.width, height: Self.tagSize.height)
            .background(served >= milestone ? Color.green300 : Color.solarOrange, in: Capsule())
    }
}

/// One cross per customer the run may lose: red once lost, grey until then.
private struct LostCustomersPlaque: View {
    let lost: Int
    let allowed: Int

    var body: some View {
        MetalPlate(width: 283) {
            HStack(spacing: 22.6) {
                ForEach(0..<allowed, id: \.self) { index in
                    Image(systemName: "xmark")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(index < lost ? Color.patienceLow : Color.gaugeTrack)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Customers lost: \(lost) of \(allowed)"))
    }
}
