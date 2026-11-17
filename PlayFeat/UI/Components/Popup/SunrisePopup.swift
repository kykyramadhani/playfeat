//
//  SunrisePopup.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  The purple tray every Sunrise popup sits in — Settings, Recipe, New Tools,
//  New Menu: a lilac well inside a purple frame, a title tab on top, and a
//  handle on each side. Laid out at its Figma size (1040×775); the caller
//  centres it on a design-scaled screen.
//

import SwiftUI

struct SunrisePopup<Content: View>: View {
    let title: Text
    /// Shows the round close button on the frame's top-right corner.
    var onClose: (() -> Void)?
    @ViewBuilder let content: Content

    static var size: CGSize { CGSize(width: 1040, height: 775) }
    private static var frameRect: CGRect { CGRect(x: 42, y: 41.85, width: 956, height: 708) }
    private static var cornerRadius: CGFloat { 47 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            frame
            sideHandle(onLeft: true)
            sideHandle(onLeft: false)
            titleTab
            if let onClose { closeButton(onClose) }
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var frame: some View {
        content
            .frame(width: 891, height: 646, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(
                        Color.purple50
                            .shadow(.inner(color: .black.opacity(0.37), radius: 2, y: -4))
                            .shadow(.inner(color: .black.opacity(0.39), radius: 1.2, y: 4))
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
            .padding(.leading, 32.15)
            .padding(.top, 31.15)
            .frame(width: Self.frameRect.width, height: Self.frameRect.height, alignment: .topLeading)
            .background(Color.levelPanel, in: RoundedRectangle(cornerRadius: Self.cornerRadius))
            .offset(x: Self.frameRect.minX, y: Self.frameRect.minY)
    }

    /// Hangs over the frame's top edge, its text sitting low in the tab.
    private var titleTab: some View {
        title
            .font(.atkinson(size: 40, weight: .bold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .offset(y: 13)
            .frame(width: 342, height: 69.6)
            .background(Color.levelPanel, in: UnevenRoundedRectangle(topLeadingRadius: 69.6, topTrailingRadius: 69.6))
            .offset(x: 348, y: -25)
            .accessibilityAddTraits(.isHeader)
    }

    /// The purple handle on each side, with its three green grip marks.
    private func sideHandle(onLeft: Bool) -> some View {
        let radius: CGFloat = 41.85
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: onLeft ? radius : 0,
            bottomLeadingRadius: onLeft ? radius : 0,
            bottomTrailingRadius: onLeft ? 0 : radius,
            topTrailingRadius: onLeft ? 0 : radius
        )
        return VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule().fill(Color.green300).frame(width: 7.1, height: 42.7)
            }
        }
        .frame(width: 41.85, height: 205.7)
        .background(Color.levelPanel, in: shape)
        .offset(x: onLeft ? 0 : Self.frameRect.maxX, y: 325)
        .accessibilityHidden(true)
    }

    private func closeButton(_ action: @escaping () -> Void) -> some View {
        RaisedIconButton(icon: "CloseIcon", label: "Close", palette: .pink, action: action)
            .frame(width: 76, height: 76)
            .offset(x: Self.frameRect.maxX - 59, y: Self.frameRect.minY - 27)
    }
}

/// A Sunrise popup over the screen: the screen dims behind it and it is
/// scaled to the device like every other screen.
struct SunrisePopupOverlay<Content: View>: View {
    let title: Text
    var onClose: (() -> Void)?
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onClose?() }
            SunrisePopup(title: title, onClose: onClose) { content }
        }
        .designScaled()
    }
}

extension View {
    /// The white sheet most popups put their content on, inset in the lilac well.
    func sunrisePanel() -> some View {
        frame(width: 804, height: 551, alignment: .top)
            .background(.white, in: RoundedRectangle(cornerRadius: 24))
            .padding(.leading, 43.85)
            .padding(.top, 49)
    }
}

#Preview {
    SunrisePopupOverlay(title: Text("Settings"), onClose: {}) {
        Text(verbatim: "Content").sunrisePanel()
    }
    .environment(AudioManager())
}
