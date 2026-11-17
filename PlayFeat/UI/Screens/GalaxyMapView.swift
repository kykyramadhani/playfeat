//
//  GalaxyMapView.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  The galaxy: Kepler-186f glowing on the left with its flag planted, and the
//  planets still to come, dark and padlocked. Tapping Kepler-186f opens its
//  level board. Tapping the next planet says what's still needed to fly
//  there — gas, or the unplayed levels — or, once both are done,
//  congratulates the player on opening it. Reached from START and the
//  board's galaxy button.
//
//  Pieces are placed at their Figma positions (art points on the
//  1376×1034 frame), measured from the screen's top-left corner.
//

import SwiftUI

struct GalaxyMapView: View {
    @Bindable var sceneManager: SceneManager

    @State private var notice: PlanetNotice?
    @State private var showNewPlanet = false

    /// Centres of the planets not yet open, in design points.
    private static let lockedPlanets: [CGPoint] = [
        CGPoint(x: 750.5, y: 548.5),
        CGPoint(x: 1273.5, y: 548.5),
    ]

    var body: some View {
        PlanetScreen(backdrop: .space) {
            ZStack(alignment: .topLeading) {
                ClickButton(action: sceneManager.goToPlanetSelect) { kepler }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: Planet.kepler186f.name))
                ClickButton(action: tryToLeaveKepler) { lockedPlanet }
                    .buttonStyle(.plain)
                    .position(Self.lockedPlanets[0])
                ForEach(Self.lockedPlanets.indices.dropFirst(), id: \.self) { index in
                    lockedPlanet.position(Self.lockedPlanets[index])
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
                // ponytail: the next planet has no board yet, so PROCEED just closes.
                NewPlanetPopup(onProceed: { showNewPlanet = false })
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

    /// The open planet: a soft glow, the planet, its flag on a rock, and its name.
    private var kepler: some View {
        ZStack(alignment: .topLeading) {
            Ellipse()
                .fill(Color.planetGlow)
                .frame(width: 276, height: 256)
                .blur(radius: 9.5)
                .position(x: 258, y: 549)
            Image("KeplerPlanet")
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
            nameTag
                .position(x: 257.5, y: 733)
        }
        .frame(width: 520, height: 800, alignment: .topLeading)
        .contentShape(Rectangle())
    }

    private var nameTag: some View {
        Text(verbatim: Planet.kepler186f.name)
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
