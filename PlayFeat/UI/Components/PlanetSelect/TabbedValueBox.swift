//
//  TabbedValueBox.swift
//  PlayFeat
//  Created by kyky on 11/11/26.
//
//  A cream box holding one value, with a violet tab on top naming it —
//  "KEPLER-186F / LEVEL 1" in the level popup, "HIGHEST SCORE / 7,200" on
//  the marathon screen.
//

import SwiftUI

struct TabbedValueBox: View {
    let tab: Text
    let value: Text
    let metrics: Metrics

    var body: some View {
        VStack(spacing: 0) {
            tab
                .font(.atkinson(size: metrics.tabFontSize, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .frame(width: metrics.tabSize.width, height: metrics.tabSize.height)
                .background(Color.labelTab, in: tabShape)

            value
                .font(.atkinson(size: metrics.valueFontSize, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(Color.purple900)
                .frame(width: metrics.boxSize.width, height: metrics.boxSize.height)
                .background(Color.neutralElevated, in: boxShape)
                .overlay(boxShape.strokeBorder(.white.opacity(0.5), lineWidth: 2.2))
                .shadow(color: .black.opacity(0.2), radius: 0, y: 2.5)
        }
        .accessibilityElement(children: .combine)
    }

    private var tabShape: UnevenRoundedRectangle {
        let radius = metrics.tabSize.height
        return UnevenRoundedRectangle(topLeadingRadius: radius, topTrailingRadius: radius)
    }

    private var boxShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: metrics.boxSize.height * 0.41)
    }
}

extension TabbedValueBox {
    /// The two sizes the designs use; they don't scale from one another.
    struct Metrics {
        let tabSize: CGSize
        let tabFontSize: CGFloat
        let boxSize: CGSize
        let valueFontSize: CGFloat

        static let level = Metrics(
            tabSize: CGSize(width: 227, height: 42), tabFontSize: 24,
            boxSize: CGSize(width: 358, height: 96), valueFontSize: 32
        )
        static let highScore = Metrics(
            tabSize: CGSize(width: 364, height: 54), tabFontSize: 28,
            boxSize: CGSize(width: 471, height: 85), valueFontSize: 42
        )
    }
}

#Preview {
    TabbedValueBox(tab: Text("Highest Score"), value: Text(7200, format: .number), metrics: .highScore)
}
