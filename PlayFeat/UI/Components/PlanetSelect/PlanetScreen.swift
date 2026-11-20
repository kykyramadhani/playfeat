//
//  PlanetScreen.swift
//  PlayFeat
//  Created by kyky on 11/11/26.
//
//  What every screen on a planet shares: the planet's landscape, the
//  resource counters along the top (energy explains itself on a tap), and
//  the settings gear with its sheet.
//  The screen's own content is laid over the landscape, under the top bar.
//  Callers add `.designScaled()` after any overlay that must cover the top
//  bar too, such as a popup's dimming.
//

import SwiftUI

struct PlanetScreen<Content: View>: View {
    /// What fills the screen behind the content.
    enum Backdrop {
        /// A planet's own landscape, for its board and Buffet.
        case planet(PlanetBackdrop)
        /// Starry space, for the galaxy map.
        case space
    }

    let backdrop: Backdrop
    @ViewBuilder let content: Content

    /// Watches the saved purse, so a purchase in a popup over this screen
    /// (the shop) shows in the counter at once.
    @AppStorage(GameStorage.coinKey) private var coinCount = 0
    @State private var showSettings = false
    @State private var showEnergyNotice = false

    var body: some View {
        ZStack {
            content
                .background(alignment: .top) { landscape }
                .overlay(alignment: .top) { topBar }

            if showSettings {
                SettingsView(onClose: { showSettings = false })
                    .transition(.opacity)
                    .zIndex(1)
            }

            if showEnergyNotice {
                PlanetNoticePopup(notice: .energy, onClose: { showEnergyNotice = false })
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSettings)
        .animation(.easeInOut(duration: 0.2), value: showEnergyNotice)
    }

    @ViewBuilder
    private var landscape: some View {
        switch backdrop {
        case .planet(let planetBackdrop):
            LayeredPlanetBackdrop(backdrop: planetBackdrop)
        case .space:
            Image("LaunchBackground")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)
        }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            // TODO: energy has no system behind it yet; this is the design's
            // sample value until it does. Fuel shows on the spaceship.
            HStack(spacing: 22) {
                ClickButton(action: { showEnergyNotice = true }) {
                    HUDCounter(icon: "EnergyIcon", label: "Energy", value: "25/25", metrics: .energy)
                }
                .buttonStyle(.plain)
                HUDCounter(icon: "HUDCoinsIcon", label: "Coins", value: "\(coinCount)", metrics: .coins)
            }
            .padding(.leading, 31)
            .padding(.top, 33)

            Spacer()

            RaisedIconButton(icon: "SettingsGear", label: "Settings", palette: .pink) {
                showSettings = true
            }
            .frame(width: 76, height: 76)
            .padding(.trailing, 46)
            .padding(.top, 38)
        }
    }
}

#Preview {
    PlanetScreen(backdrop: .planet(Planet.k2332b.backdrop)) { Color.clear }
        .environment(AudioManager())
}
