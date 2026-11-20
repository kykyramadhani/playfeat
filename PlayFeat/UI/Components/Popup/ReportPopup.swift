//
//  ReportPopup.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  The purple end-of-play card shared by the level report and the marathon
//  report: a tilted title plaque, a header the caller draws (the stars, or
//  the marathon's points), a RECAP box of numbers, a total with coins, and
//  raised buttons hanging off the bottom edge.
//

import SwiftUI

/// One line of a report's recap: an optional "3x" count, a label and a value.
struct ReportRow {
    let count: Int?
    let label: LocalizedStringKey
    let value: Int
}

/// A raised button hanging off the bottom of a report.
struct ReportButton {
    let title: LocalizedStringKey
    let icon: String
    let palette: RaisedButtonPalette
    let label: Color
    let action: () -> Void
    var sound: SoundEffect? = .uiClick

    static func next(_ action: @escaping () -> Void) -> ReportButton {
        ReportButton(title: "Next", icon: "PlayIcon", palette: .pink, label: .electricPink, action: action)
    }
}

struct ReportPopup<Header: View>: View {
    let title: Text
    let rows: [ReportRow]
    let totalLabel: LocalizedStringKey
    let total: Int
    let buttons: [ReportButton]
    @ViewBuilder let header: Header

    // Computed: a generic type can't store statics.
    private static var cardWidth: CGFloat { 765 }
    private static var cardHeight: CGFloat { 876 }
    private static var boxWidth: CGFloat { 571 }
    private static var recapLineHeight: CGFloat { 25.5 }
    /// Drawn at the design's size the buttons hang off a 1024-point screen,
    /// so the whole report is shown a little smaller.
    private static var fitScale: CGFloat { 0.85 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            card
                .padding(.top, 56)
                .overlay(alignment: .top) { TiltedTitleBadge(title: title).padding(.top, 3) }
                .overlay(alignment: .bottom) { buttonRow.offset(y: 59) }
                .scaleEffect(Self.fitScale)
        }
        .designScaled()
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 0) {
            header.padding(.top, 31)
            recap.padding(.top, 31)
            totalBox.padding(.top, 25)
            Spacer(minLength: 0)
        }
        .frame(width: 671, height: 732)
        .background(Color.purple50, in: RoundedRectangle(cornerRadius: 24))
        .padding(.top, 76)
        .frame(width: Self.cardWidth, height: Self.cardHeight, alignment: .top)
        .boardPanelBackground(cornerRadius: 46.3)
        .overlay { PopupScrews(size: 24, inset: 24) }
    }

    /// The RECAP tab over a cream box of the numbers.
    private var recap: some View {
        VStack(spacing: 0) {
            Text("Recap")
                .font(.atkinson(size: 38, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .frame(width: 362, height: 67)
                .background(Color.labelTab, in: UnevenRoundedRectangle(topLeadingRadius: 67, topTrailingRadius: 67))

            VStack(alignment: .trailing, spacing: 28) {
                ForEach(rows.indices, id: \.self) { index in
                    recapRow(rows[index])
                }
            }
            .frame(width: 484)
            .padding(.top, 43)
            .frame(width: Self.boxWidth, height: 227, alignment: .top)
            .creamBox(.recap)
        }
    }

    private func recapRow(_ row: ReportRow) -> some View {
        HStack(spacing: 20) {
            Group {
                if let count = row.count {
                    Text(verbatim: "\(count)x")
                        .font(.atkinson(size: 32, weight: .bold))
                        .foregroundStyle(Color.purple600)
                } else {
                    Color.clear
                }
            }
            .frame(width: 38, alignment: .leading)

            Text(row.label)
                .font(.atkinson(size: 24, weight: .bold))
                .foregroundStyle(Color.purple800)
            Spacer()
            Text(row.value, format: .number)
                .font(.atkinson(size: 40, weight: .bold))
                .foregroundStyle(Color.purple800)
        }
        // The design's tight line height: the big numbers overhang the row
        // rather than pushing the rows apart.
        .frame(height: Self.recapLineHeight)
        .accessibilityElement(children: .combine)
    }

    private var totalBox: some View {
        // Design positions: the label centred on x 156.6, the coins from x 347.6.
        HStack(spacing: 34.4) {
            Text(totalLabel)
                .font(.atkinson(size: 40, weight: .bold))
                .foregroundStyle(Color.purple800)
                .frame(width: 313.2)
            HStack(spacing: 0) {
                Image("CoinsIcon")
                    .resizable()
                    .frame(width: 81, height: 81)
                Text(total, format: .number)
                    .font(.atkinson(size: 50, weight: .bold))
                    .foregroundStyle(Color.purple800)
                    .shadow(color: .black.opacity(0.15), radius: 0, y: 3.3)
                    .frame(minWidth: 112)
            }
        }
        .frame(width: Self.boxWidth, height: 120, alignment: .leading)
        .creamBox(.total)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Title and buttons

    private var buttonRow: some View {
        HStack(spacing: 68) {
            ForEach(buttons.indices, id: \.self) { index in
                reportButton(buttons[index])
            }
        }
    }

    private func reportButton(_ button: ReportButton) -> some View {
        ClickButton(action: button.action, sound: button.sound) {
            HStack(spacing: 11.8) {
                Text(button.title)
                    .font(.atkinson(size: 28, weight: .bold))
                    .tracking(0.56)
                    .textCase(.uppercase)
                Image(button.icon)
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            .foregroundStyle(button.label)
            .shadow(color: .black.opacity(0.15), radius: 0, y: 3)
            .padding(.horizontal, 47)
        }
        .buttonStyle(RaisedButtonStyle(palette: button.palette, lipHeight: 14.8))
        .frame(height: 88.6)
        .fixedSize(horizontal: true, vertical: false)
        .shadow(color: .black.opacity(0.25), radius: 1.5, y: 6)
    }
}

private extension View {
    /// The cream, white-rimmed box the report's numbers sit in.
    /// The drop shadow sits on the box alone, so the text inside stays flat.
    func creamBox(_ box: CreamBox) -> some View {
        let shape = RoundedRectangle(cornerRadius: box.cornerRadius)
        return background {
            shape
                .fill(Color.neutralElevated)
                .paperTexture(clippedTo: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.5), lineWidth: box.rimWidth))
                .compositingGroup()
                .shadow(color: .black.opacity(0.2), radius: 0, y: box.dropHeight)
        }
    }
}

/// The two cream boxes' measurements from the design: the total box is the
/// recap box drawn at about 0.63 scale, rim and drop included.
private struct CreamBox {
    let cornerRadius: CGFloat
    let rimWidth: CGFloat
    let dropHeight: CGFloat

    static let recap = CreamBox(cornerRadius: 63, rimWidth: 3.8, dropHeight: 4.17)
    static let total = CreamBox(cornerRadius: 39.5, rimWidth: 2.38, dropHeight: 2.61)
}
