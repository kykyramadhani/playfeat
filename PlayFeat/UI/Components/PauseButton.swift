//
//  PauseButton.swift
//  PlayFeat
//  Created by Owen Limantoro on 19/11/26.
//
//  The round pink pause button shown over a kitchen day. Same 76 pt raised
//  button as the pause card's Settings and Home, so pausing and the card it
//  opens read as one set.
//

import SwiftUI

struct PauseButton: View {
    let action: () -> Void

    private static let diameter: CGFloat = 76

    var body: some View {
        RaisedIconButton(icon: "PauseIcon", label: "Pause", palette: .pink, action: action)
            .foregroundStyle(Color.electricPink)
            .frame(width: Self.diameter, height: Self.diameter)
    }
}

#Preview {
    PauseButton {}
        .padding()
        .environment(AudioManager())
}
