//
//  RaisedTextButton.swift
//  PlayFeat
//  Created by kyky on 11/11/26.
//
//  A 76pt-tall RaisedButtonStyle button with one word on it (START, PLAY).
//  It fills the width it's given, so callers either `.fixedSize` it to hug
//  the word or give it a width.
//

import SwiftUI

struct RaisedTextButton: View {
    let title: LocalizedStringKey
    let palette: RaisedButtonPalette
    let action: () -> Void

    var body: some View {
        ClickButton(action: action) {
            Text(title)
                .font(.atkinson(size: 32, weight: .bold))
                .tracking(0.64)
                .textCase(.uppercase)
                .foregroundStyle(palette.label)
                .shadow(color: .black.opacity(0.15), radius: 0, y: 2.5)
                .padding(.horizontal, 40)
        }
        .buttonStyle(RaisedButtonStyle(palette: palette, lipHeight: 12.67))
        .frame(height: 76)
        .shadow(color: .black.opacity(0.25), radius: 1.3, y: 5)
    }
}

#Preview {
    RaisedTextButton(title: "Play", palette: .start) {}
        .frame(width: 208)
        .environment(AudioManager())
}
