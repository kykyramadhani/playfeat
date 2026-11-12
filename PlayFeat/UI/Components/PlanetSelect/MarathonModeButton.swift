//
//  MarathonModeButton.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  The trophy under the level board that opens the planet's endless
//  marathon. It glows gold once unlocked; until then the trophy is a dark
//  silhouette behind a padlock and nothing happens on tap.
//

import SwiftUI

struct MarathonModeButton: View {
    let isUnlocked: Bool
    let action: () -> Void

    var body: some View {
        if isUnlocked {
            ClickButton(action: action) { badge }
                .buttonStyle(.plain)
        } else {
            badge
        }
    }

    /// Laid out on the Figma frame's own 275×207 grid: the art is a
    /// composed badge, not flowing content.
    private var badge: some View {
        ZStack {
            Circle()
                .fill(isUnlocked ? Color.marathonGlow : .white)
                .frame(width: 153, height: 153)
                .position(x: 137.5, y: 109.5)

            Image("MarathonGlowRays")
                .resizable()
                .frame(width: 194.9, height: 193)
                .foregroundStyle(isUnlocked ? Color.marathonRays : Color.marathonRaysLocked)
                .blur(radius: 8.5)
                .position(x: 134.5, y: 100.6)

            Image(isUnlocked ? "MarathonTrophy" : "MarathonTrophyLocked")
                .resizable()
                .frame(width: 129, height: 134)
                .position(x: 135.5, y: 67)

            if !isUnlocked {
                Image("MarathonLock")
                    .resizable()
                    .frame(width: 103, height: 103)
                    .position(x: 137.5, y: 82.5)
            }

            label
                .position(x: 135, y: 174)
        }
        .frame(width: 275, height: 207)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isUnlocked ? .isButton : [])
    }

    private var label: some View {
        Text("Marathon Mode")
            .font(.atkinson(size: 20, weight: .bold))
            .tracking(0.4)
            .textCase(.uppercase)
            .foregroundStyle(isUnlocked ? Color.purple900 : Color.marathonTextLocked)
            .frame(width: 252, height: 58)
            .background(isUnlocked ? Color.marathonLabel : Color.marathonLabelLocked, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1.7))
            .shadow(color: .black.opacity(0.2), radius: 0, y: 1.9)
    }

    private var accessibilityText: Text {
        isUnlocked ? Text("Marathon Mode") : Text("Marathon Mode, locked")
    }
}

#Preview {
    HStack {
        MarathonModeButton(isUnlocked: true) {}
        MarathonModeButton(isUnlocked: false) {}
    }
    .padding()
    .background(Color.levelPanel)
    .environment(AudioManager())
}
