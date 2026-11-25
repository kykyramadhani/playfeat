//
//  SoundEffects.swift
//  GetCooking
//
//  Created by Owen Limantoro on 22/08/26.
//

import Foundation

// MARK: - Sound catalog

/// Every sound in the game. The raw value is the file name (without extension)
/// exactly as it appears in Resource/Sound.
enum SoundEffect: String, CaseIterable {
    case bubbleGrab      = "bubble_grab"        // pick up an ingredient/item
    case bubblePut       = "bubble_put"         // place an ingredient down
    case clockRunningOut = "sfx_time_warning"   // low-time warning (looping)
    case countdown       = "countdown321"       // start of a round
    case putOrder        = "sfx_serve_ok"        // submit a completed order
    case uiClick         = "sfx_button"         // menu button pressed
    case wrongIngredient = "sfx_wrong_dish"     // a wrong ingredient placed on the plate

    case back = "sfx_back"
    case place = "sfx_place"
    case handFound = "sfx_hand_found"
    case bakeLoop = "sfx_bake_loop"
    case boilingPot = "sfx_boiling_pot"
    case bakeReady = "sfx_bake_ready"
    case bakeWarning = "sfx_bake_warning"
    case bakeBurnt = "sfx_bake_burnt"
    case customerArrive = "sfx_customer_arrive"
    case angryArrive = "sfx_angry_arrive"
    case tip = "sfx_tip"
    case patienceRed = "sfx_patience_red"
    case customerLeaves = "sfx_customer_leaves"
    case dayEnd = "sfx_day_end"
    /// Despite the filename, this belongs to the STORY level report only.
    case storyReport = "sfx_round_over"
    /// Plays when the Buffet final report appears.
    case runOver = "sfx_run_over"
    case star1 = "sfx_star_1"
    case star2 = "sfx_star_2"
    case star3 = "sfx_star_3"
    case noStar = "sfx_no_star"
    case gasCollected = "sfx_gas_collected"
    case hint = "sfx_hint"
    case cardReveal = "sfx_card_reveal"
    case cardPicked = "sfx_card_picked"
    case coinSpentBuffet = "sfx_coin_spent_buffet"
    case unlock = "sfx_unlock"
    case bestScore = "sfx_best_score"
    /// The landed ship's hatch dropping open on the level board.
    case openShip = "sfx_open_ship"

    func resourceURL(in bundle: Bundle = .main) -> URL? {
        for ext in ["wav", "mp3", "m4a", "caf"] {
            if let url = bundle.url(forResource: rawValue, withExtension: ext) { return url }
        }
        return nil
    }

    /// Speed and pitch are independent: x5 must not raise the pitch fivefold.
    var playbackRate: Float {
        switch self {
        case .dayEnd: 5
        case .angryArrive: 2
        default: 1
        }
    }

    /// How many times the sound plays back to back, each at `playbackRate`.
    /// The sped-up day-end and angry-customer cues are too short heard once.
    var repeatCount: Int {
        switch self {
        case .dayEnd: 5
        case .angryArrive: 2
        default: 1
        }
    }

    var gain: Float {
        switch self {
        case .bakeLoop, .boilingPot: 0.16
        case .bakeWarning, .clockRunningOut: 0.35
        case .customerArrive, .angryArrive: 0.6
        default: 0.8
        }
    }

    static func star(_ number: Int) -> SoundEffect {
        switch number {
        case 1: .star1
        case 2: .star2
        default: .star3
        }
    }
}

nonisolated enum MusicTrack {
    static let menu = "bgm_menu"
    static let story = "bgm_story"
    // Only the retained underscore-named track is bundled. No alternate.
    static let buffet = "music_buffet"
}
