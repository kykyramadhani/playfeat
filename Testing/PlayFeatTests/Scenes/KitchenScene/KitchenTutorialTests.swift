import Foundation
import SpriteKit
import Testing
@testable import PlayFeat

@MainActor
struct KitchenTutorialTests {
    @Test func firstSaleTeachesEachAcceptedMoveAndRemembersItOnRetry() throws {
        let defaults = try makeDefaults()
        let level = try LevelLoader.load("1-1")
        let (scene, day) = makeKitchenScene(level: level)
        let tutorial = KitchenTutorial(levelID: level.id, isBuffet: false, progress: TutorialProgress(in: defaults))
        scene.installTutorial(tutorial)
        day.start()

        let bubble = add(KitchenMenu.rawFlatbread, at: CGPoint(x: 570, y: 710), in: scene)
        #expect(tutorial.cue(in: scene, day: day)?.source == bubble.position)
        scene.remove(bubble) // A bubble passing out of reach does not finish the lesson.
        #expect(tutorial.cue(in: scene, day: day) == nil)
        let bread = add(KitchenMenu.rawFlatbread, at: CGPoint(x: 700, y: 670), in: scene)
        #expect(tutorial.cue(in: scene, day: day)?.source == bread.position)

        let grill = KitchenBubbleNode.Placement.cooker(.grill, slot: 0)
        let pepper = add(KitchenMenu.pepper, at: CGPoint(x: 620, y: 700), in: scene)
        drop(pepper, on: grill, in: scene)
        #expect(!tutorial.progress.hasLearned(.grillBread))
        #expect(tutorial.cue(in: scene, day: day)?.lesson == .grillBread)

        drop(bread, on: grill, in: scene)
        #expect(tutorial.progress.hasLearned(.grillBread))
        #expect(tutorial.cue(in: scene, day: day) == nil)
        scene.updateCookers(now: 6)
        #expect(tutorial.cue(in: scene, day: day)?.lesson == .plateBread)

        scene.unpark(bread)
        drop(bread, on: .plate(0), in: scene)
        #expect(tutorial.progress.hasLearned(.plateBread))
        scene.remove(pepper)
        let topping = add(KitchenMenu.pepper, at: CGPoint(x: 620, y: 700), in: scene)
        #expect(tutorial.cue(in: scene, day: day)?.lesson == .addPepper)
        drop(topping, on: .plate(0), in: scene)
        #expect(tutorial.cue(in: scene, day: day)?.lesson == .servePepper)

        let dish = try #require(scene.bubbles.first { $0.ingredient == KitchenMenu.pepperFlatbread })
        let seat = try #require(day.presentCustomers.first?.seat)
        scene.unpark(dish)
        scene.serveOrReject(dish, at: seat)
        #expect(tutorial.progress.hasLearned(.servePepper))
        #expect(tutorial.cue(in: scene, day: day) == nil)

        let (retry, retryDay) = makeKitchenScene(level: level)
        let resumed = KitchenTutorial(levelID: level.id, isBuffet: false, progress: TutorialProgress(in: defaults))
        retryDay.start()
        _ = add(KitchenMenu.rawFlatbread, at: CGPoint(x: 570, y: 710), in: retry)
        #expect(resumed.progress.hasServed(KitchenMenu.pepperFlatbread))
        #expect(resumed.cue(in: retry, day: retryDay) == nil)
    }

    @Test func rawNoodleRefusalTeachesThePotWithoutCompletingTheBoilOrBowlSteps() throws {
        let defaults = try makeDefaults()
        let (scene, day) = makeKitchenScene(level: try LevelLoader.load("2-1"))
        let tutorial = KitchenTutorial(levelID: day.level.id, isBuffet: false, progress: TutorialProgress(in: defaults))
        scene.installTutorial(tutorial)
        day.start()
        let raw = add(KitchenMenu.rawNoodles, at: CGPoint(x: 580, y: 680), in: scene)
        #expect(tutorial.cue(in: scene, day: day)?.lesson == .boilNoodles)
        drop(raw, on: .plate(0), in: scene)
        #expect(tutorial.progress.hasLearned(.rawNoodleRefusal))
        #expect(!tutorial.progress.hasLearned(.boilNoodles))
        #expect(!tutorial.progress.hasLearned(.bowlNoodles))

        let noodles = add(KitchenMenu.rawNoodles, at: CGPoint(x: 600, y: 670), in: scene)
        drop(noodles, on: .cooker(.pot, slot: 0), in: scene)
        #expect(tutorial.progress.hasLearned(.boilNoodles))
        scene.updateCookers(now: 6)
        #expect(tutorial.cue(in: scene, day: day)?.lesson == .bowlNoodles)
        scene.unpark(noodles)
        drop(noodles, on: .plate(0), in: scene)
        #expect(tutorial.progress.hasLearned(.bowlNoodles))
        #expect(tutorial.cue(in: scene, day: day) == nil)
    }

    @Test func burntFoodMustBeReleasedByThePlayerAndDisappear() throws {
        let defaults = try makeDefaults()
        let (scene, day) = makeKitchenScene(level: try LevelLoader.load("1-2"))
        let tutorial = KitchenTutorial(levelID: day.level.id, isBuffet: false, progress: TutorialProgress(in: defaults))
        scene.installTutorial(tutorial)
        day.start()

        let first = add(KitchenMenu.burntFlatbread, at: CGPoint(x: 600, y: 650), in: scene)
        #expect(tutorial.cue(in: scene, day: day)?.lesson == .discardBurnt)
        scene.settle(first)
        scene.remove(first)
        #expect(!tutorial.progress.hasLearned(.discardBurnt))

        let second = add(KitchenMenu.burntFlatbread, at: CGPoint(x: 600, y: 650), in: scene)
        scene.settle(second, releasedByPlayer: true)
        #expect(!tutorial.progress.hasLearned(.discardBurnt))
        scene.remove(second)
        #expect(tutorial.progress.hasLearned(.discardBurnt))
    }

    @Test func alwaysShowReplaysCompletedLessonsAndTracksProgressForTheCurrentAttempt() throws {
        let defaults = try makeDefaults()
        let level = try LevelLoader.load("1-1")
        defaults.set(1, forKey: GameStorage.bestStarsKey(forLevel: level.id))
        var progress = TutorialProgress(in: defaults)
        progress.learn(.grillBread)

        let (scene, day) = makeKitchenScene(level: level)
        let tutorial = KitchenTutorial(levelID: level.id, isBuffet: false, progress: TutorialProgress(in: defaults))
        scene.installTutorial(tutorial)
        day.start()
        let bread = add(KitchenMenu.rawFlatbread, at: CGPoint(x: 570, y: 710), in: scene)
        #expect(tutorial.cue(in: scene, day: day) == nil)

        tutorial.alwaysShow = true
        #expect(tutorial.cue(in: scene, day: day)?.lesson == .grillBread)
        drop(bread, on: .cooker(.grill, slot: 0), in: scene)
        scene.updateCookers(now: 6)
        #expect(tutorial.cue(in: scene, day: day)?.lesson == .plateBread)

        tutorial.alwaysShow = false
        #expect(tutorial.cue(in: scene, day: day) == nil)
        tutorial.alwaysShow = true
        #expect(tutorial.cue(in: scene, day: day)?.lesson == .plateBread)

        let (retry, retryDay) = makeKitchenScene(level: level)
        let fresh = KitchenTutorial(levelID: level.id, isBuffet: false, alwaysShow: true,
                                    progress: TutorialProgress(in: defaults))
        retryDay.start()
        _ = add(KitchenMenu.rawFlatbread, at: CGPoint(x: 570, y: 710), in: retry)
        #expect(fresh.cue(in: retry, day: retryDay)?.lesson == .grillBread)
    }

    @Test func visitorResetKeepsProgressAndLearnedDishesAreSharedBetweenModes() throws {
        let defaults = try makeDefaults()
        let recipeIDs = [KitchenIntroduction.sunGrill.id, KitchenIntroduction.pepperFlatbread.id]
        defaults.set(recipeIDs, forKey: GameStorage.seenIntroductionsKey)
        defaults.set(8, forKey: GameStorage.coinKey)
        defaults.set(2, forKey: GameStorage.bestStarsKey(forLevel: "1-1"))
        defaults.set(1, forKey: GameStorage.upgradeLevelKey(KitchenShop.plateID))

        var story = TutorialProgress(in: defaults)
        story.serve(KitchenMenu.mushroomFlatbread)
        story.learn(.addPepper)
        story.seeBuffetSpoiler(on: .kepler186f)

        var buffet = TutorialProgress(in: defaults)
        #expect(buffet.hasServed(KitchenMenu.mushroomFlatbread))
        #expect(buffet.hasSeenBuffetSpoiler(on: .kepler186f))
        #expect(!buffet.hasSeenBuffetSpoiler(on: .k2332b))
        buffet.seeBuffetSpoiler(on: .k2332b)
        TutorialProgress.reset(in: defaults)
        // An older snapshot must not resurrect the lessons it already loaded.
        story.learn(.extraPlate)
        var visitor = TutorialProgress(in: defaults)
        #expect(!visitor.hasServed(KitchenMenu.mushroomFlatbread))
        #expect(!visitor.hasLearned(.addPepper))
        #expect(!visitor.hasSeenBuffetSpoiler(on: .k2332b))
        #expect(!visitor.hasClearedLevel("1-1"))
        visitor.clearLevel("1-1", stars: 0)
        #expect(!visitor.hasClearedLevel("1-1"))
        visitor.clearLevel("1-1", stars: 1)
        #expect(TutorialProgress(in: defaults).hasClearedLevel("1-1"))
        #expect(defaults.stringArray(forKey: GameStorage.seenIntroductionsKey) == recipeIDs)
        #expect(defaults.integer(forKey: GameStorage.coinKey) == 8)
        #expect(defaults.integer(forKey: GameStorage.bestStarsKey(forLevel: "1-1")) == 2)
        #expect(defaults.integer(forKey: GameStorage.upgradeLevelKey(KitchenShop.plateID)) == 1)
    }

    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "KitchenTutorialTests.\(UUID())"))
    }

    private func add(_ ingredient: String, at position: CGPoint, in scene: KitchenScene) -> KitchenBubbleNode {
        let node = KitchenBubbleNode(ingredient: ingredient, radius: scene.bubbleRadius)
        node.position = position
        scene.addChild(node)
        scene.bubbles.append(node)
        return node
    }

    private func drop(_ node: KitchenBubbleNode, on station: KitchenBubbleNode.Placement, in scene: KitchenScene) {
        let rect = scene.layout.sceneRect(scene.artRect(of: station))
        node.position = CGPoint(x: rect.midX, y: rect.midY)
        scene.settle(node, releasedByPlayer: true)
    }
}
