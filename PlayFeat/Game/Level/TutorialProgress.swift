import Foundation

/// A visitor's learned hints are independent of recipes, purchases and scores.
nonisolated struct TutorialProgress {
    enum Lesson: String {
        case grillBread, plateBread, addPepper, servePepper, discardBurnt, patience, fillGlass
        case boilNoodles, bowlNoodles, rawNoodleRefusal, grillClam, buildCookie, angryCustomer
        case ingredientUpgrade, extraPlate, extraBowl
    }

    static let alwaysShowKey = "settings.alwaysShowTutorial"
    private static let key = "tutorial.completed"
    private static let legacySpoilerKey = "marathonSpoilerSeen"
    private static let visitorResetKey = "tutorial.visitorReset"
    private let defaults: UserDefaults
    private var completed: Set<String>
    private var completedThisVisit: Set<String> = []
    var repeatsLessons = false

    init(in defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completed = Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    private var completedLessons: Set<String> { repeatsLessons ? completedThisVisit : completed }

    func hasLearned(_ lesson: Lesson) -> Bool { completedLessons.contains(lesson.rawValue) }
    func hasServed(_ dish: String) -> Bool { completedLessons.contains("dish.\(dish)") }

    func hasClearedLevel(_ levelID: String) -> Bool {
        // Existing saves already have stars. After New Visitor, only clears
        // by the new visitor count for the tutorial.
        completed.contains("level.\(levelID)")
            || (!defaults.bool(forKey: Self.visitorResetKey)
                && defaults.integer(forKey: GameStorage.bestStarsKey(forLevel: levelID)) > 0)
    }

    func hasSeenBuffetSpoiler(on planet: Planet.ID) -> Bool {
        completed.contains("spoiler.\(planet.rawValue)")
            || (planet == .kepler186f && defaults.bool(forKey: Self.legacySpoilerKey))
    }

    mutating func seeBuffetSpoiler(on planet: Planet.ID) { record("spoiler.\(planet.rawValue)") }

    mutating func learn(_ lesson: Lesson) { record(lesson.rawValue) }
    mutating func serve(_ dish: String) { record("dish.\(dish)") }
    mutating func clearLevel(_ levelID: String, stars: Int) {
        guard stars > 0 else { return }
        record("level.\(levelID)")
    }

    static func reset(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: legacySpoilerKey)
        defaults.set(true, forKey: visitorResetKey)
    }

    private mutating func record(_ id: String) {
        completedThisVisit.insert(id)
        guard !completed.contains(id) else { return }
        // Merge only the new action, so an old snapshot cannot restore hints
        // that the New Visitor shortcut cleared.
        var saved = Set(defaults.stringArray(forKey: Self.key) ?? [])
        saved.insert(id)
        completed = saved
        defaults.set(saved.sorted(), forKey: Self.key)
    }
}
