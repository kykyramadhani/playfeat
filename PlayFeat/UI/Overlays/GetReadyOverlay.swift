//
//  GetReadyOverlay.swift
//  GetCooking
//
//  The illustrated countdown between passing the seat check and playing.
//
//  Deliberately shown over a live board — camera, plate and HUD all visible
//  behind it — so the player can settle their hands before anything is asked
//  of them.
//

import SwiftUI

struct GetReadyOverlay: View {
    enum Step: String, CaseIterable {
        case ready = "CountdownReady"
        case three = "CountdownThree"
        case two = "CountdownTwo"
        case one = "CountdownOne"
        case start = "CountdownStart"

        var accessibilityLabel: Text {
            switch self {
            case .ready: Text("GET READY!")
            case .three: Text(3, format: .number)
            case .two: Text(2, format: .number)
            case .one: Text(1, format: .number)
            case .start: Text("Start!")
            }
        }
    }

    let step: Step

    var body: some View {
        // The exported 1366 × 1024 artwork includes each word or digit's
        // exact position. Keep the transparent canvas intact at every size.
        Image(step.rawValue)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: DesignCanvas.size.width * 0.5, maxHeight: DesignCanvas.size.height * 0.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(step.accessibilityLabel)
            .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.gray
        GetReadyOverlay(step: .three)
    }
}
