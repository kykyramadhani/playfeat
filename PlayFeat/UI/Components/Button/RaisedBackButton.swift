//
//  RaisedBackButton.swift
//  PlayFeat
//  Created by Owen Limantoro on 21/11/26.
//
//  The round pink back button from Figma (node 1950:946): a white back
//  triangle on the START pink, in the same raised style as the pause button.
//

import SwiftUI

struct RaisedBackButton: View {
    let action: () -> Void

    /// The whole button, lip included, and the face above the lip.
    private static let diameter: CGFloat = 93
    private static let faceHeight: CGFloat = 84.14
    private static let triangleSize = CGSize(width: 26.57, height: 46.5)
    /// The design nudges the triangle left of centre (its left edge at 27.9
    /// on the 93-wide face), so it looks centred despite pointing left.
    private static let triangleOffset: CGFloat = 27.9 + 26.57 / 2 - 93 / 2

    var body: some View {
        ClickButton(action: action, sound: .back) {
            Image("BackTriangle")
                .resizable()
                .frame(width: Self.triangleSize.width, height: Self.triangleSize.height)
                .foregroundStyle(RaisedButtonPalette.start.label)
                .offset(x: Self.triangleOffset)
        }
        .buttonStyle(RaisedButtonStyle(palette: .start, lipHeight: Self.diameter - Self.faceHeight))
        .frame(width: Self.diameter, height: Self.diameter)
        .accessibilityLabel(Text("Back"))
    }
}

#Preview {
    RaisedBackButton {}
        .padding()
        .environment(AudioManager())
}
