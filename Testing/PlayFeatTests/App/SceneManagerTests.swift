//
//  SceneManagerTests.swift
//  PlayFeatTests
//
//  Which screen the app lands on after each navigation call.
//

import Foundation
import Testing
@testable import PlayFeat

@MainActor
struct SceneManagerTests {

    private let result = GameResult(dishesByType: ["salad": 2], speedBonus: 5)

    /// A returning player's manager, with a full energy meter of its own, so
    /// tests don't drain (or depend on) the energy and story saved on the device.
    private func makeManager(energy: EnergyMeter = EnergyMeter()) -> SceneManager {
        let defaults = UserDefaults(suiteName: "SceneManagerTests-\(UUID().uuidString)") ?? .standard
        defaults.set(energy.stored, forKey: EnergyStore.storedKey)
        defaults.set(energy.refillStartedAt, forKey: EnergyStore.refillStartedAtKey)
        GameStorage.markIntroductionSeen(SceneManager.introStoryID, in: defaults)
        return SceneManager(energy: EnergyStore(defaults: defaults), defaults: defaults)
    }

    // MARK: - Intro story

    /// Fresh, empty defaults: what a new install starts with.
    private func makeFreshInstallDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "SceneManagerTests-\(UUID().uuidString)"))
    }

    @Test func aFreshInstallOpensOnTheIntroStory() throws {
        let manager = SceneManager(defaults: try makeFreshInstallDefaults())

        #expect(manager.screen == .introStory)
    }

    @Test func finishingTheIntroStoryGoesToTheGalaxy() throws {
        let manager = SceneManager(defaults: try makeFreshInstallDefaults())

        manager.finishIntroStory()

        #expect(manager.screen == .galaxy)
    }

    @Test func theIntroStoryNeverPlaysAgainOnceFinished() throws {
        let defaults = try makeFreshInstallDefaults()
        SceneManager(defaults: defaults).finishIntroStory()

        let nextLaunch = SceneManager(defaults: defaults)

        #expect(nextLaunch.screen == .galaxy)
    }

    @Test func otherIntroductionsDontCountAsSeeingTheStory() throws {
        let defaults = try makeFreshInstallDefaults()
        GameStorage.markIntroductionSeen("newPlanet_k2332b", in: defaults)

        let manager = SceneManager(defaults: defaults)

        #expect(manager.screen == .introStory)
    }

    // MARK: - Energy

    @Test func startingALevelSpendsItsEnergy() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("1-1")

        manager.goToKitchen(level)

        #expect(manager.screen == .kitchen(level))
        #expect(manager.energy.meter.energy(at: .now) == EnergyMeter.maxEnergy - level.energyCost)
    }

    @Test func aLevelCostingMoreEnergyThanIsLeftDoesntOpen() throws {
        let manager = makeManager(energy: EnergyMeter(stored: 1, refillStartedAt: .now))
        let level = try LevelLoader.load("1-1")
        manager.goToPlanet(.kepler186f)

        manager.goToKitchen(level)

        #expect(manager.screen == .planetSelect)
        #expect(manager.isShortOfEnergy)
    }

    /// AstroFeast skips the classic main menu: START lands on the galaxy map.
    @Test func theAppOpensOnTheGalaxyMapWithTheTutorialStillToRead() {
        let manager = makeManager()

        #expect(manager.screen == .galaxy)
        #expect(manager.isInTutorial)
    }

    @Test func playingOpensTheGameplayScreen() {
        let manager = makeManager()

        manager.play()

        #expect(manager.screen == .gameplay)
    }

    /// The results screen carries the finished run's outcome with it.
    @Test func endingARunShowsItsResults() {
        let manager = makeManager()
        manager.play()

        manager.goToPostGame(result)

        #expect(manager.screen == .postGame(result))
    }

    @Test func playAgainGoesFromTheResultsBackIntoGameplay() {
        let manager = makeManager()
        manager.goToPostGame(result)

        manager.replayGame()

        #expect(manager.screen == .gameplay)
    }

    /// Tap to Play opens the galaxy; a planet there opens its board.
    @Test func theGalaxyLeadsToAPlanetsBoard() {
        let manager = makeManager()

        manager.goToGalaxy()
        #expect(manager.screen == .galaxy)

        manager.goToPlanetSelect()
        #expect(manager.screen == .planetSelect)
    }

    /// Landing on a planet from the galaxy opens that planet's board.
    @Test func landingOnAPlanetOpensItsBoard() {
        let manager = makeManager()

        manager.goToPlanet(.k2332b)

        #expect(manager.planet == .k2332b)
        #expect(manager.screen == .planetSelect)
    }

    /// A day's kitchen is on its own planet, so leaving it goes back to that
    /// planet's board.
    @Test func aPlanetTwoDayReturnsToPlanetTwosBoard() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("2-1")

        manager.goToKitchen(level)
        manager.goToPlanetSelect()

        #expect(manager.planet == .k2332b)
        #expect(manager.screen == .planetSelect)
    }

    /// The planet board opens first; a level there starts the run.
    @Test func thePlanetBoardSitsBetweenTheMenuAndARun() {
        let manager = makeManager()

        manager.goToPlanetSelect()
        #expect(manager.screen == .planetSelect)

        manager.play()
        #expect(manager.screen == .gameplay)
    }

    /// The unlocked trophy opens the marathon; STORY MODE goes back to the board.
    @Test func theMarathonOpensFromThePlanetBoardAndLeadsBackToIt() {
        let manager = makeManager()
        manager.goToPlanetSelect()

        manager.goToMarathon()
        #expect(manager.screen == .marathon)

        manager.goToPlanetSelect()
        #expect(manager.screen == .planetSelect)
    }

    /// A planet level opens its kitchen, carrying the level it plays.
    @Test func aLevelOpensItsKitchen() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("1-1")

        manager.goToKitchen(level)

        #expect(manager.screen == .kitchen(level))
    }

    /// RETRY from a kitchen doesn't open the new one straight away: the
    /// old kitchen closes first, so the day is rebuilt from nothing.
    @Test func retryingALevelClosesTheOldKitchenFirst() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)

        manager.goToKitchen(level)

        #expect(manager.screen == .kitchenHandover(level))
    }

    @Test func theWaitingKitchenOpensOnceTheOldOneHasClosed() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)
        manager.goToKitchen(level)

        manager.kitchenDidClose()

        #expect(manager.screen == .kitchen(level))
    }

    /// Pressing RETRY again while the old kitchen is still closing keeps
    /// waiting for it, rather than opening a kitchen beside it.
    @Test func aSecondRetryDuringTheHandoverKeepsWaiting() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)
        manager.goToKitchen(level)

        manager.goToKitchen(level)

        #expect(manager.screen == .kitchenHandover(level))
    }

    @Test func restartingAMarathonClosesTheOldKitchenAndStartsAFreshRun() throws {
        let manager = makeManager()
        manager.startMarathon(on: .kepler186f)
        let firstRun = try #require(manager.marathon)

        manager.startMarathon(on: .kepler186f)

        #expect(manager.screen == .kitchenHandover(firstRun.day.level))
        #expect(manager.marathon !== firstRun)
    }

    /// The closing kitchen keeps the camera running only when another
    /// kitchen is about to open.
    @Test func aRetryIsAKitchenHandover() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)

        manager.goToKitchen(level)

        #expect(manager.isHandingOverKitchen)
    }

    @Test func leavingForTheBoardIsNotAKitchenHandover() throws {
        let manager = makeManager()
        manager.goToKitchen(try LevelLoader.load("1-1"))

        manager.goToPlanetSelect()

        #expect(!manager.isHandingOverKitchen)
    }

    /// Leaving for the board: the kitchen closing afterwards opens nothing.
    @Test func closingAKitchenOnTheWayToTheBoardStaysOnTheBoard() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)
        manager.goToPlanetSelect()

        manager.kitchenDidClose()

        #expect(manager.screen == .planetSelect)
    }

    @Test func aStoryReportKeepsTheFinishedKitchenOnScreen() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("1-1")
        let report = makeReport(for: level)
        manager.goToKitchen(level)

        manager.showReport(report)

        #expect(manager.screen == .kitchen(level))
        #expect(manager.levelReport == report)
    }

    @Test func leavingTheReportReturnsToTheBoardAndClearsIt() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)
        manager.showReport(makeReport(for: level))

        manager.goToPlanetSelect()

        #expect(manager.screen == .planetSelect)
        #expect(manager.levelReport == nil)
    }

    @Test func nextFromTheReportOpensAFreshKitchenForTheFollowingLevel() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("1-1")
        let nextLevel = try LevelLoader.load("1-2")
        manager.goToKitchen(level)
        manager.showReport(makeReport(for: level))

        manager.goToNextLevel(after: level)

        #expect(manager.screen == .kitchenHandover(nextLevel))
        #expect(manager.levelReport == nil)
    }

    @Test func retryFromTheReportRebuildsTheKitchenAndClearsTheReport() throws {
        let manager = makeManager()
        let level = try LevelLoader.load("1-1")
        manager.goToKitchen(level)
        manager.showReport(makeReport(for: level))

        manager.goToKitchen(level)

        #expect(manager.screen == .kitchenHandover(level))
        #expect(manager.levelReport == nil)
    }

    @Test func nextAfterTheFinalLevelReturnsToTheBoard() throws {
        let manager = makeManager()
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
        let manager = makeManager()

        manager.showReport(try makeOneStarReport(previousBest: 0))

        #expect(manager.starDeliveries == [StarDelivery(levelID: "test", previousBest: 0, newBest: 1)])
    }

    @Test func aReportWithNoNewStarsLeavesNothing() throws {
        let manager = makeManager()

        manager.showReport(try makeOneStarReport(previousBest: 1))

        #expect(manager.starDeliveries.isEmpty)
    }

    @Test func aLevelPlayedTwiceBeforeTheBoardKeepsOneDelivery() throws {
        let manager = makeManager()
        manager.showReport(try makeOneStarReport(previousBest: 0))

        manager.showReport(try makeOneStarReport(previousBest: 0))

        #expect(manager.starDeliveries.count == 1)
    }

    @Test func theBoardTakesOnlyItsOwnPlanetsStars() throws {
        let manager = makeManager()
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
        let manager = makeManager()

        manager.goToShop()
        #expect(manager.screen == .shop)

        manager.goToMainMenu()
        #expect(manager.screen == .mainMenu)
    }

    /// Read once per launch: a second run goes straight to the seat check.
    @Test func finishingTheTutorialSkipsItForLaterRuns() {
        let manager = makeManager()

        manager.finishTutorial()
        manager.replayGame()

        #expect(!manager.isInTutorial)
    }
}
