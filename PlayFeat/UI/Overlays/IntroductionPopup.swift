//
//  IntroductionPopup.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  "New Tools" / "New Menu": the name, picture and a line about something a
//  level brings into the kitchen for the first time.
//

import SwiftUI

struct IntroductionPopup: View {
    let introduction: KitchenIntroduction
    let onClose: () -> Void

    var body: some View {
        SunrisePopupOverlay(title: title, onClose: onClose) {
            VStack(spacing: 30) {
                Text(introduction.name)
                    .font(.atkinson(size: 40, weight: .bold))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.purple800)
                art
                    .frame(width: 224, height: 201)
                Text(introduction.description)
                    .font(.atkinson(size: 32, weight: .bold))
                    .tracking(0.64)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.purple800)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 100)
            .padding(.vertical, 40)
            .sunrisePanel()
        }
    }

    private var title: Text {
        switch introduction.kind {
        case .tool: Text("New Tools")
        case .menu: Text("New Menu")
        }
    }

    @ViewBuilder
    private var art: some View {
        switch introduction.kind {
        case .tool(let image):
            Image(image).resizable().scaledToFit()
        case .menu(let item):
            KitchenItemArt(item: item)
        }
    }
}

#Preview {
    IntroductionPopup(introduction: .sunGrill, onClose: {})
        .environment(AudioManager())
}
