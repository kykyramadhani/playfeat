//
//  RedEdgeFlash.swift
//  PlayFeat
//  Created by Owen Limantoro on 20/11/26.
//
//  The screen's left and right edges blink red when something is lost: a
//  life in the camera game (LoseHeartOverlay), a customer in a marathon.
//  Moved out of LoseHeartOverlay so both games flash the same way.
//

import SwiftUI

struct RedEdgeFlash: View {
    /// How many have been lost so far; each rise blinks the edges.
    let losses: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var opacity: Double = 0

    private static let blinkDuration: TimeInterval = 0.2
    /// Three blinks: each one fades in and back out.
    private static let blinkHalves = 6

    var body: some View {
        RedEdgeGlow()
            .opacity(opacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: losses) { previous, current in
                if current > previous { flash() }
            }
    }

    private func flash() {
        if reduceMotion {
            glowOnce()
        } else {
            blink()
        }
    }

    private func blink() {
        withAnimation(.easeInOut(duration: Self.blinkDuration).repeatCount(Self.blinkHalves, autoreverses: true)) {
            opacity = 1
        } completion: {
            opacity = 0
        }
    }

    /// With Reduce Motion on, one slow glow in and out instead of blinking.
    private func glowOnce() {
        withAnimation(.easeIn(duration: 0.3)) {
            opacity = 1
        } completion: {
            withAnimation(.easeOut(duration: 0.6)) { opacity = 0 }
        }
    }
}

/// Red fading in from the left and right edges, clear in the middle.
private struct RedEdgeGlow: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .warningRed.opacity(0.45), location: 0.0),
                .init(color: .warningRed.opacity(0.15), location: 0.25),
                .init(color: .clear, location: 0.5),
                .init(color: .warningRed.opacity(0.15), location: 0.75),
                .init(color: .warningRed.opacity(0.45), location: 1.0),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    @Previewable @State var losses = 0
    ZStack {
        Color.gray
        RedEdgeFlash(losses: losses)
    }
    .task {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2))
            losses += 1
        }
    }
}
