//
//  TapToRevealLayer.swift
//  PlayFeat
//  Created by Owen Limantoro on 19/11/26.
//
//  The hidden way out of play. The game is played with hands, not touch, so
//  a permanent button would only sit over the play area: instead a tap
//  anywhere reveals `control`, which hides itself again after a while. The
//  caller places the control, so each game can put it where its design says.
//

import SwiftUI

struct TapToRevealLayer<Control: View>: View {
    @ViewBuilder let control: () -> Control

    @State private var isRevealed = false

    /// Long enough to reach the control, short enough that a forgotten tap
    /// doesn't leave it sitting over the play area.
    private static var autoHideDelay: Duration { .seconds(5) }

    var body: some View {
        ZStack {
            // Full-screen tap catcher. A tap toggles the control; with it
            // showing, a tap that misses it lands here and hides it.
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { setRevealed(!isRevealed) }

            if isRevealed {
                control()
                    .transition(.opacity)
            }
        }
        // Each fresh reveal restarts the timer, through the id.
        .task(id: isRevealed) {
            guard isRevealed else { return }
            do {
                try await Task.sleep(for: Self.autoHideDelay)
            } catch {
                return
            }
            setRevealed(false)
        }
    }

    private func setRevealed(_ revealed: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isRevealed = revealed
        }
    }
}

#Preview {
    TapToRevealLayer {
        PauseButton {}
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    .environment(AudioManager())
}
