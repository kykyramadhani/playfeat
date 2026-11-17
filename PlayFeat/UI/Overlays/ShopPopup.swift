//
//  ShopPopup.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  The kitchen shop over the level board: an INGREDIENTS and a TOOLS tab,
//  each a scrolling grid of upgrade cards. Buying spends coins at once and
//  is saved; the next kitchen day uses the upgrade.
//

import SwiftUI

struct ShopPopup: View {
    /// Levels finished with a star: each item goes on sale after a set one.
    let clearedLevels: Set<String>
    let onClose: () -> Void

    @State private var tab = KitchenUpgrade.Tab.ingredients
    /// Re-read after every purchase, so the cards show the new levels and prices.
    @State private var coins = GameStorage.coins
    @State private var levels = Self.savedLevels()

    private static let cardSize = CGSize(width: 253, height: 340)

    var body: some View {
        SunrisePopupOverlay(title: Text("Shop"), onClose: onClose) {
            VStack(spacing: 24) {
                tabs
                ScrollView(.vertical) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.fixed(Self.cardSize.width), spacing: 24), count: 3),
                        alignment: .leading,
                        spacing: 27
                    ) {
                        ForEach(KitchenShop.upgrades(on: tab)) { item in
                            card(for: item)
                        }
                    }
                    .padding(.bottom, 26)
                }
                .scrollIndicators(.hidden)
            }
            .frame(width: 807)
            .padding(.top, 26)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: - Tabs

    private var tabs: some View {
        HStack(spacing: 13) {
            ShopTab(title: Text("Ingredients"), isSelected: tab == .ingredients) { tab = .ingredients }
                .frame(width: 390)
            ShopTab(title: Text("Tools"), isSelected: tab == .tools) { tab = .tools }
                .frame(width: 404)
        }
    }

    // MARK: - Cards

    private func card(for item: KitchenUpgrade) -> some View {
        let isUnlocked = item.isUnlocked(clearedLevels: clearedLevels)
        let upgrade = item.upgrade(isUnlocked: isUnlocked)
        let offer = upgrade.offer(atLevel: levels[item.id] ?? 0, coins: coins)
        return UpgradeCard(upgrade: upgrade, offer: offer) { buy(item, offer: offer) }
    }

    private func buy(_ item: KitchenUpgrade, offer: ShopUpgrade.Offer) {
        guard case .buy(_, _, let price, true) = offer else { return }
        do {
            try GameStorage.buyUpgrade(item.id, price: price)
        } catch {
            // The button is only live when the coins cover the price, so
            // this means the purse changed elsewhere; show the real count.
        }
        coins = GameStorage.coins
        levels = Self.savedLevels()
    }

    private static func savedLevels() -> [String: Int] {
        Dictionary(uniqueKeysWithValues: KitchenShop.upgrades.map { ($0.id, GameStorage.upgradeLevel($0.id)) })
    }
}

/// One tab: a cream, white-rimmed box around a magenta pill when selected,
/// a faded pink one when not.
private struct ShopTab: View {
    let title: Text
    let isSelected: Bool
    let action: () -> Void

    private static let rim = RoundedRectangle(cornerRadius: 28.76)

    var body: some View {
        ClickButton(action: action) {
            RoundedRectangle(cornerRadius: 22.85)
                .fill(isSelected ? Color.levelPanel : Color.shopTabIdle)
                .padding(.leading, 6.26)
                .padding(.trailing, 9.74)
                .padding(.top, 4.26)
                .padding(.bottom, 8.74)
                .overlay {
                    title
                        .font(.atkinson(size: 32, weight: .bold))
                        .tracking(0.64)
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                }
                .frame(height: 78)
                .background {
                    Self.rim.fill(Color.neutralElevated).paperTexture(clippedTo: Self.rim)
                }
                .overlay(Self.rim.strokeBorder(.white.opacity(0.5), lineWidth: 1.7))
                .compositingGroup()
                .shadow(color: .black.opacity(0.2), radius: 0, y: 1.9)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ShopPopup(clearedLevels: [], onClose: {})
        .environment(AudioManager())
}
