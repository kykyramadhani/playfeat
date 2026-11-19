//
//  AppScreen.swift
//  PlayFeat
//
//  The full-screen destinations ContentView can show. The tutorial and seat
//  check are not here on purpose: they are phases inside GameplayView, so the
//  camera stays mounted from the first tutorial page to the end of the run.
//

import Foundation

enum AppScreen: Equatable {
    case mainMenu
    /// The galaxy: the planets, opened from the main menu's Tap to Play.
    case galaxy
    /// A planet's level board, between the galaxy and a run.
    case planetSelect
    /// The planet's endless marathon: best score, leaderboard, PLAY.
    case marathon
    case shop
    case gameplay
    /// One day of a planet level, in that planet's kitchen.
    case kitchen(LevelData)
    /// Between two kitchens: the old one closes before `LevelData`'s opens.
    case kitchenHandover(LevelData)
    /// The end-of-run paycheck, carrying the finished run's outcome.
    case postGame(GameResult)
}
