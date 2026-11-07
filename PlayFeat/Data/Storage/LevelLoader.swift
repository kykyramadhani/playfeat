//
//  LevelLoader.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  Reads `level_<id>.json` from the bundle and validates it.
//

import Foundation

nonisolated enum LevelLoaderError: Error {
    case fileMissing(levelID: String)
    case unreadable(levelID: String, underlying: Error)
    case invalid(levelID: String, LevelDataError)
}

nonisolated enum LevelLoader {
    static func fileName(for levelID: String) -> String { "level_\(levelID)" }

    static func load(_ levelID: String, from bundle: Bundle = .main) throws(LevelLoaderError) -> LevelData {
        guard let url = bundle.url(forResource: fileName(for: levelID), withExtension: "json") else {
            throw .fileMissing(levelID: levelID)
        }
        let level: LevelData
        do {
            level = try JSONDecoder().decode(LevelData.self, from: Data(contentsOf: url))
        } catch {
            throw .unreadable(levelID: levelID, underlying: error)
        }
        do {
            try level.validate()
        } catch {
            throw .invalid(levelID: levelID, error)
        }
        return level
    }
}
