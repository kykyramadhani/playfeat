//
//  NoticeCard.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  The small Sunrise popup: a screwed-on purple frame 795 wide around a
//  lilac card. The planet notices, the pause popups and the new-planet
//  popup are all built on it; the caller fills the card.
//

import SwiftUI

struct NoticeCard<Content: View>: View {
    /// Purple frame showing under the card; the designs vary it a little.
    var bottomMargin: CGFloat = 31
    @ViewBuilder let content: Content

    // Computed: a generic type can't store statics.
    private static var cornerRadius: CGFloat { 39.2 }

    var body: some View {
        content
            .frame(width: 713)
            .background {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(
                        Color.purple50
                            .shadow(.inner(color: .black.opacity(0.37), radius: 1.7, y: -3.4))
                            .shadow(.inner(color: .black.opacity(0.39), radius: 1, y: 3.4))
                    )
            }
            .padding(.top, 31)
            .padding(.bottom, bottomMargin)
            .frame(width: 795)
            .boardPanelBackground(cornerRadius: Self.cornerRadius)
            .overlay { PopupScrews(size: 20.3, inset: 20.3) }
    }
}

/// A screw in each corner of a popup frame.
struct PopupScrews: View {
    let size: CGFloat
    let inset: CGFloat

    private static let corners: [Alignment] = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]

    var body: some View {
        ZStack {
            ForEach(Self.corners.indices, id: \.self) { index in
                Image("PopupScrew")
                    .resizable()
                    .frame(width: size, height: size)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Self.corners[index])
            }
        }
        .padding(inset)
        .accessibilityHidden(true)
    }
}

/// The tilted magenta plaque hanging over a popup's top edge.
struct TiltedTitleBadge: View {
    let title: Text

    var body: some View {
        title
            .font(.atkinson(size: 42.8, weight: .bold))
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .frame(width: 477, height: 107)
            .background {
                RoundedRectangle(cornerRadius: 25.7)
                    .fill(
                        Color.toggleSelected
                            .shadow(.inner(color: .black.opacity(0.25), radius: 2.1, y: 3.2))
                            .shadow(.inner(color: .black.opacity(0.25), radius: 2.1, y: -7.5))
                    )
            }
            .rotationEffect(.degrees(-0.73))
            .accessibilityAddTraits(.isHeader)
    }
}

/// A white pill button with a pink label and icon, as on the pause and
/// new-planet popups.
struct NoticeButton: View {
    let title: LocalizedStringKey
    let icon: String
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        ClickButton(action: action) {
            HStack(spacing: 11.8) {
                Text(title)
                    .font(.atkinson(size: 28, weight: .bold))
                    .tracking(0.56)
                    .textCase(.uppercase)
                    .shadow(color: .black.opacity(0.15), radius: 0, y: 3)
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
            }
            .foregroundStyle(Color.electricPink)
        }
        .buttonStyle(RaisedButtonStyle(palette: .pink, lipHeight: 14.8))
        .frame(width: width, height: 88.6)
    }
}

#Preview {
    NoticeCard(bottomMargin: 44) {
        Text(verbatim: "You have to finish all six levels to continue to the next planet")
            .padding(48)
    }
    .environment(AudioManager())
}
