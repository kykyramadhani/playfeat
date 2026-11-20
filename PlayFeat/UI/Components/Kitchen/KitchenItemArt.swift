//
//  KitchenItemArt.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  Any planet-kitchen item drawn in SwiftUI, as it looks in a bubble, in its
//  premium look when its ingredient is upgraded. Fits whatever frame the
//  caller gives it.
//

import SwiftUI

struct KitchenItemArt: View {
    let item: String
    /// Ingredients the player has upgraded, which turn their items premium.
    var upgraded: Set<String> = []

    var body: some View {
        Self.trimmedImage(KitchenArt.image(of: item, upgraded: upgraded))
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }

    /// The art without its transparent border, so every item fills its
    /// frame the same way — the raw flatbread, for one, carries a wide margin.
    private static func trimmedImage(_ name: String) -> Image {
        TrimmedArt.image(named: name).map(Image.init(uiImage:)) ?? Image(name)
    }
}
