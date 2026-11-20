import Foundation

/// A visitor's learned hints are independent of recipes, purchases and scores.
nonisolated struct TutorialProgress {
    enum Lesson: String {
        case grillBread, plateBread, addPepper, servePepper, discardBurnt, patience, fillGlass
        case boilNoodles, bowlNoodles, rawNoodleRefusal, grillClam, buildCookie, angryCustomer
        case ingredientUpgrade, extraPlate, extraBowl
    }

    private static let key = "tutorial.completed"
    private static let legacySpoilerKey = "marathonSpoilerSeen"
    private let defaults: UserDefaults
    private var completed: Set<String>

    init(in defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completed = Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    func hasLearned(_ lesson: Lesson) -> Bool { completed.contains(lesson.rawValue) }
    func hasServed(_ dish: String) -> Bool { completed.contains("dish.\(dish)") }

    func hasSeenBuffetSpoiler(on planet: Planet.ID) -> Bool {
        completed.contains("spoiler.\(planet.rawValue)")
            || (planet == .kepler186f && defaults.bool(forKey: Self.legacySpoilerKey))
    }

    mutating func seeBuffetSpoiler(on planet: Planet.ID) { record("spoiler.\(planet.rawValue)") }

    mutating func learn(_ lesson: Lesson) { record(lesson.rawValue) }
    mutating func serve(_ dish: String) { record("dish.\(dish)") }

    static func reset(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: legacySpoilerKey)
    }

    private mutating func record(_ id: String) {
        guard !completed.contains(id) else { return }
        // Merge only the new action, so an old snapshot cannot restore hints
        // that the New Visitor shortcut cleared.
        var saved = Set(defaults.stringArray(forKey: Self.key) ?? [])
        saved.insert(id)
        completed = saved
        defaults.set(saved.sorted(), forKey: Self.key)
    }
}
