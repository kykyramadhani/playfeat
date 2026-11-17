//
//  UpgradeCard.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  One shop card: the item, what the upgrade changes (now → next), and the
//  buy button. Maxed out it shows the final value and MAX; locked, the item
//  is a black silhouette with "?" values and N/A.
//
//  The shop screen that lays these out isn't designed yet; the card is ready
//  for it.
//

import SwiftUI

struct UpgradeCard: View {
    let upgrade: ShopUpgrade
    let offer: ShopUpgrade.Offer
    let onBuy: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            art
                .frame(width: 140, height: 118)
                .padding(.top, 43)
            statRow
                .frame(height: 39)
                .padding(.top, 21)
            buyButton
                .padding(.top, 21)
            Spacer(minLength: 0)
        }
        .frame(width: 253, height: 340)
        .background(.white, in: RoundedRectangle(cornerRadius: 22.6))
    }

    @ViewBuilder
    private var art: some View {
        let image = Image(upgrade.image).resizable()
        if offer == .locked {
            image.renderingMode(.template).scaledToFit().foregroundStyle(.black)
        } else {
            image.scaledToFit()
        }
    }

    // MARK: - Stat

    @ViewBuilder
    private var statRow: some View {
        switch offer {
        case .buy(let from, let to, _, _):
            change(from: Text(from, format: .number), to: Text(to, format: .number))
        case .maxed(let value):
            stat(Text(value, format: .number))
        case .locked:
            change(from: Text(verbatim: "?"), to: Text(verbatim: "?"))
        }
    }

    private func change(from: Text, to: Text) -> some View {
        HStack(spacing: 12) {
            stat(from)
            Image("UpgradeArrow")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.nebulaPink)
            stat(to)
        }
    }

    private func stat(_ value: Text) -> some View {
        HStack(spacing: 4) {
            Image(statIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 39, height: 39)
            value
                .font(.atkinson(size: 32, weight: .bold))
                .foregroundStyle(Color.purple900)
        }
    }

    private var statIcon: String {
        switch upgrade.stat {
        case .coins: "CoinsIcon"
        case .seconds: "StopwatchIcon"
        case .count(let icon): icon
        }
    }

    // MARK: - Button

    private var buyButton: some View {
        ClickButton(action: onBuy) {
            buttonLabel
                .font(.atkinson(size: 26.3, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(palette.label)
                .shadow(color: .black.opacity(0.15), radius: 0, y: 1.7)
        }
        .buttonStyle(RaisedButtonStyle(palette: palette, lipHeight: 8.7))
        .frame(width: 157, height: 52.3)
        .shadow(color: .black.opacity(0.25), radius: 0.9, y: 3.5)
        .disabled(!canBuy)
    }

    @ViewBuilder
    private var buttonLabel: some View {
        switch offer {
        case .buy(_, _, let price, let canAfford):
            HStack(spacing: 0) {
                Image(canAfford ? "CoinsIcon" : "CoinsIconDisabled")
                    .resizable()
                    .frame(width: 42.8, height: 42.8)
                Text(price, format: .number)
            }
        case .maxed: Text("Max")
        case .locked: Text(verbatim: "N/A")
        }
    }

    private var canBuy: Bool {
        if case .buy(_, _, _, true) = offer { return true }
        return false
    }

    private var palette: RaisedButtonPalette {
        if case .buy(_, _, _, false) = offer { return .greenDisabled }
        return .green
    }
}

#Preview {
    let tentacle = ShopUpgrade(image: "Tentacle", stat: .coins, values: [7, 14], prices: [210], isUnlocked: true)
    let pot = ShopUpgrade(image: "CookingPot", stat: .seconds, values: [7], prices: [], isUnlocked: true)
    let coral = ShopUpgrade(image: "CoralLettuce", stat: .coins, values: [5, 10], prices: [150], isUnlocked: true)
    return HStack(spacing: 20) {
        UpgradeCard(upgrade: tentacle, offer: tentacle.offer(atLevel: 1, coins: 0), onBuy: {})
        UpgradeCard(upgrade: pot, offer: pot.offer(atLevel: 0, coins: 0), onBuy: {})
        UpgradeCard(upgrade: tentacle, offer: tentacle.offer(atLevel: 0, coins: 100), onBuy: {})
        UpgradeCard(upgrade: coral, offer: .locked, onBuy: {})
        UpgradeCard(upgrade: coral, offer: coral.offer(atLevel: 0, coins: 500), onBuy: {})
    }
    .padding()
    .background(Color.levelPanel)
    .environment(AudioManager())
}
