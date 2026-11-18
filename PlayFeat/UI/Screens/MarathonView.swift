//
//  MarathonView.swift
//  PlayFeat
//  Created by kyky on 11/11/26.
//
//  The planet's endless mode: the glowing trophy with the player's best
//  score under it, PLAY, and the Game Center leaderboard on the right.
//  Reached from the unlocked marathon trophy; STORY MODE goes back to the
//  level board.
//

import SwiftUI

struct MarathonView: View {
    @Bindable var sceneManager: SceneManager

    @State private var highestScore = GameStorage.highscore
    @State private var leaderboard: [LeaderboardEntry] = []

    private static let leaderboardSize = 5

    var body: some View {
        PlanetScreen(backdrop: .planet(PlanetCatalog.planet(sceneManager.planet).backdrop)) {
            Color.clear
                .overlay(alignment: .topLeading) { storyModeButton.padding(.leading, 36).padding(.top, 147) }
                .overlay(alignment: .topLeading) { trophyColumn.padding(.leading, 142).padding(.top, 215) }
                .overlay(alignment: .topTrailing) { leaderboardBoard.padding(.trailing, 46).padding(.top, 114) }
        }
        .designScaled()
        .task {
            highestScore = GameStorage.highscore
            leaderboard = await GameCenter.topEntries(count: Self.leaderboardSize)
        }
    }

    private var storyModeButton: some View {
        ClickButton(action: sceneManager.goToPlanetSelect) {
            HStack(spacing: 9) {
                Image("BackTriangle")
                    .resizable()
                    .frame(width: 14, height: 24)
                Text("Story Mode")
                    .font(.atkinson(size: 24, weight: .bold))
                    .tracking(0.48)
                    .textCase(.uppercase)
            }
            .foregroundStyle(RaisedButtonPalette.pink.label)
            .padding(.horizontal, 36)
        }
        .buttonStyle(RaisedButtonStyle(palette: .pink, lipHeight: 11.3))
        .frame(height: 67.7)
        .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: - Trophy column

    private var trophyColumn: some View {
        VStack(spacing: 0) {
            trophy
            TabbedValueBox(tab: Text("Highest Score"), value: Text(highestScore, format: .number), metrics: .highScore)
                .padding(.top, 12)
            RaisedTextButton(title: "Play", palette: .start, action: { sceneManager.startMarathon(on: sceneManager.planet) })
                .frame(width: 208)
                .padding(.top, 25)
        }
        .frame(width: 471)
    }

    /// The gold trophy in front of its blurred yellow rays, a touch left of
    /// the column's centre as in the design.
    private var trophy: some View {
        ZStack(alignment: .bottom) {
            Image("MarathonGlowRays")
                .resizable()
                .frame(width: 542, height: 537)
                .foregroundStyle(Color.marathonRays)
                .blur(radius: 23.5)
                .frame(maxHeight: .infinity)
            Image("MarathonTrophy")
                .resizable()
                .frame(width: 408, height: 424)
        }
        .frame(width: 471, height: 445)
        .offset(x: -10)
        .accessibilityHidden(true)
    }

    // MARK: - Leaderboard

    private var leaderboardBoard: some View {
        VStack(spacing: -BoardBanner.overlap) {
            BoardBanner(title: Text("Leaderboard"))
                .zIndex(1)
            LeaderboardList(entries: leaderboard)
                .frame(width: 512, height: 699)
                .background(.white, in: RoundedRectangle(cornerRadius: 24))
                .padding(.top, 60)
                .frame(width: 579, height: 800, alignment: .top)
                .boardPanelBackground(cornerRadius: 24)
        }
    }
}

#Preview {
    MarathonView(sceneManager: SceneManager())
        .environment(AudioManager())
}
