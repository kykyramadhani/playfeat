//
//  SceneManager.swift
//  PlayFeat
//
//  Owns which screen the app is showing. Gameplay state (score, timer,
//  recipes) stays in GameStateManager, and the tutorial and seat check live
//  inside GameplayView — this only decides between the full-screen
//  destinations in AppScreen.
//

import Foundation

@Observable
final class SceneManager {
    /// AstroFeast opens on the galaxy map, straight from START.
    private(set) var screen: AppScreen = .galaxy

    /// True until the walkthrough has been read or skipped this launch.
    private(set) var isInTutorial = true

    /// Walkthrough read, or skipped.
    func finishTutorial() {
        isInTutorial = false
    }

    func goToGalaxy() {
        screen = .galaxy
    }

    func goToPlanetSelect() {
        levelReport = nil
        screen = .planetSelect
    }

    /// The report of the story day just played, shown over its frozen kitchen
    /// until the player moves on.
    private(set) var levelReport: LevelReport?

    /// Keeps the kitchen mounted behind the finished day's report.
    func showReport(_ report: LevelReport) {
        levelReport = report
    }

    /// NEXT opens the following level on the same planet; the planet's
    /// final level returns to the board.
    func goToNextLevel(after level: LevelData) {
        guard let nextID = PlanetCatalog.nextLevelID(after: level.id),
              let nextLevel = try? LevelLoader.load(nextID) else {
            goToPlanetSelect()
            return
        }
        goToKitchen(nextLevel)
    }

    func goToMarathon() {
        screen = .marathon
    }

    /// Counts trips into a kitchen. RETRY sends the player to the level
    /// they are already on, which leaves `screen` unchanged; ContentView keys
    /// the kitchen on this so the day starts over all the same.
    private(set) var kitchenVisit = 0

    /// The marathon being played; nil on a level.
    private(set) var marathon: MarathonSession?

    func goToKitchen(_ level: LevelData) {
        marathon = nil
        levelReport = nil
        enterKitchen(level)
    }

    /// Starts a fresh marathon run on `planet`, one continuous day of rounds
    /// and breaks. Planet 1's until the planet screens pass the planet in.
    func startMarathon(on planet: Planet.ID = .kepler186f) {
        let marathon = MarathonSession(planet: PlanetCatalog.planet(planet), positionTypes: KitchenLayout.positionTypes)
        self.marathon = marathon
        enterKitchen(marathon.day.level)
    }

    private func enterKitchen(_ level: LevelData) {
        kitchenVisit += 1
        screen = .kitchen(level)
    }

    func play() {
        screen = .gameplay
    }

    /// Leaving `.gameplay` removes GameplayView, which tears down its camera
    /// and scene before the results show.
    func goToPostGame(_ result: GameResult) {
        screen = .postGame(result)
    }

    /// Play Again from the results screen. Coming from `.postGame`, this
    /// builds a brand-new GameplayView — and with it a fresh GameStateManager —
    /// so the seat check and countdown run again just like the first time.
    func replayGame() {
        screen = .gameplay
    }

    func goToMainMenu() {
        screen = .mainMenu
    }

    func goToShop() {
        screen = .shop
    }
}
