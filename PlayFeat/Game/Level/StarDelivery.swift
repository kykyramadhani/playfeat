//
//  StarDelivery.swift
//  PlayFeat
//  Created by Owen Limantoro on 19/11/26.
//
//  Stars a finished day added to a level's best, waiting to be flown to the
//  spaceship's fuel gauge the next time the planet board opens. Kept apart
//  from the saved best stars, which are already up to date by then.
//

nonisolated struct StarDelivery: Equatable {
    let levelID: String
    /// The level's best before the stars were earned, and after.
    let previousBest: Int
    let newBest: Int

    /// Two deliveries for one level, the earlier first: one flight from the
    /// earlier best to the later.
    func followed(by later: StarDelivery) -> StarDelivery {
        StarDelivery(levelID: levelID, previousBest: previousBest, newBest: later.newBest)
    }
}

extension StarDelivery {
    /// The stars `report`'s day added to the level's best; nil if it added none.
    init?(report: LevelReport) {
        guard report.newStars > 0 else { return nil }
        self.init(levelID: report.level.id, previousBest: report.previousBestStars, newBest: report.stars)
    }
}
