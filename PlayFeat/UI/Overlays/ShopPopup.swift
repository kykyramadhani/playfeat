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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let planet: Planet.ID
    /// Levels finished with a star: each item goes on sale after a set one.
    let clearedLevels: Set<String>
    let onClose: () -> Void

    @State private var tab = KitchenUpgrade.Tab.ingredients
    /// Re-read after every purchase, so the cards show the new levels and prices.
    @State private var coins = GameStorage.coins
    @State private var levels = Self.savedLevels()
    @State private var tutorial = TutorialProgress()

    private static let cardSize = CGSize(width: 253, height: 340)

    var body: some View {
        SunrisePopupOverlay(title: Text("Shop"), onClose: onClose) {
            VStack(spacing: 24) {
                ShopSectionSwitch(selection: $tab)
                if let lesson = shopLesson {
                    hint(for: lesson)
                }
                ScrollViewReader { scroll in
                    ScrollView(.vertical) {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.fixed(Self.cardSize.width), spacing: 24), count: 3),
                            alignment: .leading,
                            spacing: 27
                        ) {
                            ForEach(KitchenShop.upgrades(on: tab, planet: planet)) { item in
                                card(for: item)
                                    .id(item.id)
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.bottom, 21)
                    }
                    .scrollIndicators(.hidden)
                    .task(id: highlightedUpgradeID) {
                        guard let id = highlightedUpgradeID else { return }
                        scroll.scrollTo(id, anchor: .top)
                    }
                }
            }
            .frame(width: 807)
            .padding(.top, 26)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var shopLesson: TutorialProgress.Lesson? {
        let level = planet == .kepler186f ? "1-1" : "2-1"
        guard clearedLevels.contains(level) else { return nil }
        let lesson: TutorialProgress.Lesson
        switch (planet, tab) {
        case (.kepler186f, .ingredients):
            guard highlightedIngredientID != nil else { return nil }
            lesson = .ingredientUpgrade
        case (.kepler186f, .tools): lesson = .extraPlate
        case (.k2332b, .tools): lesson = .extraBowl
        case (.k2332b, .ingredients): return nil
        }
        return tutorial.hasLearned(lesson) ? nil : lesson
    }

    private var highlightedIngredientID: String? {
        let offers = KitchenShop.upgrades(on: .ingredients, planet: planet).compactMap { item -> (String, Int)? in
            guard case .buy(_, _, let price, true) = offer(for: item) else { return nil }
            return (item.id, price)
        }
        return offers.min { $0.1 < $1.1 }?.0
    }

    private var highlightedUpgradeID: String? {
        guard let lesson = shopLesson else { return nil }
        if lesson == .ingredientUpgrade { return highlightedIngredientID }
        let id = KitchenShop.mainStationID(on: planet)
        guard let item = KitchenShop.upgrade(id), case .buy = offer(for: item) else { return nil }
        return id
    }

    private func hint(for lesson: TutorialProgress.Lesson) -> some View {
        let copy: LocalizedStringKey = switch lesson {
        case .extraPlate: "A second plate holds more food while you cook."
        case .extraBowl: "A second bowl lets you prepare two orders at once."
        default: "Upgrade an ingredient to earn more per dish."
        }
        return HStack {
            Text(copy)
                .font(.atkinson(size: 22, weight: .bold))
            Spacer()
            ClickButton(action: { tutorial.learn(lesson) }) {
                Text("Skip")
                    .font(.atkinson(size: 21, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.purple900)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(Color.green100, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Cards

    private func offer(for item: KitchenUpgrade) -> ShopUpgrade.Offer {
        item.upgrade(isUnlocked: item.isUnlocked(clearedLevels: clearedLevels))
            .offer(atLevel: levels[item.id] ?? 0, coins: coins)
    }

    private func card(for item: KitchenUpgrade) -> some View {
        let upgrade = item.upgrade(isUnlocked: item.isUnlocked(clearedLevels: clearedLevels))
        let offer = offer(for: item)
        return UpgradeCard(upgrade: upgrade, offer: offer) { buy(item, offer: offer) }
            .overlay {
                if item.id == highlightedUpgradeID {
                    TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { timeline in
                        let pulse = 0.75 + 0.25 * cos(timeline.date.timeIntervalSinceReferenceDate * 5)
                        RoundedRectangle(cornerRadius: 22.6)
                            .strokeBorder(Color.green500, lineWidth: 5)
                            .opacity(reduceMotion ? 1 : pulse)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
    }

    private func buy(_ item: KitchenUpgrade, offer: ShopUpgrade.Offer) {
        guard case .buy(_, _, let price, true) = offer else { return }
        do {
            try GameStorage.buyUpgrade(item.id, price: price)
            if let lesson = shopLesson,
               lesson == .ingredientUpgrade || item.id == KitchenShop.mainStationID(on: planet) {
                tutorial.learn(lesson)
            }
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
