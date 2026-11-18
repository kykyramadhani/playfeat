//
//  PlanetCatalog.swift
//  PlayFeat
//  Created by Owen Limantoro on 18/11/26.
//
//  Every planet in the game, in the order they are flown to, and the
//  lookups the gameplay needs: a level's planet, and the level after it.
//  Adding a planet means adding its definition here and in `Planet.ID`.
//

nonisolated enum PlanetCatalog {
    static let all: [Planet] = Planet.ID.allCases.map { planet($0) }

    static func planet(_ id: Planet.ID) -> Planet {
        switch id {
        case .kepler186f: .kepler186f
        case .k2332b: .k2332b
        }
    }

    /// The planet whose days include `levelID`, or nil for one that is no
    /// planet's (the marathon's).
    static func planet(forLevel levelID: String) -> Planet? {
        all.first { $0.levelIDs.contains(levelID) }
    }

    /// The day after `levelID` on the same planet, or nil after its last day.
    static func nextLevelID(after levelID: String) -> String? {
        guard let levelIDs = planet(forLevel: levelID)?.levelIDs,
              let index = levelIDs.firstIndex(of: levelID),
              levelIDs.indices.contains(index + 1) else { return nil }
        return levelIDs[index + 1]
    }

    /// The day's number on its planet, counted from 1, or nil for a level
    /// that is no planet's.
    static func dayNumber(of levelID: String) -> Int? {
        planet(forLevel: levelID)?.levelIDs.firstIndex(of: levelID).map { $0 + 1 }
    }
}
