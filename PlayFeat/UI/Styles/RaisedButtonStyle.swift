//
//  RaisedButtonStyle.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  The chunky "Sunrise" button: a pale face sitting on a darker lip, so it
//  reads as something to press from across the room. Pressing sinks the face
//  halfway onto its lip.
//

import SwiftUI

struct RaisedButtonStyle: ButtonStyle {
    let palette: RaisedButtonPalette
    /// How much of the lip shows below the face, in points.
    let lipHeight: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Texture under the label, so the crayon marks never cross the text.
            .background {
                Capsule().fill(palette.face).paperTexture(clippedTo: Capsule())
            }
            .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 3))
            .offset(y: configuration.isPressed ? lipHeight / 2 : 0)
            .padding(.bottom, lipHeight)
            .background(palette.lip, in: Capsule())
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

enum RaisedButtonPalette {
    case pink
    case yellow
    case cyan
    /// Cyan face on a deep blue lip, white label (the report's BACK).
    case blue
    /// Green buy button in the shop.
    case green
    /// The shop's buy button when the player can't afford it.
    case greenDisabled
    case start
    case startDisabled

    var face: Color {
        switch self {
        case .pink: .white
        case .yellow: .starYellow
        case .cyan: .galacticCyanLight
        case .blue: .galacticCyan
        case .green: .green500
        case .greenDisabled: .green100
        case .start: .electricPink
        case .startDisabled: .disabledButtonFace
        }
    }

    /// Text and icons drawn on the face.
    var label: Color {
        switch self {
        case .pink, .yellow, .cyan: .purple900
        case .start, .blue, .green: .white
        case .greenDisabled: .disabledPriceText
        case .startDisabled: .disabledButtonText
        }
    }

    var lip: Color {
        switch self {
        case .pink: .nebulaPink
        case .yellow: .solarOrange
        case .cyan: .galacticCyan
        case .blue: .cosmicBlue
        case .green: .green500Lip
        case .greenDisabled: .green100Lip
        case .start: .startLip
        case .startDisabled: .startLipDisabled
        }
    }
}

#Preview {
    Button {} label: {
        Text(verbatim: "START")
            .font(.atkinson(size: 32, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
    }
    .buttonStyle(RaisedButtonStyle(palette: .start, lipHeight: 12.67))
    .frame(width: 160, height: 76)
}
