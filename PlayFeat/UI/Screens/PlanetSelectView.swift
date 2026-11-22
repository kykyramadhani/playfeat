//
//  PlanetSelectView.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  A planet's home: the landed spaceship (tap it to open its hatch) with its
//  fuel gauge, the board of
//  the planet's six levels with their best stars, and under it the recipe
//  book, the marathon trophy and the shop. The marathon opens once the first
//  level has a star; the first time it's opened before the planet is done,
//  a warning says it may spoil what's to come. Tapping an open level shows
//  its details in a popup with the PLAY button; tapping a locked level, the
//  locked marathon or the fuel gauge explains what's needed.
//
//  Returning from a finished story day refreshes the earned stars and fuel.
//  Stars the day newly earned fly from their level card into the fuel
//  gauge, which fills as each one lands (`FuelStarFlights`).
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
    /// Built once, when the board opens, from the stars days left for it.
    @State private var starFlights: FuelFlightPlan
    /// What the fuel gauge shows: behind `progress` until the new stars land.
    @State private var fuel: PlanetProgress

    init(sceneManager: SceneManager) {
        self.sceneManager = sceneManager
        let planet = PlanetCatalog.planet(sceneManager.planet)
        let progress = GameStorage.progress(on: planet)
        let starFlights = FuelFlightPlan(
            progress: progress,
            levelIDs: planet.levelIDs,
            deliveries: sceneManager.starDeliveries
        )
        _progress = State(initialValue: progress)
        _starFlights = State(initialValue: starFlights)
        _fuel = State(initialValue: starFlights.progressBefore)
    }

    /// The planet the player has landed on.
    private var planet: Planet { PlanetCatalog.planet(sceneManager.planet) }

    var body: some View {
        PlanetScreen(backdrop: .planet(planet.backdrop)) {
            Color.clear
                .overlay(alignment: .topLeading) { spaceship.padding(.leading, -6).padding(.top, 191) }
                .overlay(alignment: .bottomLeading) { backToGalaxyButton.padding(.leading, 48).padding(.bottom, 44) }
                .overlay(alignment: .topTrailing) { levelBoard.padding(.trailing, 46).padding(.top, 92) }
                .fuelStarFlights(starFlights, fuel: $fuel)
        }
        .overlay { levelPopup }
        .overlay {
            if showRecipeBook {
                RecipeBookView(planet: planet.id, onClose: { showRecipeBook = false })
                    .transition(.opacity)
            }
        }
        .overlay {
            if showShop {
                ShopPopup(
                    planet: planet.id, clearedLevels: GameStorage.clearedLevels(on: planet),
                    onClose: { showShop = false }
                )
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
            if sceneManager.isShortOfEnergy {
                PlanetNoticePopup(notice: .notEnoughEnergy, onClose: sceneManager.dismissEnergyShortfall)
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
        .onAppear(perform: takeStarDeliveries)
        .animation(.easeOut(duration: 0.2), value: selectedLevel)
        .animation(.easeOut(duration: 0.2), value: showRecipeBook)
        .animation(.easeOut(duration: 0.2), value: showShop)
        .animation(.easeOut(duration: 0.2), value: notice)
        .animation(.easeOut(duration: 0.2), value: showSpoilerWarning)
        .animation(.easeOut(duration: 0.2), value: sceneManager.isShortOfEnergy)
        .designScaled()
    }

    // MARK: - Left side

    /// Each planet's landed ship, with its fuel gauge on the side panel. It
    /// follows `fuel`, so a first star opens the hatch as it lands.
    private var spaceship: some View {
        LandedShip(planet: planet.id, isOpen: fuel.hasClearedFirstLevel)
            .overlay(alignment: .topLeading) {
                ClickButton(action: { notice = .gas }) {
                    FuelGauge(filledBars: fuel.fuelBars(outOf: FuelGauge.barCount))
                        .phaseAnimator([false, true], trigger: fuel) { gauge, isTopped in
                            gauge.scaleEffect(isTopped ? 1.15 : 1)
                        }
                        .anchorPreference(key: FuelFlightAnchors.self, value: .bounds) {
                            FuelFlightAnchors.Value(gauge: $0)
                        }
                }
                .buttonStyle(.plain)
                .padding(.leading, planet.id == .k2332b ? 342.5 : 242.5)
                .padding(.top, 252.5)
            }
    }

    private var backToGalaxyButton: some View {
        ClickButton(action: sceneManager.goToGalaxy, sound: .back) {
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
            .anchorPreference(key: FuelFlightAnchors.self, value: .bounds) {
                FuelFlightAnchors.Value(cards: [index: $0])
            }
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
        } else if TutorialProgress().hasSeenBuffetSpoiler(on: planet.id) || progress.isPlanetComplete {
            sceneManager.goToMarathon()
        } else {
            showSpoilerWarning = true
        }
    }

    private func enterMarathonAfterWarning() {
        var tutorial = TutorialProgress()
        tutorial.seeBuffetSpoiler(on: planet.id)
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

    /// Opens the level's kitchen. Every level ships with a data file
    /// (`LevelLoaderTests` checks), so a failed load opens nothing.
    private func startLevel(at index: Int) {
        guard let level = try? LevelLoader.load(planet.levelIDs[index]) else { return }
        sceneManager.goToKitchen(level)
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

    /// The flights are already planned, so the stars won't fly again on the
    /// next visit.
    private func takeStarDeliveries() {
        sceneManager.markStarsDelivered(on: planet.levelIDs)
    }
}

#Preview {
    PlanetSelectView(sceneManager: SceneManager())
        .environment(AudioManager())
        .environment(EnergyStore())
}
