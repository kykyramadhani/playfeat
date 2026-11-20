//
//  MarathonHUD.swift
//  PlayFeat
//  Created by Owen Limantoro on 20/11/26.
//
//  What a marathon adds to the kitchen HUD: the round at the top left, the
//  dishes served toward the next plate or glass up the right side, and the
//  customers lost at the bottom right. Placed on the design canvas as
//  Figma "Sunrise (PlayFeat)" 1964:681 draws them.
//

import SwiftUI

struct MarathonHUD: View {
    let session: MarathonSession

    // Measured on the 1366×1024 Figma frame, from the screen edges each
    // piece sticks to. A wider screen (a MacBook, an 11" iPad) widens the
    // design canvas, so the right-hand pieces are kept off the right edge
    // rather than placed from the left, or they'd drift into the kitchen.
    private static let roundBadgeInsets = EdgeInsets(top: 35, leading: 29, bottom: 0, trailing: 0)
    private static let progressBarInsets = EdgeInsets(top: 487, leading: 0, bottom: 0, trailing: 47)
    private static let lostCustomersInsets = EdgeInsets(top: 921, leading: 0, bottom: 0, trailing: 31.11)

    var body: some View {
        ZStack {
            RoundBadge(round: session.round)
                .pinned(to: .topLeading, insets: Self.roundBadgeInsets)
            BuffetProgressBar(progress: session.stationProgress)
                .pinned(to: .topTrailing, insets: Self.progressBarInsets)
            LostCustomersPlaque(lost: session.lostCustomers, allowed: MarathonFlow.lostCustomersToEnd)
                .pinned(to: .topTrailing, insets: Self.lostCustomersInsets)
        }
    }
}

/// "ROUND 1" on a white pill.
private struct RoundBadge: View {
    let round: Int

    private static let size = CGSize(width: 208, height: 64)

    var body: some View {
        Text("Round \(round)")
            .textCase(.uppercase)
            .font(.atkinson(size: 24, weight: .bold))
            .tracking(0.48)
            .foregroundStyle(Color.purple900)
            .frame(width: Self.size.width, height: Self.size.height)
            .background(Capsule().fill(Color.white))
    }
}

private extension View {
    /// Keeps this view `insets` in from the canvas edges at `alignment`.
    func pinned(to alignment: Alignment, insets: EdgeInsets) -> some View {
        padding(insets)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

#Preview {
    MarathonHUD(session: MarathonSession(planet: .kepler186f, positionTypes: KitchenLayout.positionTypes))
        .background(Color.gray)
        .designScaled()
}
