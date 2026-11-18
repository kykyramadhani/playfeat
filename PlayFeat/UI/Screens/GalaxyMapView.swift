//
//  GalaxyMapView.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  The galaxy: Kepler-186f glowing on the left with its flag planted, and the
//  planets still to come, dark and padlocked. Tapping Kepler-186f opens its
//  level board. Tapping the next planet says what's still needed to fly
//  there — gas, or the unplayed levels — or, once both are done,
//  congratulates the player on opening it and flies there. From then on
//  K2-332 b shows lit, and tapping it opens its board. Reached from START
//  and the board's galaxy button.
//
//  Pieces are placed at their Figma positions (art points on the
//  1376×1034 frame), measured from the screen's top-left corner.
//

import SwiftUI

struct GalaxyMapView: View {
    @Bindable var sceneManager: SceneManager

    @State private var notice: PlanetNotice?
    @State private var showNewPlanet = false

    /// Centres of the planets after Kepler-186f, in design points.
    private static let laterPlanets: [CGPoint] = [
        CGPoint(x: 750.5, y: 548.5),
        CGPoint(x: 1273.5, y: 548.5),
    ]

    /// K2-332 b drawn about the size of the locked planet it replaces.
    private static let openPlanetSize = CGSize(width: 300, height: 305)
    /// How far below a planet's centre its name tag's centre sits, as under Kepler.
    private static let nameTagDrop: CGFloat = 184.5

    /// Remembered with the other one-off popups: once the player has
    /// proceeded to K2-332 b, it stays open on the map.
    private static let planetTwoArrivalID = "newPlanet_\(Planet.ID.k2332b.rawValue)"

    private var hasReachedPlanetTwo: Bool {
        GameStorage.seenIntroductions.contains(Self.planetTwoArrivalID)
    }

    var body: some View {
        PlanetScreen(backdrop: .space) {
            ZStack(alignment: .topLeading) {
                ClickButton(action: { sceneManager.goToPlanet(.kepler186f) }) { kepler }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: Planet.kepler186f.name))
                planetTwo
                    .position(Self.laterPlanets[0])
                ForEach(Self.laterPlanets.indices.dropFirst(), id: \.self) { index in
                    lockedPlanet.position(Self.laterPlanets[index])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .overlay {
            if let notice {
                PlanetNoticePopup(notice: notice, onClose: { self.notice = nil })
                    .transition(.opacity)
            }
        }
        .overlay {
            if showNewPlanet {
                NewPlanetPopup(onProceed: flyToPlanetTwo)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: notice)
        .animation(.easeOut(duration: 0.2), value: showNewPlanet)
        .designScaled()
    }

    private func tryToLeaveKepler() {
        switch GameStorage.progress(on: .kepler186f).departure {
        case .needsFuel: notice = .gas
        case .needsEveryLevel: notice = .unplayedLevels
        case .ready: showNewPlanet = true
        }
    }

    private func flyToPlanetTwo() {
        GameStorage.markIntroductionSeen(Self.planetTwoArrivalID)
        sceneManager.goToPlanet(.k2332b)
    }

    /// K2-332 b: lit once the player has flown there, padlocked before.
    @ViewBuilder
    private var planetTwo: some View {
        if hasReachedPlanetTwo {
            ClickButton(action: { sceneManager.goToPlanet(.k2332b) }) { openPlanet(.k2332b) }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: Planet.k2332b.name))
        } else {
            ClickButton(action: tryToLeaveKepler) { lockedPlanet }
                .buttonStyle(.plain)
        }
    }

    /// A planet the player has reached: its glow, the planet and its name.
    private func openPlanet(_ planet: Planet) -> some View {
        ZStack {
            Ellipse()
                .fill(Color.planetGlow)
                .frame(width: 276, height: 256)
                .blur(radius: 9.5)
            Image(planet.backdrop.galaxyImageName)
                .resizable()
                .frame(width: Self.openPlanetSize.width, height: Self.openPlanetSize.height)
        }
        .overlay { nameTag(planet.name).offset(y: Self.nameTagDrop) }
    }

    /// The open planet: a soft glow, the planet, its flag on a rock, and its name.
    private var kepler: some View {
        ZStack(alignment: .topLeading) {
            Ellipse()
                .fill(Color.planetGlow)
                .frame(width: 276, height: 256)
                .blur(radius: 9.5)
                .position(x: 258, y: 549)
            Image(Planet.kepler186f.backdrop.galaxyImageName)
                .resizable()
                .frame(width: 296, height: 277)
                .position(x: 261, y: 548.5)
            Image("PlanetFlag")
                .resizable()
                .frame(width: 124.5, height: 136)
                .position(x: 266.9, y: 386)
            Image("FlagRock")
                .resizable()
                .frame(width: 133.7, height: 70.7)
                .rotationEffect(.degrees(-2.81))
                .position(x: 260.5, y: 444.4)
            nameTag(Planet.kepler186f.name)
                .position(x: 257.5, y: 733)
        }
        .frame(width: 520, height: 800, alignment: .topLeading)
        .contentShape(Rectangle())
    }

    private func nameTag(_ name: String) -> some View {
        Text(verbatim: name)
            .font(.atkinson(size: 32, weight: .bold))
            .tracking(0.64)
            .textCase(.uppercase)
            .foregroundStyle(Color.purple900)
            .padding(.leading, 12)
            .frame(width: 246, height: 58, alignment: .leading)
            .background(Color.purple50, in: RoundedRectangle(cornerRadius: 22.8))
            .frame(width: 261, height: 70)
            .background(Color.neutralElevated, in: RoundedRectangle(cornerRadius: 28.8))
            .overlay(RoundedRectangle(cornerRadius: 28.8).strokeBorder(.white.opacity(0.5), lineWidth: 1.7))
            .shadow(color: .black.opacity(0.2), radius: 0, y: 1.9)
    }

    private var lockedPlanet: some View {
        ZStack {
            Image("LockedPlanet")
                .resizable()
                .frame(width: 353, height: 361)
            Image("MarathonLock")
                .resizable()
                .frame(width: 120, height: 120)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Locked"))
    }
}

#Preview {
    GalaxyMapView(sceneManager: SceneManager())
        .environment(AudioManager())
}
