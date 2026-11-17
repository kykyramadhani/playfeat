//
//  RaisedIconButton.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  A round RaisedButtonStyle button holding one picture icon. The caller
//  sets the size with `.frame`; the icon and lip scale with it, matching the
//  Figma proportions at every size.
//

import SwiftUI

struct RaisedIconButton: View {
    let icon: String
    let label: LocalizedStringKey
    let palette: RaisedButtonPalette
    let action: () -> Void

    private static let iconShare: CGFloat = 0.69
    private static let lipShare: CGFloat = 0.095

    var body: some View {
        GeometryReader { proxy in
            let diameter = proxy.size.height

            ClickButton(action: action) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: diameter * Self.iconShare, height: diameter * Self.iconShare)
            }
            .buttonStyle(RaisedButtonStyle(palette: palette, lipHeight: diameter * Self.lipShare))
            .accessibilityLabel(Text(label))
        }
    }
}

#Preview {
    RaisedIconButton(icon: "ShopIcon", label: "Shop", palette: .pink) {}
        .frame(width: 109, height: 109)
        .environment(AudioManager())
}
