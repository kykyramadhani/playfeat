//
//  RecipeBookView.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  The recipe book, opened from the planet board: a pink page on the left
//  for the chosen recipe — its name, picture, description and how to cook
//  it, or for an ingredient the dishes it goes in — and a scrolling grid of
//  every recipe and ingredient on the right. A recipe stays a shadow of
//  its dish until the kitchen has introduced it; before any is unlocked,
//  the page says to go and play. Ingredients the player has upgraded are drawn premium.
//

import SwiftUI

struct RecipeBookView: View {
    /// The planet's pages, dishes first.
    private let entries: [RecipeBookEntry]
    private let seenIntroductions: Set<String>
    private let upgraded: Set<String>
    private let onClose: () -> Void

    /// The open page; nil until the first recipe is unlocked.
    @State private var selected: RecipeBookEntry?

    init(
        planet: Planet.ID,
        seenIntroductions: Set<String> = GameStorage.seenIntroductions,
        upgraded: Set<String> = GameStorage.dishPricing.upgradedIngredients,
        onClose: @escaping () -> Void
    ) {
        entries = RecipeBook.entries(on: planet)
        self.seenIntroductions = seenIntroductions
        self.upgraded = upgraded
        self.onClose = onClose
        _selected = State(initialValue: entries.first { $0.isUnlocked(afterSeeing: seenIntroductions) })
    }

    var body: some View {
        SunrisePopupOverlay(title: Text("Recipe"), onClose: onClose) {
            HStack(alignment: .top) {
                page
                Spacer(minLength: 0)
                tiles
            }
            .frame(width: 825)
            .padding(.leading, 33.85)
            .padding(.top, 34)
        }
    }

    @ViewBuilder
    private var page: some View {
        if let selected {
            RecipePage(entry: selected, upgraded: upgraded)
        } else {
            NoRecipesPage()
        }
    }

    /// Each recipe keeps its place in the grid, locked until it's unlocked.
    private var tiles: some View {
        ScrollView(.vertical) {
            tileGrid
        }
        .frame(width: 343, height: RecipePage.height)
    }

    private var tileGrid: some View {
        LazyVGrid(columns: [GridItem(.fixed(165), spacing: 13), GridItem(.fixed(165))], spacing: 13.3) {
            ForEach(entries) { entry in
                if entry.isUnlocked(afterSeeing: seenIntroductions) {
                    ClickButton(action: { selected = entry }) {
                        RecipeTile(entry: entry, upgraded: upgraded, isSelected: entry == selected)
                    }
                    .buttonStyle(.plain)
                } else {
                    LockedRecipeTile(item: entry.item)
                }
            }
        }
    }

}

// MARK: - Page

/// The chosen recipe, on the book's pink page.
private struct RecipePage: View {
    let entry: RecipeBookEntry
    let upgraded: Set<String>

    static let width: CGFloat = 465
    /// As tall as the page with a recipe on it, so the book keeps its size.
    static let height: CGFloat = 577

    var body: some View {
        VStack(spacing: 5) {
            Text(entry.name)
                .font(.atkinson(size: 32, weight: .bold))
                .tracking(0.64)
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .frame(height: 46)
            KitchenItemArt(item: entry.item, upgraded: upgraded)
                .frame(width: 178, height: 160)
            InfoBox(tab: Text("Description")) {
                Text(entry.description)
                    .font(.atkinson(size: 14.7, weight: .bold))
                    .foregroundStyle(Color.purple900)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
            }
            if entry.isIngredient {
                InfoBox(tab: Text("Used In")) { usedIn }
            } else {
                InfoBox(tab: Text("How to Cook")) { howToCook }
            }
        }
        .padding(.horizontal, 29)
        .padding(.vertical, 25)
        .frame(width: Self.width)
        .background(Color.nebulaPink, in: RoundedRectangle(cornerRadius: 16))
    }

    /// "A + B = result", in pictures.
    private var howToCook: some View {
        HStack(spacing: 18) {
            term(entry.madeFrom[0])
            sign("PlusSign", size: 23.6)
            term(entry.madeFrom[1])
            sign("EqualsSign", size: 33.6)
            KitchenItemArt(item: entry.item, upgraded: upgraded).frame(width: 51, height: 51)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(entry.name))
    }

    /// The dishes this ingredient goes in, in pictures.
    private var usedIn: some View {
        HStack(spacing: 24) {
            ForEach(RecipeBook.dishes(using: entry.item)) { dish in
                KitchenItemArt(item: dish.item, upgraded: upgraded)
                    .frame(width: 70, height: 70)
                    .accessibilityElement()
                    .accessibilityLabel(Text(dish.name))
            }
        }
    }

    @ViewBuilder
    private func term(_ term: RecipeBookEntry.Term) -> some View {
        switch term {
        case .item(let item):
            KitchenItemArt(item: item, upgraded: upgraded).frame(width: 51, height: 51)
        case .tool(let image):
            Image(image).resizable().scaledToFit().frame(width: 59, height: 51)
        }
    }

    private func sign(_ image: String, size: CGFloat) -> some View {
        Image(image)
            .resizable()
            .frame(width: size, height: size)
            .foregroundStyle(.black)
    }
}

/// The page before any recipe is unlocked: a locked picture and a nudge to
/// go and cook.
private struct NoRecipesPage: View {
    var body: some View {
        VStack(spacing: 30) {
            BigQuestionMark(size: 160)
                .foregroundStyle(.white)
            Text("Play a level to discover new recipes!")
                .font(.atkinson(size: 32, weight: .bold))
                .tracking(0.64)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 29)
        .frame(width: RecipePage.width, height: RecipePage.height)
        .background(Color.nebulaPink, in: RoundedRectangle(cornerRadius: 16))
    }
}

/// A cream box with a small blue tab naming it.
private struct InfoBox<Content: View>: View {
    let tab: Text
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tab
                .font(.atkinson(size: 14.8, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .frame(width: 157, height: 34)
                .background(Color.cosmicBlue, in: UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34))
                .padding(.leading, 25)
            content
                .frame(width: 370, height: 103)
                .background(Color.neutralElevated, in: RoundedRectangle(cornerRadius: 27.2))
                .overlay(RoundedRectangle(cornerRadius: 27.2).strokeBorder(.white.opacity(0.5), lineWidth: 1.6))
                .shadow(color: .black.opacity(0.2), radius: 0, y: 1.8)
        }
        .padding(.top, 16)
    }
}

// MARK: - Tiles

private struct RecipeTile: View {
    let entry: RecipeBookEntry
    let upgraded: Set<String>
    let isSelected: Bool

    var body: some View {
        KitchenItemArt(item: entry.item, upgraded: upgraded)
            .frame(width: 116, height: 104)
            .frame(width: 165, height: 184)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20).strokeBorder(Color.nebulaPink, lineWidth: 5)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(entry.name))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A recipe not unlocked yet: its dish as a black shadow under a question
/// mark.
private struct LockedRecipeTile: View {
    /// The dish this tile will show once unlocked.
    let item: String

    var body: some View {
        KitchenItemArt(item: item)
            .colorMultiply(.black)
            .overlay {
                BigQuestionMark(size: 32).foregroundStyle(.white)
            }
            .frame(width: 116, height: 104)
            .frame(width: 165, height: 184)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Locked"))
    }
}

private struct BigQuestionMark: View {
    let size: CGFloat

    var body: some View {
        Text(verbatim: "?")
            .font(.atkinson(size: size, weight: .bold))
            .accessibilityHidden(true)
    }
}

#Preview("Level 1 played, pepper upgraded") {
    RecipeBookView(
        planet: .kepler186f,
        seenIntroductions: Set(KitchenIntroduction.introduced(byLevel: "1-1").map(\.id)),
        upgraded: [KitchenMenu.pepper],
        onClose: {}
    )
    .environment(AudioManager())
}

#Preview("K2-332 b to 2-3, noodles upgraded") {
    RecipeBookView(
        planet: .k2332b,
        seenIntroductions: Set(["2-1", "2-2", "2-3"].flatMap(KitchenIntroduction.introduced(byLevel:)).map(\.id)),
        upgraded: [KitchenMenu.rawNoodles],
        onClose: {}
    )
    .environment(AudioManager())
}

#Preview("Nothing unlocked") {
    RecipeBookView(planet: .kepler186f, seenIntroductions: [], upgraded: [], onClose: {})
        .environment(AudioManager())
}
