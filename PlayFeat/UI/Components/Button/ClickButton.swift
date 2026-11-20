//
//  ClickButton.swift
//  PlayFeat
//
//  A Button with the UI click sound built in. Use it instead of `Button` for
//  every tappable control, so the sound lives in one place and a new button
//  can't forget it. Where a screen accepts hand clicks, it can also be
//  pressed by pinching over it (HandClickTarget).
//

import SwiftUI

struct ClickButton<Label: View>: View {
    @Environment(AudioManager.self) private var audio

    let action: () -> Void
    var sound: SoundEffect? = .uiClick
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: press) {
            label()
        }
        .handClickTarget(press: press)
    }

    private func press() {
        if let sound { audio.play(sound) }
        action()
    }
}

#Preview {
    ClickButton(action: {}) {
        Text("Tap me")
    }
    .environment(AudioManager())
}
