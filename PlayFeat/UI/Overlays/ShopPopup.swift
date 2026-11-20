//
//  ShopPopup.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  A planet's kitchen shop over its level board: an INGREDIENTS | TOOLS
//  switch over a scrolling grid of that section's upgrade cards. Buying spends coins at once and
//  is saved; the next kitchen day uses the upgrade.
//

import SwiftUI

struct ShopPopup: View {
    let planet: Planet.ID
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
                ShopSectionSwitch(selection: $tab)
                ScrollView(.vertical) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.fixed(Self.cardSize.width), spacing: 24), count: 3),
                        alignment: .leading,
                        spacing: 27
                    ) {
                        ForEach(KitchenShop.upgrades(on: tab, planet: planet)) { item in
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

/// The joined INGREDIENTS | TOOLS switch: one cream, white-rimmed box with
/// a magenta pill that slides under whichever section is chosen.
private struct ShopSectionSwitch: View {
    @Binding var selection: KitchenUpgrade.Tab

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let size = CGSize(width: 807, height: 78)
    private static let pillSize = CGSize(width: 374, height: 65)
    /// The pill's top-left corner over each section, from the Figma frame.
    private static let pillTop: CGFloat = 4.26
    private static let ingredientsPillX: CGFloat = 4.26
    private static let toolsPillX: CGFloat = 422.26
    private static let slide: Animation = .spring(duration: 0.3, bounce: 0.15)
    private static let rim = RoundedRectangle(cornerRadius: 28.76)

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22.85)
                .fill(Color.levelPanel)
                .frame(width: Self.pillSize.width, height: Self.pillSize.height)
                .offset(x: Self.pillX(under: selection), y: Self.pillTop)
            sectionButton(.ingredients, title: Text("Ingredients"))
            sectionButton(.tools, title: Text("Tools"))
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .background {
            Self.rim.fill(Color.neutralElevated).paperTexture(clippedTo: Self.rim)
        }
        .overlay(Self.rim.strokeBorder(.white.opacity(0.5), lineWidth: 1.7))
        .compositingGroup()
        .shadow(color: .black.opacity(0.2), radius: 0, y: 1.9)
        .animation(reduceMotion ? nil : Self.slide, value: selection)
    }

    private func sectionButton(_ section: KitchenUpgrade.Tab, title: Text) -> some View {
        let isSelected = selection == section
        return ClickButton(action: { selection = section }) {
            title
                .font(.atkinson(size: 32, weight: .bold))
                .tracking(0.64)
                .textCase(.uppercase)
                .foregroundStyle(isSelected ? Color.white : Color.shopTabIdleText)
                .frame(width: Self.pillSize.width, height: Self.pillSize.height)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(x: Self.pillX(under: section), y: Self.pillTop)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private static func pillX(under section: KitchenUpgrade.Tab) -> CGFloat {
        switch section {
        case .ingredients: ingredientsPillX
        case .tools: toolsPillX
        }
    }
}

#Preview("Kepler-186f, nothing cleared") {
    ShopPopup(planet: .kepler186f, clearedLevels: [], onClose: {})
        .environment(AudioManager())
}

#Preview("K2-332 b, every level cleared") {
    ShopPopup(planet: .k2332b, clearedLevels: Set(Planet.k2332b.levelIDs), onClose: {})
        .environment(AudioManager())
}
