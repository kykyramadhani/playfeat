//
//  LevelReportView.swift
//  PlayFeat
//  Created by kyky on 15/11/26.
//
//  The card at the end of a story day, shown over the level board: the
//  stars against the level's targets, a recap of orders delivered and
//  missed and tips, and the day's total income. The earned stars light up
//  grey to yellow one by one; each star reports where it sits so the board
//  can fly the new ones to the spaceship's fuel gauge. BACK closes it;
//  a day with a star offers NEXT, one without offers RETRY.
//

import SwiftUI

struct LevelReportView: View {
    let report: LevelReport
    let levelNumber: Int
    let onNext: () -> Void
    let onBack: () -> Void
    let onRetry: () -> Void
    /// Called once every earned star is lit.
    var onStarsLit: () -> Void = {}

    static let firstStarDelay: Duration = .milliseconds(600)
    static let starInterval: Duration = .milliseconds(450)

    @Environment(AudioManager.self) private var audio
    @State private var litStars = 0

    var body: some View {
        ReportPopup(
            title: Text("Level \(levelNumber) Report"),
            rows: [
                .init(count: report.ordersDelivered, label: "Order Delivered", value: report.dishEarnings),
                .init(count: report.ordersMissed, label: "Order Missed", value: -report.pointsLost),
                .init(count: nil, label: "Tips", value: report.tips),
            ],
            totalLabel: "Total Income",
            total: report.total,
            buttons: buttons
        ) {
            stars
        }
        .task { await lightStars() }
    }

    private var stars: some View {
        HStack(spacing: 32) {
            ForEach(report.level.starTargets.indices, id: \.self) { index in
                VStack(spacing: 0) {
                    Image("LevelStar")
                        .resizable()
                        .frame(width: 115, height: 115)
                        .foregroundStyle(index < litStars ? Color.starYellow : Color.starEmpty)
                        .scaleEffect(index < litStars ? 1 : 0.85)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: litStars)
                        .reportingFrame(ofStar: index)
                    Text(report.level.starTargets[index], format: .number)
                        .font(.atkinson(size: 64, weight: .bold))
                        .foregroundStyle(Color.purple900)
                        .frame(height: 72)
                }
                .frame(width: 115)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(report.stars) of 3 stars"))
    }

    private var buttons: [ReportButton] {
        let back = ReportButton(title: "Back", icon: "HomeIcon", palette: .blue, label: .white, action: onBack)
        guard report.stars == 0 else { return [back, .next(onNext)] }
        return [back, .init(title: "Retry", icon: "RestartIcon", palette: .pink, label: .electricPink, action: onRetry)]
    }

    /// Lights the earned stars one at a time, each with a chime.
    private func lightStars() async {
        do {
            try await Task.sleep(for: Self.firstStarDelay)
            for _ in 0..<report.stars {
                litStars += 1
                audio.play(.addPoint)
                try await Task.sleep(for: Self.starInterval)
            }
        } catch {
            return
        }
        onStarsLit()
    }
}

// MARK: - Where the stars are

/// Each report star's frame in the level board's coordinate space.
struct ReportStarFramesKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Reports this star's frame on the level board, for the flight to the fuel gauge.
    func reportingFrame(ofStar index: Int) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ReportStarFramesKey.self,
                    value: [index: proxy.frame(in: .named(PlanetSelectView.boardSpace))]
                )
            }
        }
    }
}
