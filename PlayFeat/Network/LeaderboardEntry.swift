//
//  LeaderboardEntry.swift
//  PlayFeat
//  Created by kyky on 11/11/26.
//
//  One row of a Game Center leaderboard, copied out of GameKit so the
//  screens never touch GKPlayer.
//

nonisolated struct LeaderboardEntry: Identifiable, Equatable {
    let rank: Int
    let name: String
    let score: Int
    let isLocalPlayer: Bool

    var id: Int { rank }
}
