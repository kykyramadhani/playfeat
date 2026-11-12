//
//  PlanetScreen.swift
//  PlayFeat
//  Created by kyky on 11/11/26.
//
//  What every screen on a planet shares: the planet's landscape, the
//  resource counters along the top, and the settings gear with its sheet.
//  The screen's own content is laid over the landscape, under the top bar.
//  Callers add `.designScaled()` after any overlay that must cover the top
//  bar too, such as a popup's dimming.
//

import SwiftUI

struct PlanetScreen<Content: View>: View {
    @Environment(AudioManager.self) private var audio

    @ViewBuilder let content: Content

    @State private var coinCount = GameStorage.coins
    @State private var showSettings = false

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
        }
        .onAppear {
            coinCount = GameStorage.coins
            audio.startMusic("home_soundtrack")
        }
        .animation(.easeInOut(duration: 0.2), value: showSettings)
    }

    /// Drawn larger than the screen and nudged left, as the Figma frame crops it.
    private var landscape: some View {
        Image("KeplerBackground")
            .resizable()
            .frame(width: 1730, height: 1297)
            .offset(x: -58)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
            .accessibilityHidden(true)
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            // TODO: energy and fuel have no system behind them yet; these are
            // the design's sample values until they do.
            HStack(spacing: 22) {
                HUDCounter(icon: "EnergyIcon", label: "Energy", value: "25/25")
                HUDCounter(icon: "CoinsIcon", label: "Coins", value: "\(coinCount)")
                HUDCounter(icon: "FuelIcon", label: "Fuel", value: "10/12")
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
    PlanetScreen { Color.clear }
        .environment(AudioManager())
}
