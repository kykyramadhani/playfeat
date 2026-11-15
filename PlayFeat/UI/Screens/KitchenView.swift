//
//  KitchenView.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  One day of a planet level, played in the planet's illustrated kitchen
//  instead of over the camera picture. The camera shows only during the seat
//  check; after that hand tracking keeps running and the player's hands are
//  drawn as cartoon hands over the kitchen.
//
//  Layers, back to front: the kitchen art (KitchenBackdrop), the SpriteKit
//  bubbles and hands (KitchenScene), then the HUD and overlays. When the
//  day's clock runs out the shift ends and the player goes back to the
//  planet board.
//

import AVFoundation
import SpriteKit
import SwiftUI

struct KitchenView: View {
    @Environment(AudioManager.self) private var audio
    @Environment(HandPoseManager.self) private var handPoseManager
    /// Forwarded by PlayFeatApp (PhoneSafeSides hosts the app separately).
    @Environment(\.scenePhase) private var scenePhase

    @Bindable var sceneManager: SceneManager

    @State private var day: KitchenDay
    @State private var scene = KitchenScene(size: KitchenLayout.artSize)
    @State private var hasCalibrated = false
    /// 3 → 0 ("GO!") during a get-ready beat, -1 otherwise.
    @State private var countdown = 3
    @State private var showShiftOver = false
    /// The app left the foreground while the day was running.
    @State private var isInterrupted = false
    /// It went as far as the background: coming back plays a fresh 3-2-1.
    @State private var needsGetReadyOnReturn = false
    @State private var resumeCountdownRequest = 0

    init(sceneManager: SceneManager, level: LevelData) {
        self.sceneManager = sceneManager
        var generator = SystemRandomNumberGenerator()
        let day = KitchenDay(level: level, seatCount: KitchenLayout.seats.count, using: &generator)
        _day = State(initialValue: day)
        #if DEBUG
        _hasCalibrated = State(initialValue: DebugLaunch.skipSeatCheck)
        #endif
    }

    var body: some View {
        ZStack {
            if hasCalibrated {
                KitchenBackdrop(day: day)
            } else {
                CameraPreviewView(camera: handPoseManager.camera)
                    .ignoresSafeArea()
            }

            sceneLayer

            if hasCalibrated {
                dayOverlays
            } else {
                SeatCalibrationView(handPoseManager: handPoseManager) {
                    handPoseManager.lockOntoPlayer()
                    hasCalibrated = true
                }
                .designScaled()
            }

            if showShiftOver {
                GameOverOverlay { sceneManager.goToPlanetSelect() }
                    .designScaled()
                    .zIndex(200)
            }
        }
        .onAppear(perform: setUp)
        .onDisappear(perform: tearDown)
        .onChange(of: day.isOver) { _, isOver in
            if isOver { endShift() }
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhase(phase)
        }
    }

    // MARK: - Layers

    private var sceneLayer: some View {
        GeometryReader { proxy in
            SpriteView(
                scene: scene,
                // No GPU work outside the foreground — iOS rejects it.
                isPaused: scenePhase != .active,
                options: [.allowsTransparency, .ignoresSiblingOrder]
            )
            .onAppear { scene.size = proxy.size }
            .onChange(of: proxy.size) { _, newSize in scene.size = newSize }
        }
        .ignoresSafeArea()
    }

    private var dayOverlays: some View {
        ZStack {
            KitchenHUD(day: day)

            if countdown >= 0 {
                GetReadyOverlay(count: countdown)
                    .ignoresSafeArea()
            }

            if handPoseManager.authorizationStatus == .denied
                || handPoseManager.authorizationStatus == .restricted {
                CameraPermissionDeniedOverlay()
            }

            if countdown < 0, !showShiftOver {
                StopButtonLayer(onStop: endShift)
            }
        }
        .task {
            guard await playGetReadyCountdown() else { return }
            day.start()
            audio.startMusic()
        }
        .task(id: resumeCountdownRequest) {
            guard resumeCountdownRequest > 0,
                  await playGetReadyCountdown(),
                  scenePhase == .active else { return }
            day.start()
        }
        .designScaled()
    }

    // MARK: - Lifecycle

    private func setUp() {
        scene.prepare(for: day, pantry: Planet.kepler186f.pantry)
        scene.handInput = handPoseManager
        scene.audio = audio
        handPoseManager.start()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func tearDown() {
        handPoseManager.releasePlayer()
        handPoseManager.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        audio.stopMusic()
    }

    /// Plays the 3-2-1-GO! beat. False if it was cut short.
    private func playGetReadyCountdown() async -> Bool {
        audio.play(.countdown)
        for step in stride(from: 3, through: 0, by: -1) {
            countdown = step
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return false
            }
        }
        countdown = -1
        return true
    }

    private func endShift() {
        guard !showShiftOver else { return }
        day.pause()
        audio.stopMusic()
        showShiftOver = true
    }

    // MARK: - Leaving and returning to the foreground

    /// Hand tracking stops whenever the app isn't active, so the day's clock
    /// stops with it. Back from the background, a fresh 3-2-1 plays first.
    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            guard isInterrupted else { return }
            isInterrupted = false
            if needsGetReadyOnReturn {
                needsGetReadyOnReturn = false
                resumeCountdownRequest += 1
            } else {
                day.start()
            }
        case .background:
            // `.inactive` always comes first and has already paused the day.
            needsGetReadyOnReturn = isInterrupted
        default:
            if day.isRunning {
                isInterrupted = true
                day.pause()
            }
        }
    }
}
