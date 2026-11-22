//
//  PausePopup.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  The card STOP opens over the kitchen: resume, start over, settings, or
//  home. A level calls it GAME PAUSE; a marathon, ROUND PAUSE, and starts
//  the whole run over, since a marathon is one continuous day.
//

import SwiftUI

struct PausePopup: View {
    struct Labels {
        let title: LocalizedStringKey
        let resume: LocalizedStringKey
        let restart: LocalizedStringKey

        static let level = Labels(title: "Game Pause", resume: "Resume Level", restart: "Retry Level")
        static let marathon = Labels(title: "Round Pause", resume: "Resume", restart: "Restart Buffet")
    }

    let labels: Labels
    let onResume: () -> Void
    let onRestart: () -> Void
    let onSettings: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            NoticeCard(bottomMargin: 41) { buttons }
                .padding(.top, 37)
                .overlay(alignment: .top) { TiltedTitleBadge(title: Text(labels.title)).padding(.top, 3) }
        }
        .designScaled()
        .accessibilityAddTraits(.isModal)
    }

    private var buttons: some View {
        VStack(spacing: 40) {
            NoticeButton(title: labels.resume, icon: "PlayIcon", width: 350, action: onResume)
            NoticeButton(title: labels.restart, icon: "RestartIcon", width: 329, action: onRestart)
            HStack(spacing: 21) {
                iconButton("SettingsGear", label: "Settings", action: onSettings)
                iconButton("HomeIcon", label: "Home", action: onHome)
            }
        }
        .padding(.top, 96)
        .padding(.bottom, 24)
    }

    private func iconButton(_ icon: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        RaisedIconButton(icon: icon, label: label, palette: .pink, action: action)
            .foregroundStyle(Color.electricPink)
            .frame(width: 76, height: 76)
    }
}

#Preview {
    PausePopup(labels: .level, onResume: {}, onRestart: {}, onSettings: {}, onHome: {})
        .environment(AudioManager())
}
