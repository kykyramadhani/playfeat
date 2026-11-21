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
//  Reports and Buffet overlays keep hand tracking on for their pinch buttons.
//  The manual pause menu suspends detection and uses touch controls.
//

import AVFoundation
import SpriteKit
import SwiftUI

struct KitchenView: View {
    @Environment(AudioManager.self) private var audio
    @Environment(HandPoseManager.self) private var handPoseManager
    /// Forwarded by PlayFeatApp (PhoneSafeSides hosts the app separately).
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(TutorialProgress.alwaysShowKey) private var alwaysShowTutorial = false

    @Bindable var sceneManager: SceneManager

    @State private var day: KitchenDay
    @State private var scene = KitchenScene(size: KitchenLayout.artSize)
    @State private var hasCalibrated = false
    @State private var countdown: GetReadyOverlay.Step? = .ready
    /// Set while a marathon is being played; levels leave it nil.
    private let marathon: MarathonSession?
    /// What shows over a finished marathon round.
    @State private var marathonStep: MarathonStep?
    @State private var isPaused = false
    @State private var showSettings = false
    @State private var showsBuffetRules: Bool
    /// The app left the foreground while the day was running.
    @State private var isInterrupted = false
    /// It went as far as the background: coming back plays a fresh 3-2-1.
    @State private var needsGetReadyOnReturn = false
    @State private var resumeCountdownRequest = 0
    @State private var marathonNewBest = false
    /// The run's points are saved and sent once, however the run ends.
    @State private var isMarathonRunBanked = false
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
            openSeats: KitchenLayout.openSeats(on: level),
            pricing: GameStorage.dishPricing,
            tools: KitchenTools(
                for: level,
                ownedPlates: GameStorage.kitchenPlates(on: level.planet),
                ownedGlasses: GameStorage.kitchenGlasses(on: level.planet)
            )
        )
        _day = State(initialValue: day)
        
        _showsBuffetRules = State(initialValue: marathon != nil)
        
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
                calibrationLayer
            }

            if let marathon, let marathonStep {
                marathonOverlay(marathonStep, of: marathon)
                    .acceptsHandClicks()
                    .transition(.opacity)
                    .zIndex(200)
            }

            storyReportOverlay

            if sceneManager.isShortOfEnergy {
                PlanetNoticePopup(notice: .notEnoughEnergy, onClose: sceneManager.dismissEnergyShortfall)
                    .acceptsHandClicks()
                    .transition(.opacity)
                    .zIndex(300)
            }
        }
        .overlayPreferenceValue(HandClickTargets.self) { targets in
            if !targets.isEmpty {
                HandPointerLayer(targets: targets)
            }
        }
        .onAppear(perform: setUp)
        .onDisappear(perform: tearDown)
        .onChange(of: reduceMotion) { _, enabled in scene.tutorial?.reduceMotion = enabled }
        .onChange(of: alwaysShowTutorial) { _, enabled in scene.tutorial?.alwaysShow = enabled }
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

    /// The seat check, with a way back to where the player came from. The
    /// button sits above the camera-permission card too, so a player who
    /// turned the camera off can still leave.
    private var calibrationLayer: some View {
        ZStack {
            SeatCalibrationView(handPoseManager: handPoseManager) {
                handPoseManager.lockOntoPlayer()
                hasCalibrated = true
                audio.play(.handFound)
            }

            // Figma "Button" (1950:946): top left of the 1366 × 1024 canvas.
            RaisedBackButton(action: leaveBeforePlaying)
                .padding(.top, 45)
                .padding(.leading, 49)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .designScaled()
    }

    /// Back from the seat check: to the Buffet lobby for a marathon, the
    /// planet board for a level. Nothing has been played yet, so nothing is
    /// recorded.
    private func leaveBeforePlaying() {
        if marathon != nil {
            sceneManager.goToMarathon()
        } else {
            sceneManager.goToPlanetSelect()
        }
    }

    private var dayOverlays: some View {
        ZStack {
            KitchenHUD(day: day, marathon: marathon)
            if let marathon {
                MarathonHUD(session: marathon)
                RedEdgeFlash(losses: marathon.lostCustomers)
            }

            if let countdown, !showsBuffetRules {
                GetReadyOverlay(step: countdown)
                    .ignoresSafeArea()
            }

            if showsBuffetRules {
                BuffetRulesCard { showsBuffetRules = false }
                    .acceptsHandClicks()
            }

            if handPoseManager.authorizationStatus == .denied
                || handPoseManager.authorizationStatus == .restricted {
                CameraPermissionDeniedOverlay()
            }

            // Gone while paused, so it comes back hidden after RESUME.
            if countdown == nil, !day.isOver, marathonStep == nil, !isPaused {
                pauseButtonLayer
            }

            if isPaused {
                PausePopup(
                    labels: marathon == nil ? .level : .marathon,
                    onResume: resumeDay,
                    onRestart: restartDay,
                    onSettings: { showSettings = true },
                    onHome: quitToHome
                )
            }

            if showSettings {
                SettingsView(onClose: { showSettings = false })
            }
        }
        .task(id: showsBuffetRules) {
            guard !showsBuffetRules, await playGetReadyCountdown(), scenePhase == .active else { return }
            startPlaying()
        }
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
        let tutorial = KitchenTutorial(levelID: day.level.id, isBuffet: marathon != nil, alwaysShow: alwaysShowTutorial)
        tutorial.reduceMotion = reduceMotion
        scene.installTutorial(tutorial)
        if let marathon { applyUpgrades(of: marathon) }
        scene.handInput = handPoseManager
        scene.audio = audio
        handPoseManager.setDetectionPaused(false)
        handPoseManager.start()
    }

    /// Closes everything this day opened. NEXT and RETRY wait for this (the
    /// handover in SceneManager), so the next day starts from nothing.
    private func tearDown() {
        audio.stopMusic(ifPlaying: gameplayMusic)
        audio.stopClockWarning()
        audio.stopKitchenLoops()
        handPoseManager.releasePlayer()
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

    /// Plays the opening countdown. False if it was cut short.
    private func playGetReadyCountdown() async -> Bool {
        let generation = countdownGeneration
        for step in GetReadyOverlay.Step.allCases {
            guard generation == countdownGeneration, scenePhase == .active else { return false }
            countdown = step
            if step == .three { audio.play(.countdown) }
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return false
            }
        }
        guard generation == countdownGeneration, scenePhase == .active else { return false }
        countdown = nil
        return true
    }

    /// Both reports keep the finished kitchen visible. Income is banked only
    /// once. Hand tracking stays on for the report's buttons, until the
    /// player leaves the kitchen (`tearDown`).
    /// Keeps the run's points as the planet's best if they beat it, and
    /// sends them to the planet's Buffet leaderboard.
    private func bankMarathonRun(_ marathon: MarathonSession) {
        guard !isMarathonRunBanked else { return }
        isMarathonRunBanked = true
        marathonNewBest = GameStorage.recordMarathon(score: marathon.points, on: marathon.planet.id)
        GameCenter.submit(marathon.points, to: GameCenter.buffetLeaderboardID(on: marathon.planet.id))
    }

    /// HOME from the pause card. Leaving a marathon gives the run up: it
    /// ends there, and its points count as if the last customer had left.
    private func quitToHome() {
        if let marathon { bankMarathonRun(marathon) }
        sceneManager.goToPlanetSelect()
    }

    private func endDay() {
        guard sceneManager.screen == .kitchen(day.level),
              sceneManager.levelReport == nil, marathonStep != .report else { return }
        day.pause()
        audio.stopMusic(ifPlaying: gameplayMusic)
        audio.stopKitchenLoops()
        if let marathon {
            bankMarathonRun(marathon)
            withAnimation(.easeOut(duration: 0.3)) { marathonStep = .report }
        } else {
            let previousBest = GameStorage.bestStars(forLevel: day.level.id)
            GameStorage.recordDay(onLevel: day.level.id, stars: day.stars, income: day.total)
            reportAchievements()
            scene.tutorial?.finishLevel(day.level.id, stars: day.stars)
            withAnimation(.easeOut(duration: 0.3)) {
                sceneManager.showReport(LevelReport(day: day, previousBestStars: previousBest))
            }
        }
    }

    /// The story achievements this day earned or kept, now that its stars are saved.
    private func reportAchievements() {
        let dessert = PlanetCatalog.planet(day.level.planet).kitchen.dessert
        let recap = StoryDayRecap(
            stars: day.stars,
            ordersDelivered: day.ordersDelivered, ordersMissed: day.ordersMissed, tips: day.tips,
            angryCustomersServed: day.angryCustomersServed, dessertsServed: day.servedDishes[dessert] ?? 0
        )
        GameCenter.report(StoryAchievement.earned(after: recap, bestStars: GameStorage.bestStars(forLevel:)))
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
            .acceptsHandClicks()
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
            MarathonReportView(
                isNewBest: marathonNewBest,
                session: marathon,
                onBack: sceneManager.goToMarathon,
                onRestart: restartDay
            )
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
            // Starting over gives the run up, so its points still count.
            bankMarathonRun(marathon)
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
            if countdown != nil, hasCalibrated, !showsBuffetRules {
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
        if marathon == nil {
            // The live tutorial replaces the introduction cards. Keep their
            // recipe-book unlocks tied to starting the same story level.
            GameStorage.markIntroductionsSeen(KitchenIntroduction.introduced(byLevel: day.level.id).map(\.id))
        }
        day.start()
        audio.startMusic(gameplayMusic)
        audio.setMusicRate(musicRate)
        audio.fadeInMusic()
    }
}
