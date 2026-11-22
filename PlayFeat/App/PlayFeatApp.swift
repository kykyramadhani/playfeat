//
//  PlayFeatApp.swift
//  PlayFeat
//

import SwiftUI
import UIKit

@main
struct PlayFeatApp: App {
    @State private var audio = AudioManager()
    @State private var camera: CameraManager
    @State private var handPoseManager: HandPoseManager

    @Environment(\.scenePhase) private var scenePhase

    init() {
        _camera = State(initialValue: CameraManager())
        _handPoseManager = State(initialValue: HandPoseManager())
        
        // Before any text is drawn: point the bundle at the language the
        // player last chose, so the app opens in it rather than flashing the
        // system language first.
        AppLocalization
            .applyStoredLanguage()
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            app.debugScreenSize()
            #else
            app
            #endif
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhase(phase)
        }
        // The game is played with hands, not touch, so nothing resets the
        // auto-lock timer: the screen stays on whenever the app is in front.
        .onChange(of: scenePhase, initial: true) { _, phase in
            UIApplication.shared.isIdleTimerDisabled = phase == .active
        }
    }

    private var app: some View {
        PhoneSafeSides {
            // Inside, not on the scene: PhoneSafeSides hosts the app
            // separately, and environment doesn't reach across. That includes
            // the scene phase, which KitchenView needs to pause the day.
            ContentView()
                .environment(audio)
                .environment(handPoseManager)
                .environment(\.scenePhase, scenePhase)
        }
    }

    // MARK: - Leaving and returning to the foreground

    /// App-wide reaction; GameplayView pauses the run itself, since each run
    /// owns its own clock and scene.
    ///
    /// iOS always passes through `.inactive` on the way to `.background`, so
    /// the GPU stops there, while it is still allowed to finish a frame.
    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            handPoseManager.resume()
            audio.resumeEffects()
            audio.fadeInMusic()
        case .inactive:
            handPoseManager.suspend()
        case .background:
            handPoseManager.suspend()
            audio.suspendEffects()
            audio.fadeOutMusic()
        @unknown default:
            handPoseManager.suspend()
        }
    }
}
