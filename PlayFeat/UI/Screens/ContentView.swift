//
//  ContentView.swift
//  PlayFeat
//
//  Root view: shows whichever AppScreen SceneManager is on, with the
//  loading screen layered above it at launch.
//
//  A plain switch rather than a NavigationStack: every screen is full-screen
//  and each exit jumps to a known screen, so there is no stack to keep.
//

import SwiftUI

struct ContentView: View {
    @Environment(HandPoseManager.self) private var handPoseManager
    @Environment(AudioManager.self) private var audio
    
    @State private var sceneManager = SceneManager()
    /// The loading/START title screen, shown once per launch.
    @State private var showLaunchScreen = true

    /// Watched, not just stored: switching language has to redraw everything
    /// that has already been laid out, and views only rebuild for state they
    /// actually read.
    @AppStorage(AppLocalization.storageKey) private var language: AppLanguage = .english

    /// The music ContentView plays for the screen on show; nil where the
    /// screen plays its own, or none. The first screen is mounted behind the
    /// launch screen, so its presence alone does not mean the player sees it.
    private var screenMusic: String? {
        guard !showLaunchScreen else { return nil }
        switch sceneManager.screen {
        case .introStory: return MusicTrack.story
        case .galaxy, .planetSelect, .marathon: return MusicTrack.menu
        case .kitchen, .kitchenHandover: return nil
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
        .environment(sceneManager.energy)
        .onAppear {
            // Here rather than in the App's init: GameKit's sign-in screen
            // needs a window to be presented from, and there isn't one yet
            // when the App value is built.
            GameCenter.authenticate()

            #if DEBUG
            DebugLaunch.applyLandscapeIfRequested()
            openDebugKitchenIfRequested()
            #endif
        }
        .onChange(of: screenMusic, initial: true) { previousMusic, music in
            if let music {
                audio.startMusic(music)
            } else if let previousMusic {
                audio.stopMusic(ifPlaying: previousMusic)
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

    @ViewBuilder
    private var currentScreen: some View {
        switch sceneManager.screen {
        case .introStory:
            // Held back until the launch screen lifts, so the first panel
            // and its music start together, from the beginning.
            if showLaunchScreen {
                Color.storyInk
                    .ignoresSafeArea()
            } else {
                IntroStoryView(onFinish: sceneManager.finishIntroStory)
                    .transition(.opacity)
            }
        case .galaxy:
            GalaxyMapView(sceneManager: sceneManager)
                .transition(.opacity)
        case .planetSelect:
            PlanetSelectView(sceneManager: sceneManager)
                .transition(.opacity)
        case .marathon:
            MarathonView(sceneManager: sceneManager)
                .transition(.opacity)
        case .kitchen(let level):
            KitchenView(sceneManager: sceneManager, level: level)
                .transition(.opacity)
        case .kitchenHandover:
            Color.black
                .ignoresSafeArea()
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
        .environment(EnergyStore())
        .environment(HandPoseManager())
        .environment(AudioManager())
}
