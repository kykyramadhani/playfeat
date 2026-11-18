//
//  SceneManagerTests.swift
//  PlayFeatTests
//
//  Which screen the app lands on after each navigation call.
//

import Testing
@testable import PlayFeat

@MainActor
struct SceneManagerTests {

    private let result = GameResult(dishesByType: ["salad": 2], speedBonus: 5)

    /// AstroFeast skips the classic main menu: START lands on the galaxy map.
    @Test func theAppOpensOnTheGalaxyMapWithTheTutorialStillToRead() {
        let manager = SceneManager()

        #expect(manager.screen == .galaxy)
        #expect(manager.isInTutorial)
    }

    @Test func playingOpensTheGameplayScreen() {
        let manager = SceneManager()

        manager.play()

        #expect(manager.screen == .gameplay)
    }

    /// The results screen carries the finished run's outcome with it.
    @Test func endingARunShowsItsResults() {
        let manager = SceneManager()
        manager.play()

        manager.goToPostGame(result)

        #expect(manager.screen == .postGame(result))
    }

    @Test func playAgainGoesFromTheResultsBackIntoGameplay() {
        let manager = SceneManager()
        manager.goToPostGame(result)

        manager.replayGame()

        #expect(manager.screen == .gameplay)
    }

    /// Tap to Play opens the galaxy; a planet there opens its board.
    @Test func theGalaxyLeadsToAPlanetsBoard() {
        let manager = SceneManager()

        manager.goToGalaxy()
        #expect(manager.screen == .galaxy)

        manager.goToPlanetSelect()
        #expect(manager.screen == .planetSelect)
    }

    /// The planet board opens first; a level there starts the run.
    @Test func thePlanetBoardSitsBetweenTheMenuAndARun() {
        let manager = SceneManager()

        manager.goToPlanetSelect()
        #expect(manager.screen == .planetSelect)

        manager.play()
        #expect(manager.screen == .gameplay)
    }

    /// The unlocked trophy opens the marathon; STORY MODE goes back to the board.
    @Test func theMarathonOpensFromThePlanetBoardAndLeadsBackToIt() {
        let manager = SceneManager()
        manager.goToPlanetSelect()

        manager.goToMarathon()
        #expect(manager.screen == .marathon)

        manager.goToPlanetSelect()
        #expect(manager.screen == .planetSelect)
    }

    /// A planet level opens its kitchen, carrying the level it plays.
    @Test func aLevelOpensItsKitchen() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")

        manager.goToKitchen(level)

        #expect(manager.screen == .kitchen(level))
    }

    /// RETRY goes to the level already on screen; the visit count still
    /// moves, so the kitchen is rebuilt and the day starts over.
    @Test func retryingALevelCountsAsANewVisit() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)

        manager.goToKitchen(level)

        #expect(manager.kitchenVisit == 2)
    }

    @Test func aStoryReportKeepsTheFinishedKitchenOnScreen() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        let report = makeReport(for: level)
        manager.goToKitchen(level)

        manager.showReport(report)

        #expect(manager.screen == .kitchen(level))
        #expect(manager.kitchenVisit == 1)
        #expect(manager.levelReport == report)
    }

    @Test func leavingTheReportReturnsToTheBoardAndClearsIt() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)
        manager.showReport(makeReport(for: level))

        manager.goToPlanetSelect()

        #expect(manager.screen == .planetSelect)
        #expect(manager.levelReport == nil)
    }

    @Test func nextFromTheReportOpensAFreshKitchenForTheFollowingLevel() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        let nextLevel = try LevelLoader.load("1-2")
        manager.goToKitchen(level)
        manager.showReport(makeReport(for: level))

        manager.goToNextLevel(after: level)

        #expect(manager.screen == .kitchen(nextLevel))
        #expect(manager.kitchenVisit == 2)
        #expect(manager.levelReport == nil)
    }

    @Test func retryFromTheReportRebuildsTheKitchenAndClearsTheReport() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)
        manager.showReport(makeReport(for: level))

        manager.goToKitchen(level)

        #expect(manager.screen == .kitchen(level))
        #expect(manager.kitchenVisit == 2)
        #expect(manager.levelReport == nil)
    }

    @Test func nextAfterTheFinalLevelReturnsToTheBoard() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-6")
        manager.goToKitchen(level)
        manager.showReport(makeReport(for: level))

        manager.goToNextLevel(after: level)

        #expect(manager.screen == .planetSelect)
        #expect(manager.levelReport == nil)
    }

    private func makeReport(for level: LevelData) -> LevelReport {
        let day = KitchenDay(
            storyLevel: level,
            positionTypes: KitchenLayout.positionTypes,
            tools: KitchenTools(for: level, ownedPlates: 1, ownedGlasses: 1)
        )
        return LevelReport(day: day, previousBestStars: 0)
    }

    @Test func theShopIsReachableAndItsBackButtonReturnsToTheMenu() {
        let manager = SceneManager()

        manager.goToShop()
        #expect(manager.screen == .shop)

        manager.goToMainMenu()
        #expect(manager.screen == .mainMenu)
    }

    /// Read once per launch: a second run goes straight to the seat check.
    @Test func finishingTheTutorialSkipsItForLaterRuns() {
        let manager = SceneManager()

        manager.finishTutorial()
        manager.replayGame()

        #expect(!manager.isInTutorial)
    }
}
