//
//  LocalizationTests.swift
//  PlayFeatTests
//
//  Split out of GetCookingTests.swift (created by Kyky on 11/08/26).
//

import Testing
import Foundation
import CoreGraphics
import SwiftUI
@testable import PlayFeat

/// The in-app language picker. Writing the preference is not enough on its
/// own — something has to point the bundle at the chosen strings, which is
/// the bug this suite exists to catch.
@MainActor
struct LocalizationTests {

    /// Every language the picker offers has to have strings compiled into the
    /// app. A missing `.lproj` is why a picker silently does nothing.
    @Test func everyOfferedLanguageIsBuiltIntoTheApp() {
        for language in AppLanguage.allCases {
            // English is the development language and lives in the base
            // localization, so it has no separate .lproj to find.
            guard language != .english else { continue }

            #expect(
                Bundle.main.path(forResource: language.code, ofType: "lproj") != nil,
                "no compiled strings for \(language.code) — the picker cannot switch to it"
            )
        }
    }

    /// `CFBundleLocalizations` is what the system reads when it decides which
    /// language to launch the app in, so it has to list real language
    /// identifiers — the same ones the `.lproj` folders are named after. It
    /// shipped once saying "indonesia", which is the enum case's name and
    /// matches nothing.
    @Test func declaredLocalizationsUseRealLanguageCodes() throws {
        let declared = try #require(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleLocalizations") as? [String]
        )

        for language in AppLanguage.allCases {
            #expect(declared.contains(language.code),
                    "Info.plist does not declare \(language.code)")
        }
    }

    /// The actual switch: after applying Indonesian, a known catalog string
    /// has to come back translated rather than in English.
    @Test func applyingALanguageChangesWhatStringsResolveTo() {
        let key: String.LocalizationValue = "Skip Story"
        defer { AppLocalization.apply(.english) }

        AppLocalization.apply(.indonesia)
        let indonesian = AppLocalization.string(key)

        AppLocalization.apply(.english)
        let english = AppLocalization.string(key)

        #expect(indonesian != english, "the bundle redirect is not taking effect")
        #expect(indonesian == "Lewati Cerita")
    }

    /// The intro story reads its captions outside the view tree, so they have
    /// to follow the picker too — this is the path that would otherwise stay
    /// English.
    @Test func introStoryCaptionsFollowTheChosenLanguage() throws {
        defer { AppLocalization.apply(.english) }
        let caption = try #require(IntroStoryPanel.all.first).caption

        AppLocalization.apply(.indonesia)
        let indonesian = AppLocalization.string(caption)

        AppLocalization.apply(.english)
        let english = AppLocalization.string(caption)

        #expect(indonesian != english)
    }

    /// Every screen the player reported as still-English: the settings
    /// sheet, the seat check, the planet board and the kitchen. Each of
    /// these keys existed in the catalog (Xcode's extractor found the
    /// literal) but had never actually been given an Indonesian value — the
    /// bundle redirect had nothing to redirect *to*, so it silently fell back
    /// to the English source text. This is the regression test for that: a
    /// key present but untranslated is exactly as broken as a key that is
    /// missing outright, and this fails either way.
    @Test func everyUserFacingScreenHasIndonesianTranslations() {
        let keys: [String.LocalizationValue] = [
            // Settings sheet
            "Music", "Sound Effects", "Language", "One-hand Mode", "OFF", "ON",
            "Left Hand", "Right Hand", "Pickup Gesture", "Pinch", "F Pinch",
            // Seat check
            "Adjust your seat to fit in the frame",
            "Adjust your seat and raise your left hand",
            "Adjust your seat and raise your right hand",
            "Dishes Served", "Shop",
            // Launch screen and planet board
            "Start", "Buffet Mode", "Energy", "Coins", "Fuel", "Settings", "Help",
            "Recipe Book", "Galaxy Map",
            // Level popup and marathon screen
            "Play", "Close", "Story Mode", "Highest Score", "Leaderboard",
            "It’s a little empty here...", "You",
            // Planet kitchen
            "Time Left", "Tips",
            // Settings, level report, recipe book, introductions, shop
            "One Hand Mode", "Recap", "Order Delivered", "Order Missed", "Total Income",
            "Next", "Back", "Retry", "Recipe", "Description", "How to Cook", "Locked",
            "Play a level to discover new recipes!", "Used In",
            "Raw Flatbread", "Pepper", "Mushroom", "Tentacle", "Slime",
            "Baked Flatbread", "Pepper Flatbread", "Mushroom Flatbread", "Slimy Tentacles",
            "New Tools", "New Menu", "Sun Grill", "Glass", "Max",
            "Desserts are put together in the glass.",
            "Bake a flatbread on the grill, put it on the plate, then add a pepper.",
            "Bake a flatbread on the grill, put it on the plate, then add a mushroom.",
            "Put a tentacle in the glass, then pour green slime over it.",
            // Planet 2 introductions and recipe book
            "Pot", "Noodle Bowl", "Cookie Plate",
            "Coral Noodles", "Urchin Noodles", "Clam Noodles", "Star Cookie", "Boiled Noodles", "Grilled Clam",
            "Tide Noodles", "Coral Leaf", "Bubble Urchin", "Lantern Clam", "Sea Cookie", "Starfish Sugar",
            "Boil the noodles in the pot before they go in the bowl.",
            "Noodle dishes are put together in the bowl.",
            "The Star Cookie is put together on the cookie plate.",
            "Boil noodles in the pot, put them in the bowl, then add a coral leaf.",
            "Boil noodles in the pot, put them in the bowl, then add a bubble urchin.",
            "Boil noodles, put them in the bowl, then grill a lantern clam and add it.",
            "Put a sea cookie on the cookie plate, then add starfish sugar on top.",
            // Recipe book descriptions
            "Ooh, that smells like bread—hold on, I actually made bread!",
            "Mmm… hoo, hoo, HOT—why did I take such a big bite?",
            "Whoa, even with the bread on top I can still see the mushrooms glowing!",
            "Eww, it wobbles when I move the glass—wait, let me do that again.",
            "Oop, it folded over my hand like a tiny blanket.",
            "Phew, my nose is tingling and I haven’t even bitten it yet!",
            "Oooh, look at you glowing in my cupboard like a tiny night-light!",
            "Ah!—oh, that’s my own hand making it wave.",
            "Eugh, it went ‘blorp’—I wonder if it’ll do that again.",
            "Slurp—hold on, am I still eating the same noodle?",
            "Ooh, it opened up—hello in there, you smell surprisingly good!",
            "Crunch! Oh, that was the coral—I was worried I’d eaten a bit of the bowl.",
            "Pop! Hehe, I’m trying to eat quietly but the bubbles aren’t helping.",
            "Mmm… I ate the clam first and now I’m checking its shell for bonus noodles.",
            "Ooh, a cookie covered in tiny stars—I’m going to eat a constellation!",
            "Huh, I tried to untangle these and somehow made a smaller, tighter tangle.",
            "Crunch, crunch… ooh, I can hear myself eating inside my helmet!",
            "Ooh, bubbles—I’ll poke just one before we start cooking… okay, two.",
            "Whoa, look inside—it’s like a tiny lunchbox someone packed for me!",
            "Sniff, sniff… smells like a cookie, looks like a sand dollar, going in my mouth.",
            "Aww, tiny stars—I’ve spent so long arranging them that I forgot to taste one!",
            // Marathon rounds, pause and report
            "Continue", "Faster Grill I", "Faster Pot", "Boil time 6 s → 4.5 s", "Second Grill Spot", "Cozy Seats", "Golden Flatbread", "Round Pause",
            "Resume", "Restart Buffet", "Home", "Nothing left to buy. Take a breather.",
            "Grill holds 2 flatbreads at once", "Both flatbreads +6 points", "Buffet Complete", "Total Buffet Points", "Rounds Played",
            "Average Dishes / Round", "Customers Served", "Total Points",
            "Choose 1 upgrade for the next round, or skip to save your coins.", "Buffet Coins",
            "Game Pause", "Resume Level", "Retry Level", "Pause",
            // Marathon HUD
            "Round %lld", "Customers Lost", "%lld of %lld",
            // Notices and the new planet
            "Complete previous level to unlock this level", "Complete the first level to unlock Buffet mode",
            "You have to finish all six levels to continue to the next planet",
            "One energy comes back every 5 minutes", "Not enough energy. One comes back every 5 minutes",
            "Congratulations!!", "You’ve unlocked a new planet", "Proceed to Planet",
            // Level board, shop, marathon warning
            "Back to Galaxy", "Ingredients", "Tools",
            // Intro story
            "Skip Story", "Tap anywhere to continue", "Tap anywhere to start",
            "Buffet is open! Heads up: it serves dishes and customers you haven't met yet in the story. It can be hard, so have fun and learn as you go.",
        ]

        defer { AppLocalization.apply(.english) }
        AppLocalization.apply(.indonesia)

        for key in keys + IntroStoryPanel.all.map(\.caption) {
            let indonesian = AppLocalization.string(key)
            let english = String(localized: key)
            #expect(indonesian != english, "\"\(english)\" has no Indonesian translation")
        }
    }
}
