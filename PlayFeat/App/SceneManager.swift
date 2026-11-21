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

    /// The planet the player is on. Its board, Buffet and kitchen are the
    /// ones `planetSelect`, `marathon` and `kitchen` show.
    private(set) var planet: Planet.ID = .kepler186f

    /// Lands on `planet` from the galaxy and opens its level board.
    func goToPlanet(_ planet: Planet.ID) {
        self.planet = planet
        goToPlanetSelect()
    }

    /// Back to the board of the planet the player is on.
    func goToPlanetSelect() {
        levelReport = nil
        screen = .planetSelect
    }

    /// The report of the story day just played, shown over its frozen kitchen
    /// until the player moves on.
    private(set) var levelReport: LevelReport?

    /// Keeps the kitchen mounted behind the finished day's report, and keeps
    /// any stars it added for the planet board to fly to its fuel gauge.
    func showReport(_ report: LevelReport) {
        levelReport = report
        if let delivery = StarDelivery(report: report) { keep(delivery) }
    }

    /// Stars earned since the planet board last showed them, in the order
    /// they were earned. NEXT can play several levels before the board is
    /// seen again; a level played twice keeps one delivery.
    private(set) var starDeliveries: [StarDelivery] = []

    /// The board has flown the stars earned on `levelIDs` to its gauge.
    func markStarsDelivered(on levelIDs: [String]) {
        starDeliveries.removeAll { levelIDs.contains($0.levelID) }
    }

    private func keep(_ delivery: StarDelivery) {
        if let index = starDeliveries.firstIndex(where: { $0.levelID == delivery.levelID }) {
            starDeliveries[index] = starDeliveries[index].followed(by: delivery)
        } else {
            starDeliveries.append(delivery)
        }
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

    /// The marathon being played; nil on a level.
    private(set) var marathon: MarathonSession?

    func goToKitchen(_ level: LevelData) {
        marathon = nil
        levelReport = nil
        enterKitchen(level)
    }

    /// Starts a fresh marathon run on `planet`, one continuous day of rounds
    /// and breaks.
    func startMarathon(on planet: Planet.ID) {
        let marathon = MarathonSession(
            planet: PlanetCatalog.planet(planet), openSeats: Array(KitchenLayout.seats.indices)
        )
        self.marathon = marathon
        enterKitchen(marathon.day.level)
    }

    /// From a kitchen (NEXT, RETRY, RESTART) the old one closes first: the
    /// handover holds `level` until `kitchenDidClose()`, so the new kitchen
    /// is built from nothing, as if it were opened from the board.
    private func enterKitchen(_ level: LevelData) {
        planet = level.planet
        switch screen {
        case .kitchen, .kitchenHandover:
            screen = .kitchenHandover(level)
        default:
            screen = .kitchen(level)
        }
    }

    /// A kitchen is closing so that another can open (NEXT, RETRY, RESTART).
    var isHandingOverKitchen: Bool {
        if case .kitchenHandover = screen { true } else { false }
    }

    /// The closing kitchen has let go of its player and music; the
    /// level waiting in the handover, if any, opens now.
    func kitchenDidClose() {
        guard case .kitchenHandover(let level) = screen else { return }
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
