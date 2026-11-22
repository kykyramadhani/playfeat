import Foundation
import Testing
@testable import PlayFeat

@MainActor
struct MarathonRecordTests {
    @Test func buffetRecordsUsePointsPerPlanetAndOnlyAnnounceImprovements() throws {
        let suite = "MarathonRecordTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(GameStorage.bestMarathonScore(on: .kepler186f, in: defaults) == 0)
        #expect(GameStorage.recordMarathon(score: 500, on: .kepler186f, in: defaults))
        #expect(!GameStorage.recordMarathon(score: 500, on: .kepler186f, in: defaults))
        #expect(!GameStorage.recordMarathon(score: 450, on: .kepler186f, in: defaults))
        #expect(GameStorage.bestMarathonScore(on: .kepler186f, in: defaults) == 500)
        #expect(GameStorage.bestMarathonScore(on: .k2332b, in: defaults) == 0)
        #expect(GameStorage.recordMarathon(score: 200, on: .k2332b, in: defaults))
    }
}
