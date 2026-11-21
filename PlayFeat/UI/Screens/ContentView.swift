//
//  ContentView.swift
//  PlayFeat
//
//  Root view: shows whichever AppScreen SceneManager is on, with onboarding
//  and the splash layered above it.
//
//  A plain switch rather than a NavigationStack: every screen is full-screen
//  with no back button, and each exit jumps to a known screen, so there is no
//  stack to keep. GameStateManager stays inside GameplayView, so every run
//  starts fresh.
//

import SwiftUI

struct ContentView: View {
    @Environment(InventoryManager.self) private var inventory
    @Environment(HandPoseManager.self) private var handPoseManager
    @Environment(AudioManager.self) private var audio
    
    @State private var sceneManager = SceneManager()
    /// The loading/START title screen, shown once per launch.
    @State private var showLaunchScreen = true
    @AppStorage(GameStorage.coinKey) private var coin: Int = 0
    @AppStorage(GameStorage.scoreKey) private var highscore: Int = 0

    /// Watched, not just stored: switching language has to redraw everything
    /// that has already been laid out, and views only rebuild for state they
    /// actually read.
    @AppStorage(AppLocalization.storageKey) private var language: AppLanguage = .english

    /// The galaxy map is mounted behind the launch screen, so its presence
    /// alone does not mean the player has reached the planet selector.
    private var showsMenuMusicScreen: Bool {
        guard !showLaunchScreen else { return false }
        switch sceneManager.screen {
        case .mainMenu, .galaxy, .planetSelect, .marathon, .shop: return true
        case .gameplay, .kitchen, .kitchenHandover, .postGame: return false
        }
    }

    var body: some View {
        ZStack {
            currentScreen
                .tint(.appSecondaryText)

            #if DEBUG
            HandSkeletonView(handPoseManager: handPoseManager)
            BodySkeletonView(handPoseManager: handPoseManager)
            #endif

            if showLaunchScreen {
                LaunchView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showLaunchScreen = false
                    }
                }
                .transition(.opacity)
                .zIndex(75)
            }

        }
        // Inside the language handling below, so the prompt follows the
        // in-game language like every other piece of text.
        .requiresLandscape()
        // Rebuilds the whole tree when the language changes. Redirecting the
        // bundle is not enough on its own: views already on screen keep the
        // text they resolved when they were built, so they have to be thrown
        // away and made again.
        .id(language)
        .environment(\.locale, language.locale)
        .onAppear {
            // Here rather than in the App's init: GameKit's sign-in screen
            // needs a window to be presented from, and there isn't one yet
            // when the App value is built.
            GameCenter.authenticate()

            #if DEBUG
            DebugLaunch.applyLandscapeIfRequested()
            if DebugLaunch.skipToGameplay {
                showLaunchScreen = false
                sceneManager.finishTutorial()
                sceneManager.play()
            }
            openDebugKitchenIfRequested()
            #endif
        }
        .onChange(of: showsMenuMusicScreen, initial: true) { _, shouldPlay in
            if shouldPlay {
                audio.startMusic(MusicTrack.menu)
            } else {
                audio.stopMusic(ifPlaying: MusicTrack.menu)
            }
        }
        .onChange(of: language) { _, newValue in
            AppLocalization.apply(newValue)
        }
        // Remove the outgoing kitchen before mounting the next one. An
        // opacity transition keeps its SpriteView alive during teardown.
        .animation(sceneManager.isHandingOverKitchen ? nil : .easeInOut(duration: 0.3),
                   value: sceneManager.screen)
    }

    /// The camera preview lives inside GameplayView, as that screen's
    /// backmost layer. The capture *session* is owned by HandPoseManager, so
    /// mounting the preview there doesn't rebuild the pipeline.
    @ViewBuilder
    private var currentScreen: some View {
        switch sceneManager.screen {
        case .mainMenu:
            GameOpening(sceneManager: sceneManager)
                .transition(.opacity)
        case .galaxy:
            GalaxyMapView(sceneManager: sceneManager)
                .transition(.opacity)
        case .planetSelect:
            PlanetSelectView(sceneManager: sceneManager)
                .transition(.opacity)
        case .marathon:
            MarathonView(sceneManager: sceneManager)
                .transition(.opacity)
        case .shop:
            ShopView(sceneManager: sceneManager)
                .transition(.opacity)
        case .gameplay:
            GameplayView(
                sceneManager: sceneManager,
                handPoseManager: handPoseManager,
                inventory: inventory,
                audio: audio
            )
            .transition(.opacity)
        case .kitchen(let level):
            KitchenView(sceneManager: sceneManager, level: level)
                .transition(.opacity)
        case .kitchenHandover:
            Color.black
                .ignoresSafeArea()
                .transition(.opacity)
        case .postGame(let result):
            PostGameView(result: result, sceneManager: sceneManager)
                .transition(.opacity)
        }
    }

    #if DEBUG
    /// `-debugLevel` / `-debugBuffet`: straight into a planet kitchen, so a
    /// day can be played before any screen leads to it.
    private func openDebugKitchenIfRequested() {
        if let levelID = DebugLaunch.levelID {
            do {
                let level = try LevelLoader.load(levelID)
                showLaunchScreen = false
                sceneManager.goToKitchen(level)
            } catch {
                print("[debug] -debugLevel \(levelID) failed to load: \(error)")
            }
        } else if let planet = DebugLaunch.buffetPlanet {
            showLaunchScreen = false
            sceneManager.startMarathon(on: planet)
        }
    }
    #endif
}

#Preview {
    ContentView()
        .environment(InventoryManager(inMemory: true))
        .environment(HandPoseManager())
        .environment(AudioManager())
}
