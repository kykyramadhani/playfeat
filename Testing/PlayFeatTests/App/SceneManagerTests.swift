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

    /// Landing on a planet from the galaxy opens that planet's board.
    @Test func landingOnAPlanetOpensItsBoard() {
        let manager = SceneManager()

        manager.goToPlanet(.k2332b)

        #expect(manager.planet == .k2332b)
        #expect(manager.screen == .planetSelect)
    }

    /// A day's kitchen is on its own planet, so leaving it goes back to that
    /// planet's board.
    @Test func aPlanetTwoDayReturnsToPlanetTwosBoard() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("2-1")

        manager.goToKitchen(level)
        manager.goToPlanetSelect()

        #expect(manager.planet == .k2332b)
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

    /// RETRY from a kitchen doesn't open the new one straight away: the
    /// old kitchen closes first, so the day is rebuilt from nothing.
    @Test func retryingALevelClosesTheOldKitchenFirst() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)

        manager.goToKitchen(level)

        #expect(manager.screen == .kitchenHandover(level))
    }

    @Test func theWaitingKitchenOpensOnceTheOldOneHasClosed() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)
        manager.goToKitchen(level)

        manager.kitchenDidClose()

        #expect(manager.screen == .kitchen(level))
    }

    /// Pressing RETRY again while the old kitchen is still closing keeps
    /// waiting for it, rather than opening a kitchen beside it.
    @Test func aSecondRetryDuringTheHandoverKeepsWaiting() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)
        manager.goToKitchen(level)

        manager.goToKitchen(level)

        #expect(manager.screen == .kitchenHandover(level))
    }

    @Test func restartingAMarathonClosesTheOldKitchenAndStartsAFreshRun() throws {
        let manager = SceneManager()
        manager.startMarathon(on: .kepler186f)
        let firstRun = try #require(manager.marathon)

        manager.startMarathon(on: .kepler186f)

        #expect(manager.screen == .kitchenHandover(firstRun.day.level))
        #expect(manager.marathon !== firstRun)
    }

    /// The closing kitchen keeps the camera running only when another
    /// kitchen is about to open.
    @Test func aRetryIsAKitchenHandover() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)

        manager.goToKitchen(level)

        #expect(manager.isHandingOverKitchen)
    }

    @Test func leavingForTheBoardIsNotAKitchenHandover() throws {
        let manager = SceneManager()
        manager.goToKitchen(try LevelLoader.load("1-1"))

        manager.goToPlanetSelect()

        #expect(!manager.isHandingOverKitchen)
    }

    /// Leaving for the board: the kitchen closing afterwards opens nothing.
    @Test func closingAKitchenOnTheWayToTheBoardStaysOnTheBoard() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)
        manager.goToPlanetSelect()

        manager.kitchenDidClose()

        #expect(manager.screen == .planetSelect)
    }

    @Test func aStoryReportKeepsTheFinishedKitchenOnScreen() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        let report = makeReport(for: level)
        manager.goToKitchen(level)

        manager.showReport(report)

        #expect(manager.screen == .kitchen(level))
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

        #expect(manager.screen == .kitchenHandover(nextLevel))
        #expect(manager.levelReport == nil)
    }

    @Test func retryFromTheReportRebuildsTheKitchenAndClearsTheReport() throws {
        let manager = SceneManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)
        manager.showReport(makeReport(for: level))

        manager.goToKitchen(level)

        #expect(manager.screen == .kitchenHandover(level))
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

    // MARK: - Stars for the fuel gauge

    /// A day that beat the level's best leaves its new stars for the board.
    @Test func aReportWithNewStarsLeavesThemForTheBoard() throws {
        let manager = SceneManager()

        manager.showReport(try makeOneStarReport(previousBest: 0))

        #expect(manager.starDeliveries == [StarDelivery(levelID: "test", previousBest: 0, newBest: 1)])
    }

    @Test func aReportWithNoNewStarsLeavesNothing() throws {
        let manager = SceneManager()

        manager.showReport(try makeOneStarReport(previousBest: 1))

        #expect(manager.starDeliveries.isEmpty)
    }

    @Test func aLevelPlayedTwiceBeforeTheBoardKeepsOneDelivery() throws {
        let manager = SceneManager()
        manager.showReport(try makeOneStarReport(previousBest: 0))

        manager.showReport(try makeOneStarReport(previousBest: 0))

        #expect(manager.starDeliveries.count == 1)
    }

    @Test func theBoardTakesOnlyItsOwnPlanetsStars() throws {
        let manager = SceneManager()
        manager.showReport(try makeOneStarReport(previousBest: 0))

        manager.markStarsDelivered(on: ["1-1", "1-2"])
        #expect(manager.starDeliveries.count == 1)

        manager.markStarsDelivered(on: ["test"])
        #expect(manager.starDeliveries.isEmpty)
    }

    /// A day on the test level that served one order: one star.
    private func makeOneStarReport(previousBest: Int) throws -> LevelReport {
        let day = makeDay()
        day.start()
        for frame in 0...5 { day.tick(at: Double(frame) * 0.2) }
        let seat = try #require(day.presentCustomers.first?.seat)
        #expect(day.serve(KitchenMenu.pepperFlatbread, at: seat))
        return LevelReport(day: day, previousBestStars: previousBest)
    }

    private func makeReport(for level: LevelData) -> LevelReport {
        let day = KitchenDay(
            storyLevel: level,
            openSeats: KitchenLayout.openSeats(on: level),
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
