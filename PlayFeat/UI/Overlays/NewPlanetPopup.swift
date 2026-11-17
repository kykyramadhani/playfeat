//
//  NewPlanetPopup.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  Shown on the galaxy when the player taps the next planet with a full
//  tank and every level played: the planet they've just opened up.
//

import SwiftUI

struct NewPlanetPopup: View {
    let onProceed: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            NoticeCard(bottomMargin: 49) { content }
        }
        .designScaled()
        .accessibilityAddTraits(.isModal)
    }

    private var content: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    Text("Congratulations!!")
                        .font(.atkinson(size: 32, weight: .bold))
                        .textCase(.uppercase)
                        .accessibilityAddTraits(.isHeader)
                    // ponytail: the next planet has no name or levels yet.
                    Text("You’ve unlocked a new planet")
                        .font(.atkinson(size: 32, weight: .bold))
                }
                .tracking(-0.64)
                .foregroundStyle(Color.purple900)
                .multilineTextAlignment(.center)
                .frame(width: 508)

                Image("NewPlanet")
                    .resizable()
                    .frame(width: 223, height: 228)
                    .accessibilityHidden(true)
            }
            NoticeButton(title: "Proceed to Planet", icon: "PlayIcon", width: 448, action: onProceed)
        }
        .padding(.top, 53)
        .padding(.bottom, 48)
    }
}

#Preview {
    NewPlanetPopup(onProceed: {})
        .environment(AudioManager())
}
