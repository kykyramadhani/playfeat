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

    @Test func theAppOpensOnTheMainMenuWithTheTutorialStillToRead() {
        let manager = SceneManager()

        #expect(manager.screen == .mainMenu)
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

    /// Tap to Play opens the planet board first; a level there starts the run.
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
