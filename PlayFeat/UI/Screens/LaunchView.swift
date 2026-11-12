//
//  LaunchView.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  The space-themed title screen shown after the splash: the PlayFeat logo,
//  a loading bar, and a START button that wakes up once the bar is full.
//  Tapping START hands over to the rest of the app.
//

import SwiftUI

struct LaunchView: View {
    let onStart: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isLoaded = false

    // ponytail: the bar fills on a timer; tie it to real asset loading if
    // start-up ever gets slow enough to need it.
    private static let loadDuration: TimeInterval = 2

    var body: some View {
        ZStack {
            Image("LaunchBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 48) {
                Image("PlayFeatLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 859)
                    .accessibilityLabel(Text(verbatim: "PlayFeat"))

                VStack(spacing: 40) {
                    LoadingBar(progress: progress)
                    startButton
                }
                .frame(width: 711)
            }
        }
        .task { await fillLoadingBar() }
        .designScaled()
    }

    private var startButton: some View {
        RaisedTextButton(title: "Start", palette: isLoaded ? .start : .startDisabled, action: onStart)
            .fixedSize(horizontal: true, vertical: false)
            .disabled(!isLoaded)
    }

    /// Waits out the fill itself: an animation completion handler fired at
    /// once here, while the view was still behind the splash.
    private func fillLoadingBar() async {
        withAnimation(.easeInOut(duration: Self.loadDuration)) {
            progress = 1
        }
        try? await Task.sleep(for: .seconds(Self.loadDuration))
        isLoaded = true
    }
}

/// The cream pill with a green bar growing across its grey track.
private struct LoadingBar: View {
    let progress: CGFloat

    var body: some View {
        Capsule()
            .fill(Color.loadingTrack)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color.loadingFill)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 31)
            .padding(.horizontal, 8)
            .frame(height: 43)
            .background(Color.neutralElevated, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1.7))
            .shadow(color: .black.opacity(0.2), radius: 0, y: 1.9)
            .accessibilityElement()
            .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview {
    LaunchView {}
        .environment(AudioManager())
}
