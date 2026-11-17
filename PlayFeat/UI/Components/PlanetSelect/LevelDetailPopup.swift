//
//  LevelDetailPopup.swift
//  PlayFeat
//  Created by kyky on 11/11/26.
//
//  Opens over the planet board when a level is tapped: the score each star
//  needs, which of them the player already has, and the PLAY button.
//

import SwiftUI

struct LevelDetailPopup: View {
    let level: Level
    let onPlay: () -> Void
    let onShop: () -> Void
    let onClose: () -> Void

    private static let cardSize = CGSize(width: 795, height: 672)
    private static let innerRadius: CGFloat = 39.2

    var body: some View {
        innerCard
            .padding(.top, 41.4)
            .frame(width: Self.cardSize.width, height: Self.cardSize.height, alignment: .top)
            .boardPanelBackground(cornerRadius: Self.innerRadius)
            .overlay { PopupScrews(size: 20.3, inset: 20.3) }
            .overlay(alignment: .topTrailing) { closeButton }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
    }

    /// The lilac face: star targets, the level's name tag, and the buttons.
    private var innerCard: some View {
        VStack(spacing: 0) {
            starTargets
                .padding(.top, 35.6)

            VStack(alignment: .leading, spacing: 46) {
                TabbedValueBox(
                    tab: Text(verbatim: level.planetName),
                    value: Text("Level \(level.number)"),
                    metrics: .level
                )
                actionButtons
            }
        }
        .frame(width: 713.7, height: 586.2, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: Self.innerRadius)
                .fill(
                    Color.purple50
                        .shadow(.inner(color: .black.opacity(0.37), radius: 1.7, y: -3.4))
                        .shadow(.inner(color: .black.opacity(0.39), radius: 1, y: 3.4))
                )
        }
    }

    /// Three big stars, the middle one raised, each over the score it needs.
    private var starTargets: some View {
        HStack(alignment: .top, spacing: 57) {
            ForEach(0..<3, id: \.self) { index in
                starColumn(at: index)
                    .padding(.top, index == 1 ? 0 : 59.2)
            }
        }
    }

    private func starColumn(at index: Int) -> some View {
        VStack(spacing: 0) {
            Image("LevelStar")
                .resizable()
                .frame(width: 115, height: 115)
                .foregroundStyle(index < level.stars ? Color.starYellow : Color.starEmpty)

            // Levels without a data file yet show their stars without targets.
            if level.starTargets.indices.contains(index) {
                Text(level.starTargets[index], format: .number)
                    .font(.atkinson(size: 64, weight: .bold))
                    .foregroundStyle(Color.purple900)
                    .frame(height: 72)
            }
        }
        .frame(width: 115)
    }

    private var actionButtons: some View {
        HStack(spacing: 17) {
            RaisedIconButton(icon: "ShopIcon", label: "Shop", palette: .pink, action: onShop)
                .frame(width: 81, height: 81)
            RaisedTextButton(title: "Play", palette: .start, action: onPlay)
                .frame(width: 208)
                .overlay(alignment: .topTrailing) { energyCost.offset(x: 44.4, y: -20) }
        }
    }

    /// What PLAY costs, in a speech bubble on the button's corner.
    @ViewBuilder
    private var energyCost: some View {
        if let cost = level.energyCost {
            ZStack(alignment: .topLeading) {
                Image("EnergyCostBubble")
                    .resizable()
                    .frame(width: 66, height: 49.2)
                    .offset(y: 7)
                HStack(spacing: 0) {
                    Image("EnergyIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22.3, height: 24)
                    Text(verbatim: "-\(cost)")
                        .font(.atkinson(size: 19.9, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(Color.purple900)
                }
                .offset(x: 13, y: 16)
            }
            .frame(width: 61, height: 56.2, alignment: .topLeading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Costs \(cost) energy"))
        }
    }

    /// Hangs off the card's top-right corner.
    private var closeButton: some View {
        RaisedIconButton(icon: "CloseIcon", label: "Close", palette: .pink, action: onClose)
            .frame(width: 76, height: 76)
            .offset(x: 17, y: -27)
    }
}

extension LevelDetailPopup {
    struct Level {
        let number: Int
        let planetName: String
        let stars: Int
        /// Score needed for 1, 2 and 3 stars; empty when the level has no data yet.
        let starTargets: [Int]
        /// Energy PLAY costs; nil when the level has no data yet.
        var energyCost: Int?
    }
}

#Preview {
    LevelDetailPopup(
        level: .init(number: 1, planetName: "Kepler-186f", stars: 3, starTargets: [20, 40, 60], energyCost: 3),
        onPlay: {}, onShop: {}, onClose: {}
    )
    .environment(AudioManager())
}
