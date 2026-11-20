//
//  LoseHeartOverlay.swift
//  GetCooking
//
//  Created by Owen Limantoro on 22/08/26.
//
//  The camera game's lost-life warning: the screen's edges blink red.
//

import SwiftUI

struct LoseHeartOverlay: View {
    var gameStateManager: GameStateManager
    @State private var livesLost = 0

    var body: some View {
        RedEdgeFlash(losses: livesLost)
            .onChange(of: gameStateManager.events.latest) { _, entry in
                if case .lifeLost = entry?.event { livesLost += 1 }
            }
    }
}
