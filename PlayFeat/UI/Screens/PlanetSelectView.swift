//
//  PlanetSelectView.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  A planet's home: the two alien chefs on the planet's surface, the board
//  of its levels with their best stars, and the marathon trophy that opens
//  once every level has a star. Reached from the main menu's Tap to Play.
//  Tapping an open level shows its details in a popup with the PLAY button.
//
//  Each piece is pinned to the screen edge it hugs in the Figma frame, so a
//  wider screen spreads the layout instead of stretching it.
//

import SwiftUI

struct PlanetSelectView: View {
    @Bindable var sceneManager: SceneManager

    private let planet = Planet.kepler186f

    @State private var progress = Self.savedProgress(on: .kepler186f)
    /// Index of the level whose popup is open.
    @State private var selectedLevel: Int?

    var body: some View {
        PlanetScreen {
            Color.clear
                .overlay(alignment: .bottomLeading) { chefs.padding(.leading, 239).padding(.bottom, 191) }
                .overlay(alignment: .bottomLeading) { cornerButtons.padding(.leading, 48).padding(.bottom, 62) }
                .overlay(alignment: .bottomTrailing) { levelBoard.padding(.trailing, 46).padding(.bottom, 132) }
        }
        .overlay { levelPopup }
        .onAppear { progress = Self.savedProgress(on: planet) }
        .animation(.easeOut(duration: 0.2), value: selectedLevel)
        .designScaled()
    }

    // MARK: - Corners

    private var cornerButtons: some View {
        HStack(spacing: 23.7) {
            RaisedIconButton(icon: "ShopIcon", label: "Shop", palette: .pink, action: sceneManager.goToShop)
                .frame(width: 109, height: 109)
            // TODO: wire to a help page once one exists.
            RaisedIconButton(icon: "HelpIcon", label: "Help", palette: .pink) {}
                .frame(width: 109, height: 109)
        }
    }

    private var chefs: some View {
        HStack(alignment: .bottom, spacing: -70) {
            Image("AlienChefBlue")
                .resizable()
                .frame(width: 250, height: 406)
                .padding(.bottom, 9)
            Image("AlienChefYellow")
                .resizable()
                .frame(width: 215, height: 441)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Level board

    /// The planet's name banner overlapping the top of the purple board.
    private var levelBoard: some View {
        VStack(spacing: -BoardBanner.overlap) {
            BoardBanner(title: Text(verbatim: planet.name))
                .zIndex(1)
            Color.clear
                .overlay(alignment: .top) { levelGrid.padding(.top, 60) }
                .overlay(alignment: .top) { modeButtons.padding(.top, 400) }
                .frame(width: 579, height: 649)
                .boardPanelBackground(cornerRadius: 24)
        }
    }

    private var levelGrid: some View {
        LazyVGrid(columns: [GridItem(.fixed(208.5), spacing: 31), GridItem(.fixed(208.5))], spacing: 31) {
            ForEach(planet.levelIDs.indices, id: \.self) { index in
                levelButton(at: index)
            }
        }
        .frame(width: 512, height: 370)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private func levelButton(at index: Int) -> some View {
        let card = LevelCard(
            number: index + 1,
            stars: progress.bestStars[index],
            isLocked: !progress.isUnlocked(levelAt: index)
        )

        if card.isLocked {
            card
        } else {
            ClickButton(action: { selectedLevel = index }) { card }
                .buttonStyle(.plain)
        }
    }

    private var modeButtons: some View {
        HStack(alignment: .top, spacing: 2) {
            // TODO: wire to the recipe book once it exists.
            RaisedIconButton(icon: "RecipeBookIcon", label: "Recipe Book", palette: .yellow) {}
                .frame(width: 120, height: 120)
                .padding(.top, 60)

            MarathonModeButton(isUnlocked: progress.isMarathonUnlocked, action: sceneManager.goToMarathon)

            // TODO: wire to the galaxy map once it exists.
            RaisedIconButton(icon: "GalaxyIcon", label: "Galaxy Map", palette: .cyan) {}
                .frame(width: 120, height: 120)
                .padding(.top, 60)
        }
    }

    // MARK: - Level popup

    @ViewBuilder
    private var levelPopup: some View {
        if let index = selectedLevel {
            ZStack {
                Color.black.opacity(0.2)
                LevelDetailPopup(
                    level: levelDetail(at: index),
                    onPlay: { startLevel(at: index) },
                    onShop: sceneManager.goToShop,
                    onClose: { selectedLevel = nil }
                )
                .offset(y: 34)
            }
            .transition(.opacity)
        }
    }

    /// Opens the level's kitchen. A level without a data file yet falls back
    /// to the classic run, so every unlocked level stays playable.
    private func startLevel(at index: Int) {
        if let level = try? LevelLoader.load(planet.levelIDs[index]) {
            sceneManager.goToKitchen(level)
        } else {
            sceneManager.play()
        }
    }

    private func levelDetail(at index: Int) -> LevelDetailPopup.Level {
        let levelID = planet.levelIDs[index]
        return LevelDetailPopup.Level(
            number: index + 1,
            planetName: planet.name,
            stars: progress.bestStars[index],
            starTargets: (try? LevelLoader.load(levelID))?.starTargets ?? []
        )
    }

    // MARK: - Data

    /// Re-read on every visit: a finished level may have earned new stars.
    private static func savedProgress(on planet: Planet) -> PlanetProgress {
        PlanetProgress(bestStars: planet.levelIDs.map { GameStorage.bestStars(forLevel: $0) })
    }
}

#Preview {
    PlanetSelectView(sceneManager: SceneManager())
        .environment(AudioManager())
}
