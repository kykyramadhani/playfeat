//
//  PlanetSelectView.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  A planet's home: the landed spaceship with its fuel gauge, the board of
//  the planet's six levels with their best stars, and under it the recipe
//  book, the marathon trophy and the shop. The marathon opens once the first
//  level has a star; the first time it's opened before the planet is done,
//  a warning says it may spoil what's to come. Tapping an open level shows
//  its details in a popup with the PLAY button; tapping a locked level, the
//  locked marathon or the fuel gauge explains what's needed.
//
//  Returning from a finished story day refreshes the earned stars and fuel.
//
//  Each piece is pinned to the screen edge it hugs in the Figma frame, so a
//  wider screen spreads the layout instead of stretching it.
//

import SwiftUI

struct PlanetSelectView: View {
    @Bindable var sceneManager: SceneManager

    @State private var progress: PlanetProgress
    /// Index of the level whose popup is open.
    @State private var selectedLevel: Int?
    @State private var showRecipeBook = false
    @State private var showSpoilerWarning = false
    @State private var showShop = false
    @State private var notice: PlanetNotice?

    init(sceneManager: SceneManager) {
        self.sceneManager = sceneManager
        _progress = State(initialValue: GameStorage.progress(on: PlanetCatalog.planet(sceneManager.planet)))
    }

    /// The planet the player has landed on.
    private var planet: Planet { PlanetCatalog.planet(sceneManager.planet) }

    var body: some View {
        PlanetScreen(backdrop: .planet(planet.backdrop)) {
            Color.clear
                .overlay(alignment: .topLeading) { spaceship.padding(.leading, -6).padding(.top, 191) }
                .overlay(alignment: .bottomLeading) { backToGalaxyButton.padding(.leading, 48).padding(.bottom, 44) }
                .overlay(alignment: .topTrailing) { levelBoard.padding(.trailing, 46).padding(.top, 92) }
        }
        .overlay { levelPopup }
        .overlay {
            if showRecipeBook {
                RecipeBookView(onClose: { showRecipeBook = false })
                    .transition(.opacity)
            }
        }
        .overlay {
            if showShop {
                ShopPopup(clearedLevels: GameStorage.clearedLevels(on: planet), onClose: { showShop = false })
                    .transition(.opacity)
            }
        }
        .overlay {
            if let notice {
                PlanetNoticePopup(notice: notice, onClose: { self.notice = nil })
                    .transition(.opacity)
            }
        }
        .overlay {
            if showSpoilerWarning {
                PlanetNoticePopup(notice: .marathonSpoiler, onClose: enterMarathonAfterWarning)
                    .transition(.opacity)
            }
        }
        .onAppear(perform: loadProgress)
        .animation(.easeOut(duration: 0.2), value: selectedLevel)
        .animation(.easeOut(duration: 0.2), value: showRecipeBook)
        .animation(.easeOut(duration: 0.2), value: showShop)
        .animation(.easeOut(duration: 0.2), value: notice)
        .animation(.easeOut(duration: 0.2), value: showSpoilerWarning)
        .designScaled()
    }

    // MARK: - Left side

    /// The spaceship parked on the sand, its fuel gauge on the side.
    private var spaceship: some View {
        Image("LandedSpaceship")
            .resizable()
            .frame(width: 764, height: 674)
            .accessibilityHidden(true)
            .overlay(alignment: .topLeading) {
                ClickButton(action: { notice = .gas }) {
                    FuelGauge(filledBars: progress.fuelBars(outOf: FuelGauge.barCount))
                }
                .buttonStyle(.plain)
                .padding(.leading, 242.5)
                .padding(.top, 252.5)
            }
    }

    private var backToGalaxyButton: some View {
        ClickButton(action: sceneManager.goToGalaxy) {
            VStack(spacing: 0) {
                Image("GalaxyIcon")
                    .resizable()
                    .frame(width: 89, height: 80)
                Text("Back to Galaxy")
                    .font(.atkinson(size: 20, weight: .bold))
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.purple900)
            }
            .frame(width: 145)
            .offset(y: -2)
        }
        .buttonStyle(RaisedButtonStyle(palette: .pink, lipHeight: 16))
        .frame(width: 168, height: 168)
    }

    // MARK: - Level board

    /// The planet's name banner overlapping the top of the purple board.
    private var levelBoard: some View {
        VStack(spacing: -BoardBanner.overlap) {
            BoardBanner(title: Text(verbatim: planet.name))
                .zIndex(1)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white)
                    .frame(width: 512, height: 536)
                    .offset(x: 33, y: 60)
                levelGrid
                    .offset(x: 66, y: 91)
                MarathonModeButton(isUnlocked: progress.isMarathonUnlocked, action: openMarathon)
                    .scaleEffect(265.7 / 275)
                    .position(x: 289.85, y: 667)
                RaisedIconButton(icon: "RecipeBookIcon", label: "Recipe Book", palette: .yellow) {
                    showRecipeBook = true
                }
                .frame(width: 120, height: 120)
                .offset(x: 29, y: 627)
                RaisedIconButton(icon: "ShopIcon", label: "Shop", palette: .cyan) { showShop = true }
                    .frame(width: 120, height: 120)
                    .offset(x: 427, y: 627)
            }
            .frame(width: 579, height: 800, alignment: .topLeading)
            .boardPanelBackground(cornerRadius: 24)
        }
    }

    private var levelGrid: some View {
        let spacing: CGFloat = 31.13
        return LazyVGrid(
            columns: [GridItem(.fixed(208.5), spacing: spacing), GridItem(.fixed(208.5))],
            spacing: spacing
        ) {
            ForEach(planet.levelIDs.indices, id: \.self) { index in
                levelButton(at: index)
            }
        }
        .frame(width: 448.13)
    }

    @ViewBuilder
    private func levelButton(at index: Int) -> some View {
        let card = LevelCard(
            number: index + 1,
            stars: progress.bestStars[index],
            isLocked: !progress.isUnlocked(levelAt: index)
        )

        ClickButton(action: { openLevel(at: index, isLocked: card.isLocked) }) { card }
            .buttonStyle(.plain)
    }

    private func openLevel(at index: Int, isLocked: Bool) {
        if isLocked {
            notice = .lockedLevel
        } else {
            selectedLevel = index
        }
    }

    /// While it's locked, a note on how to open it. Open, it warns about
    /// spoilers the first time, unless the planet's last level is cleared.
    private func openMarathon() {
        if !progress.isMarathonUnlocked {
            notice = .lockedMarathon
        } else if GameStorage.hasSeenMarathonSpoiler || progress.isPlanetComplete {
            sceneManager.goToMarathon()
        } else {
            showSpoilerWarning = true
        }
    }

    private func enterMarathonAfterWarning() {
        GameStorage.hasSeenMarathonSpoiler = true
        showSpoilerWarning = false
        sceneManager.goToMarathon()
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
                    onShop: { selectedLevel = nil; showShop = true },
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
            starTargets: (try? LevelLoader.load(levelID))?.starTargets ?? [],
            energyCost: (try? LevelLoader.load(levelID))?.energyCost
        )
    }

    /// Re-read on every visit so completed days update the level stars and fuel.
    private func loadProgress() {
        progress = GameStorage.progress(on: planet)
    }
}

#Preview {
    PlanetSelectView(sceneManager: SceneManager())
        .environment(AudioManager())
}
