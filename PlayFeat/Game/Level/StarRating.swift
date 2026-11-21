//
//  StarRating.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  Turns a day's score into 0–3 stars using the level's `starTargets`.
//

nonisolated enum StarRating {
    /// A level has three star targets.
    static let maxStars = 3

    static func stars(for score: Int, targets: [Int]) -> Int {
        targets.filter { score >= $0 }.count
    }
}
