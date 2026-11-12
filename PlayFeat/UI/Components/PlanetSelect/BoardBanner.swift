//
//  BoardBanner.swift
//  PlayFeat
//  Created by kyky on 11/11/26.
//
//  The lime title plaque that sits on top of a purple board, plus the
//  board's own textured purple fill.
//

import SwiftUI

struct BoardBanner: View {
    let title: Text

    /// How far the banner hangs down over the board under it.
    static let overlap: CGFloat = 50

    var body: some View {
        Image("PlanetNameBanner")
            .resizable()
            .frame(width: 336, height: 112)
            .overlay {
                title
                    .font(.atkinson(size: 32, weight: .bold))
                    .tracking(0.64)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.purple900)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
    }
}

extension View {
    /// The crayon-textured purple of the boards and the level popup.
    func boardPanelBackground(cornerRadius: CGFloat) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.levelPanel)
                .paperTexture(clippedTo: RoundedRectangle(cornerRadius: cornerRadius), opacity: 0.67)
        }
    }
}

#Preview {
    BoardBanner(title: Text("Leaderboard"))
}
