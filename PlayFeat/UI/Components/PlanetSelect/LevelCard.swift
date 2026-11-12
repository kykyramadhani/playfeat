//
//  LevelCard.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  One level on the planet board: a screwed-on purple plate with the
//  level's number and its best stars. A locked level is drawn in grey.
//

import SwiftUI

struct LevelCard: View {
    let number: Int
    let stars: Int
    let isLocked: Bool

    private static let size = CGSize(width: 208.5, height: 134.9)
    private static let starSize: CGFloat = 53
    private static let maxStars = 3

    var body: some View {
        RoundedRectangle(cornerRadius: 11.6)
            .fill(isLocked ? Color.levelLocked : Color.purple300)
            .paperTexture(clippedTo: RoundedRectangle(cornerRadius: 11.6))
            .overlay { screws }
            .overlay { face }
            .frame(width: Self.size.width, height: Self.size.height)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
    }

    /// The white face with the stars arched over the number.
    private var face: some View {
        RoundedRectangle(cornerRadius: 6.9)
            .fill(.white)
            .frame(width: 188.7, height: 111.3)
            .overlay(alignment: .top) { starRow.padding(.top, 3.8) }
            .overlay {
                Text(verbatim: "\(number)")
                    .font(.atkinson(size: 45, weight: .bold))
                    .foregroundStyle(isLocked ? Color.levelLockedNumber : .black)
                    .offset(y: 27)
            }
    }

    /// The middle star sits higher than its neighbours.
    private var starRow: some View {
        HStack(alignment: .top, spacing: 3.4) {
            ForEach(0..<Self.maxStars, id: \.self) { index in
                Image("LevelStar")
                    .resizable()
                    .frame(width: Self.starSize, height: Self.starSize)
                    .foregroundStyle(isEarned(index) ? Color.starYellow : Color.starEmpty)
                    .padding(.top, index == 1 ? 0 : 16.7)
            }
        }
    }

    private var screws: some View {
        let screw = Image(isLocked ? "LevelScrewLocked" : "LevelScrew")
        let alignments: [Alignment] = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]

        return ZStack {
            ForEach(alignments.indices, id: \.self) { index in
                screw
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignments[index])
            }
        }
        .padding(5.5)
    }

    private func isEarned(_ starIndex: Int) -> Bool {
        !isLocked && starIndex < stars
    }

    private var accessibilityText: Text {
        isLocked
            ? Text("Level \(number), locked")
            : Text("Level \(number), \(stars) stars")
    }
}

#Preview {
    HStack(spacing: 31) {
        LevelCard(number: 3, stars: 2, isLocked: false)
        LevelCard(number: 4, stars: 0, isLocked: true)
    }
    .padding()
    .background(.white)
}
