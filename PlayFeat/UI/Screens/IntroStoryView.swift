//
//  IntroStoryView.swift
//  PlayFeat
//  Created by kyky on 21/11/26.
//
//  The comic that plays once after install, between the loading screen and
//  the galaxy: six panels, each a Lottie animation with its caption drawn
//  over it. A tap anywhere turns the page; SKIP STORY ends it at once.
//

import Lottie
import SwiftUI

struct IntroStoryView: View {
    let onFinish: () -> Void

    @State private var panelIndex = 0

    private var panel: IntroStoryPanel { IntroStoryPanel.all[panelIndex] }
    private var isLastPanel: Bool { panelIndex == IntroStoryPanel.all.indices.last }

    var body: some View {
        ZStack {
            Color.storyInk
                .ignoresSafeArea()

            IntroStoryArtwork(animationName: panel.animationName)
                .ignoresSafeArea()

            IntroStoryCaption(panel: panel, isLastPanel: isLastPanel, onSkip: onFinish)
                .designScaled()
        }
        // Rebuilt per panel, so every panel's animation and caption start over.
        .id(panelIndex)
        .contentShape(Rectangle())
        .onTapGesture(perform: turnPage)
    }

    private func turnPage() {
        if isLastPanel {
            onFinish()
        } else {
            panelIndex += 1
        }
    }
}

/// The panel's artwork, played once and held on its last frame. Filled to the
/// screen like the Figma frame it was drawn on.
private struct IntroStoryArtwork: View {
    let animationName: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        LottieView(animation: .named(animationName))
            .playbackMode(playback)
            .resizable()
            .configure(\.contentMode, to: .scaleAspectFill)
            .accessibilityHidden(true)
    }

    private var playback: LottiePlaybackMode {
        reduceMotion
            ? .paused(at: .progress(1))
            : .playing(.toProgress(1, loopMode: .playOnce))
    }
}

/// Everything drawn over the artwork: SKIP STORY, the caption box and the
/// tap hint, at their Figma positions on the design canvas.
private struct IntroStoryCaption: View {
    let panel: IntroStoryPanel
    let isLastPanel: Bool
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isCaptionShown = false
    @State private var isHintShown = false

    /// The hint fades in once the caption has had time to be read.
    private static let hintDelay: TimeInterval = 2.1

    var body: some View {
        VStack(spacing: 18) {
            IntroStorySkipButton(action: onSkip)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 39)
                .padding(.trailing, 41)

            Spacer()

            captionBox
                .opacity(isCaptionShown ? 0.75 : 0)
                .offset(y: isCaptionShown ? 0 : 16)

            Text(isLastPanel ? "Tap anywhere to start" : "Tap anywhere to continue")
                .font(.atkinson(size: 24, weight: .bold))
                .foregroundStyle(.white.opacity(0.68))
                .opacity(isHintShown ? 1 : 0)
                .padding(.bottom, 34)
        }
        .onAppear(perform: reveal)
    }

    /// Two rounded boxes, the dark one inset in the purple one; the whole
    /// box is translucent, text included, as in the design.
    private var captionBox: some View {
        Text(AppLocalization.string(panel.caption))
            .font(.atkinson(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 714, alignment: .leading)
            .padding(.vertical, 24)
            .frame(width: 776)
            .frame(minHeight: 113)
            .background(Color.storyInk, in: RoundedRectangle(cornerRadius: 24))
            .padding(16)
            .background(Color.purple800, in: RoundedRectangle(cornerRadius: 24))
            .compositingGroup()
    }

    private func reveal() {
        guard !reduceMotion else {
            isCaptionShown = true
            isHintShown = true
            return
        }
        withAnimation(.easeOut(duration: 0.45).delay(panel.captionDelay)) {
            isCaptionShown = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(Self.hintDelay)) {
            isHintShown = true
        }
    }
}

/// The white pill on a pink lip from the story frames' top-right corner.
private struct IntroStorySkipButton: View {
    let action: () -> Void

    var body: some View {
        ClickButton(action: action) {
            HStack(spacing: 9) {
                Text("Skip Story")
                    .font(.atkinson(size: 24, weight: .bold))
                    .tracking(0.48)
                    .textCase(.uppercase)
                Image("PlayIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Color.electricPink)
            .shadow(color: .black.opacity(0.15), radius: 0, y: 2.26)
            .padding(.horizontal, 36)
        }
        .buttonStyle(RaisedButtonStyle(palette: .pink, lipHeight: 11.28))
        .frame(height: 67.67)
        .fixedSize(horizontal: true, vertical: false)
    }
}

#Preview {
    IntroStoryView {}
        .environment(AudioManager())
}
