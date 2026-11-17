//
//  RecipeBookView.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  The recipe book, opened from the planet board: a pink page on the left
//  for the chosen recipe — its name, picture, description and how to cook
//  it — and a grid of every recipe on the right. Tiles past the known
//  recipes are locked.
//

import SwiftUI

struct RecipeBookView: View {
    let onClose: () -> Void

    @State private var selected = RecipeBook.entries[0]

    var body: some View {
        SunrisePopupOverlay(title: Text("Recipe"), onClose: onClose) {
            HStack(alignment: .top) {
                RecipePage(entry: selected)
                Spacer(minLength: 0)
                tiles
            }
            .frame(width: 825)
            .padding(.leading, 33.85)
            .padding(.top, 34)
        }
    }

    private var tiles: some View {
        LazyVGrid(columns: [GridItem(.fixed(165), spacing: 13), GridItem(.fixed(165))], spacing: 13.3) {
            ForEach(0..<RecipeBook.tileCount, id: \.self) { index in
                if RecipeBook.entries.indices.contains(index) {
                    let entry = RecipeBook.entries[index]
                    ClickButton(action: { selected = entry }) {
                        RecipeTile(entry: entry, isSelected: entry == selected)
                    }
                    .buttonStyle(.plain)
                } else {
                    LockedRecipeTile()
                }
            }
        }
        .frame(width: 343)
    }
}

// MARK: - Page

/// The chosen recipe, on the book's pink page.
private struct RecipePage: View {
    let entry: RecipeBookEntry

    var body: some View {
        VStack(spacing: 5) {
            Text(entry.name)
                .font(.atkinson(size: 32, weight: .bold))
                .tracking(0.64)
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .frame(height: 46)
            KitchenItemArt(item: entry.item)
                .frame(width: 178, height: 160)
            InfoBox(tab: Text("Description")) {
                Text(entry.description)
                    .font(.atkinson(size: 14.7, weight: .bold))
                    .foregroundStyle(Color.purple900)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
            }
            InfoBox(tab: Text("How to Cook")) { howToCook }
        }
        .padding(.horizontal, 29)
        .padding(.vertical, 25)
        .frame(width: 465)
        .background(Color.nebulaPink, in: RoundedRectangle(cornerRadius: 16))
    }

    /// "A + B = result", in pictures.
    private var howToCook: some View {
        HStack(spacing: 18) {
            term(entry.madeFrom[0])
            sign("PlusSign", size: 23.6)
            term(entry.madeFrom[1])
            sign("EqualsSign", size: 33.6)
            KitchenItemArt(item: entry.item).frame(width: 51, height: 51)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(entry.name))
    }

    @ViewBuilder
    private func term(_ term: RecipeBookEntry.Term) -> some View {
        switch term {
        case .item(let item):
            KitchenItemArt(item: item).frame(width: 51, height: 51)
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
    let isSelected: Bool

    var body: some View {
        KitchenItemArt(item: entry.item)
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

private struct LockedRecipeTile: View {
    var body: some View {
        Image("LockedRecipe")
            .resizable()
            .scaledToFit()
            .frame(width: 116, height: 104)
            .overlay {
                Text(verbatim: "?")
                    .font(.atkinson(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 165, height: 184)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Locked"))
    }
}

#Preview {
    RecipeBookView(onClose: {})
        .environment(AudioManager())
}
