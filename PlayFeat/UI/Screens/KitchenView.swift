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
//  bubbles and hands (KitchenScene), then the HUD and overlays. When a
//  story day ends its stars and income are banked and the report shows over
//  the frozen kitchen. A marathon is one continuous day: each round's end
//  freezes it for the card break, and losing three customers ends it with
//  the marathon report. STOP pauses either.
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
    /// Set while a marathon is being played; levels leave it nil.
    private let marathon: MarathonSession?
    /// What shows over a finished marathon round.
    @State private var marathonStep: MarathonStep?
    @State private var isPaused = false
    @State private var showSettings = false
    /// New Tools / New Menu popups still to show before the countdown.
    @State private var introductions: [KitchenIntroduction]
    /// The app left the foreground while the day was running.
    @State private var isInterrupted = false
    /// It went as far as the background: coming back plays a fresh 3-2-1.
    @State private var needsGetReadyOnReturn = false
    @State private var resumeCountdownRequest = 0
    @State private var marathonNewBest = false
    @State private var countdownGeneration = 0

    private var gameplayMusic: String { marathon == nil ? MusicTrack.story : MusicTrack.buffet }

    private var musicRate: Float {
        guard let marathon else { return 1 }
        let spacing = marathon.day.customerSpacing ?? MarathonFlow.startSpacing
        return min(1.5, max(1, Float(sqrt(MarathonFlow.startSpacing / spacing))))
    }

    init(sceneManager: SceneManager, level: LevelData) {
        self.sceneManager = sceneManager
        marathon = sceneManager.marathon
        
        let day = sceneManager.marathon?.day ?? KitchenDay(
            storyLevel: level,
            positionTypes: KitchenLayout.positionTypes,
            pricing: GameStorage.dishPricing,
            tools: KitchenTools(
                for: level,
                ownedPlates: GameStorage.kitchenPlates(on: level.planet),
                ownedGlasses: GameStorage.kitchenGlasses(on: level.planet)
            )
        )
        _day = State(initialValue: day)
        
        let seen = GameStorage.seenIntroductions
        _introductions = State(initialValue: KitchenIntroduction.introduced(byLevel: level.id).filter {
            !seen.contains($0.id)
        })
        
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
                    audio.play(.handFound)
                }
                .designScaled()
            }

            if let marathon, let marathonStep {
                marathonOverlay(marathonStep, of: marathon)
                    .transition(.opacity)
                    .zIndex(200)
            }

            storyReportOverlay
        }
        .onAppear(perform: setUp)
        .onDisappear(perform: tearDown)
        .onChange(of: day.isRunning) { _, running in
            if !running { audio.stopKitchenLoops() }
        }
        .onChange(of: day.timeLeft <= 0) { _, ended in
            if ended, marathon == nil { audio.play(.dayEnd) }
        }
        .onChange(of: day.isOver) { _, isOver in
            if isOver { endDay() }
        }
        .onChange(of: day.isRoundOver) { _, isRoundOver in
            if isRoundOver { startBreak() }
        }
        .onChange(of: day.ordersDelivered) {
            marathon?.refreshTools()
            audio.setMusicRate(musicRate)
        }
        .onChange(of: isClockTicking) { _, isTicking in
            if isTicking { audio.startClockWarning() } else { audio.stopClockWarning() }
        }
        .onChange(of: day.presentCustomers.count) { marathon?.refreshTools() }
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
                isPaused: scenePhase != .active || day.isOver,
                options: [.allowsTransparency, .ignoresSiblingOrder]
            )
            .onAppear { scene.size = proxy.size }
            .onChange(of: proxy.size) { _, newSize in scene.size = newSize }
        }
        .ignoresSafeArea()
    }

    private var dayOverlays: some View {
        ZStack {
            KitchenHUD(day: day, marathon: marathon)
            if let marathon {
                MarathonHUD(session: marathon)
                RedEdgeFlash(losses: marathon.lostCustomers)
            }

            if countdown >= 0, introductions.isEmpty {
                GetReadyOverlay(count: countdown)
                    .ignoresSafeArea()
            }

            if let introduction = introductions.first {
                IntroductionPopup(introduction: introduction) {
                    GameStorage.markIntroductionSeen(introduction.id)
                    // By id: a popup still fading out can be tapped again.
                    introductions.removeAll { $0.id == introduction.id }
                }
                .id(introduction.id)
                .transition(.opacity)
            }

            if handPoseManager.authorizationStatus == .denied
                || handPoseManager.authorizationStatus == .restricted {
                CameraPermissionDeniedOverlay()
            }

            // Gone while paused, so it comes back hidden after RESUME.
            if countdown < 0, !day.isOver, marathonStep == nil, !isPaused {
                pauseButtonLayer
            }

            if isPaused {
                PausePopup(
                    labels: marathon == nil ? .level : .marathon,
                    onResume: resumeDay,
                    onRestart: restartDay,
                    onSettings: { showSettings = true },
                    onHome: sceneManager.goToPlanetSelect
                )
            }

            if showSettings {
                SettingsView(onClose: { showSettings = false })
            }
        }
        // Runs again as each introduction closes; counts down once none are left.
        .task(id: introductions.count) {
            guard introductions.isEmpty, await playGetReadyCountdown(), scenePhase == .active else { return }
            startPlaying()
        }
        .animation(.easeOut(duration: 0.2), value: introductions.count)
        .task(id: resumeCountdownRequest) {
            guard resumeCountdownRequest > 0,
                  await playGetReadyCountdown(),
                  scenePhase == .active, !isPaused else { return }
            startPlaying()
        }
        .designScaled()
    }

    /// Figma "IN GAME if press screen": top right, clear of the HUD along
    /// the bottom.
    private var pauseButtonLayer: some View {
        TapToRevealLayer {
            PauseButton(action: pauseDay)
                .padding(.top, 38)
                .padding(.trailing, 35)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    // MARK: - Lifecycle

    private func setUp() {
        let supply: any BubbleSupply = marathon.map { MarathonBubbleSupply(starters: $0.planet.buffet.starters) }
            ?? StoryBubbleSupply(level: day.level)
        scene.prepare(for: day, bubbleSupply: supply)
        if let marathon { applyUpgrades(of: marathon) }
        scene.handInput = handPoseManager
        scene.audio = audio
        handPoseManager.setDetectionPaused(false)
        handPoseManager.start()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    /// Closes everything this day opened. NEXT and RETRY wait for this (the
    /// handover in SceneManager), so the next day starts from nothing.
    private func tearDown() {
        audio.stopMusic(ifPlaying: gameplayMusic)
        audio.stopClockWarning()
        audio.stopKitchenLoops()
        handPoseManager.releasePlayer()
        UIApplication.shared.isIdleTimerDisabled = false
        // The next kitchen wants the camera straight back, and stopping and
        // restarting it in between takes seconds with Continuity Camera on a
        // Mac. Releasing the player is enough for calibration to start over.
        guard sceneManager.isHandingOverKitchen else {
            handPoseManager.stop()
            return
        }
        // onDisappear runs while SwiftUI is switching screens. Finish the
        // handover after that update so it can mount a fresh kitchen.
        Task { @MainActor [sceneManager] in
            sceneManager.kitchenDidClose()
        }
    }

    /// Plays the 3-2-1-GO! beat. False if it was cut short.
    private func playGetReadyCountdown() async -> Bool {
        let generation = countdownGeneration
        audio.play(.countdown)
        for step in stride(from: 3, through: 0, by: -1) {
            guard generation == countdownGeneration, scenePhase == .active else { return false }
            countdown = step
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return false
            }
        }
        guard generation == countdownGeneration, scenePhase == .active else { return false }
        countdown = -1
        return true
    }

    /// Both reports keep the finished kitchen visible. Income is banked only once.
    private func endDay() {
        guard sceneManager.screen == .kitchen(day.level),
              sceneManager.levelReport == nil, marathonStep != .report else { return }
        day.pause()
        audio.stopMusic(ifPlaying: gameplayMusic)
        audio.stopKitchenLoops()
        handPoseManager.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        if let marathon {
            marathonNewBest = GameStorage.recordMarathon(score: marathon.points, on: marathon.planet.id)
            withAnimation(.easeOut(duration: 0.3)) { marathonStep = .report }
        } else {
            let previousBest = GameStorage.bestStars(forLevel: day.level.id)
            GameStorage.recordDay(onLevel: day.level.id, stars: day.stars, income: day.total)
            withAnimation(.easeOut(duration: 0.3)) {
                sceneManager.showReport(LevelReport(day: day, previousBestStars: previousBest))
            }
        }
    }

    @ViewBuilder
    private var storyReportOverlay: some View {
        if let report = sceneManager.levelReport {
            LevelReportView(
                report: report,
                levelNumber: PlanetCatalog.dayNumber(of: report.level.id) ?? 1,
                onNext: { sceneManager.goToNextLevel(after: report.level) },
                onBack: sceneManager.goToPlanetSelect,
                onRetry: restartDay
            )
            .transition(.opacity)
            .zIndex(200)
        }
    }

    // MARK: - Marathon

    enum MarathonStep { case upgrades, report }

    /// The clock ticks through a marathon round's last seconds, only while
    /// play is running: never under the pause popup or once the round is up.
    private var isClockTicking: Bool {
        day.timeLeft > 0 && day.timeLeft <= MarathonSession.roundEndingWarningSec && day.isRunning
    }

    /// A round's time is up: play freezes and the break's cards come up.
    private func startBreak() {
        guard let marathon, !day.isOver else { return }
        day.pause()
        audio.stopClockWarning()
        audio.stopKitchenLoops()
        marathon.startBreak()
        withAnimation(.easeOut(duration: 0.3)) { marathonStep = .upgrades }
    }

    /// Buys the card picked, if any, puts its upgrade on the grill, and
    /// plays on into the next round where the last one stopped, after a
    /// 3-2-1 so the player can take up anything left hanging.
    private func endBreak(buying card: MarathonCard?) {
        guard let marathon else { return }
        if let card {
            // The overlay only lets an affordable card from the offer be picked.
            do {
                try marathon.buy(card)
                audio.play(.coinSpentBuffet)
            } catch {
                // A stale or unaffordable selection makes no purchase sound.
            }
        }
        applyUpgrades(of: marathon)
        marathon.endBreak()
        withAnimation(.easeOut(duration: 0.3)) { marathonStep = nil }
        resumeCountdownRequest += 1
    }

    /// The marathon's tool cards, on the scene's cooking tools.
    private func applyUpgrades(of marathon: MarathonSession) {
        for (tool, seconds) in marathon.cookSec { scene.cookers[tool]?.cookSec = seconds }
        scene.cookers[.grill]?.growSlots(to: marathon.grillSlots)
    }

    @ViewBuilder
    private func marathonOverlay(_ step: MarathonStep, of marathon: MarathonSession) -> some View {
        switch step {
        case .upgrades:
            RoundCompleteOverlay(session: marathon, onContinue: endBreak(buying:))
        case .report:
            MarathonReportView(isNewBest: marathonNewBest, session: marathon, onNext: sceneManager.goToPlanetSelect)
        }
    }

    private func pauseDay() {
        day.pause()
        isPaused = true
        handPoseManager.setDetectionPaused(true)
        audio.stopClockWarning()
        audio.stopKitchenLoops()
        audio.fadeOutMusic()
    }

    private func resumeDay() {
        isPaused = false
        handPoseManager.setDetectionPaused(false)
        startPlaying()
    }

    /// Starts this level, or the whole marathon, over from its beginning.
    private func restartDay() {
        // The SpriteKit view stays live while the pause menu is open.
        // Stop the outgoing scene before changing screens.
        scene.isPaused = true
        if let marathon {
            sceneManager.startMarathon(on: marathon.planet.id)
        } else {
            sceneManager.goToKitchen(day.level)
        }
    }

    // MARK: - Leaving and returning to the foreground

    /// Hand tracking stops whenever the app isn't active, so the day's clock
    /// stops with it. Back from the background, a fresh 3-2-1 plays first.
    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            guard isInterrupted, !day.isOver else { return }
            isInterrupted = false
            if needsGetReadyOnReturn {
                needsGetReadyOnReturn = false
                resumeCountdownRequest += 1
            } else {
                startPlaying()
            }
        case .background:
            // `.inactive` always comes first and has already paused the day.
            needsGetReadyOnReturn = isInterrupted
        default:
            if countdown >= 0, hasCalibrated, introductions.isEmpty {
                countdownGeneration += 1
                isInterrupted = true
                needsGetReadyOnReturn = true
            }
            if day.isRunning {
                isInterrupted = true
                day.pause()
                audio.stopKitchenLoops()
            }
        }
    }

    private func startPlaying() {
        guard sceneManager.screen == .kitchen(day.level),
              !isPaused, scenePhase == .active else { return }
        day.start()
        audio.startMusic(gameplayMusic)
        audio.setMusicRate(musicRate)
        audio.fadeInMusic()
    }
}
