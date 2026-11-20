//
//  BuffetProgressBar.swift
//  PlayFeat
//  Created by Owen Limantoro on 20/11/26.
//
//  The marathon's upright bar of dishes served, filling toward the last
//  extra plate or glass, with a tag at each count that brings one out.
//  Sized as Figma "Sunrise (PlayFeat)" 1964:681 draws it.
//

import SwiftUI

struct BuffetProgressBar: View {
    let progress: StationUnlockProgress

    static let trackSize = CGSize(width: 29, height: 268)
    private static let fillWidth: CGFloat = 21.86
    /// The fill's gap to the track's ends.
    private static let fillInset: CGFloat = 4
    private static let tagSize = CGSize(width: 51, height: 34)

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(Color.buffetProgressTrack)
            Capsule()
                .fill(Color.green500)
                .frame(width: Self.fillWidth, height: fillHeight)
                .padding(.bottom, Self.fillInset)
                .animation(.easeOut(duration: 0.4), value: progress.dishesServed)
        }
        .frame(width: Self.trackSize.width, height: Self.trackSize.height)
        .overlay(alignment: .bottom) { unlockTags }
        .accessibilityElement()
        .accessibilityLabel(Text("Dishes Served"))
        .accessibilityValue(Text("\(progress.dishesServed) of \(progress.goal)"))
    }

    private var fillHeight: CGFloat {
        (Self.trackSize.height - 2 * Self.fillInset) * progress.filledShare
    }

    /// Each tag is centred where the fill's top reaches once that many
    /// dishes are served; the last one sits on the track's top end.
    private var unlockTags: some View {
        ZStack(alignment: .bottom) {
            ForEach(progress.unlocks, id: \.self) { dishes in
                UnlockTag(dishes: dishes)
                    .frame(width: Self.tagSize.width, height: Self.tagSize.height)
                    .offset(y: Self.tagSize.height / 2 - Self.trackSize.height * progress.share(at: dishes))
            }
        }
        .accessibilityHidden(true)
    }
}

/// An orange tag with the dishes count that brings out a plate or glass.
private struct UnlockTag: View {
    let dishes: Int

    var body: some View {
        Text(verbatim: "\(dishes)")
            .font(.atkinson(size: 20, weight: .bold))
            .foregroundStyle(Color.purple900)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Capsule().fill(Color.solarOrange))
    }
}

#Preview {
    HStack(spacing: 80) {
        BuffetProgressBar(progress: StationUnlockProgress(dishesServed: 3, unlocks: [6, 14]))
        BuffetProgressBar(progress: StationUnlockProgress(dishesServed: 11, unlocks: [6, 14]))
        BuffetProgressBar(progress: StationUnlockProgress(dishesServed: 4, unlocks: [6]))
    }
    .padding(60)
    .background(Color.gray)
}
