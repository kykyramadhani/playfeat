//
//  LeaderboardList.swift
//  PlayFeat
//  Created by kyky on 11/11/26.
//
//  The ranked rows on the marathon screen's board, or a friendly note when
//  there is nobody to rank yet. The leader's row is drawn a shade darker.
//

import SwiftUI

struct LeaderboardList: View {
    let entries: [LeaderboardEntry]

    var body: some View {
        if entries.isEmpty {
            Text("It’s a little empty here...")
                .font(.atkinson(size: 32, weight: .bold))
                .tracking(0.64)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.emptyStateText)
                .frame(width: 259)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 18) {
                ForEach(entries) { entry in
                    LeaderboardRow(entry: entry)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 42) {
            Text(entry.rank, format: .number)
                .font(.atkinson(size: 40, weight: .bold))
                .frame(width: 34)
            name
                .font(.atkinson(size: 32, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 156, alignment: .leading)
            Text(entry.score, format: .number)
                .font(.atkinson(size: 40, weight: .bold))
                .frame(width: 156)
        }
        .foregroundStyle(Color.purple800)
        .padding(.leading, 19)
        .frame(maxWidth: .infinity, minHeight: 101, alignment: .leading)
        .background(entry.rank == 1 ? Color.purple200 : Color.purple50, in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    private var name: Text {
        entry.isLocalPlayer ? Text("You") : Text(verbatim: entry.name)
    }
}

#Preview {
    LeaderboardList(entries: [
        LeaderboardEntry(rank: 1, name: "Adi", score: 8720, isLocalPlayer: false),
        LeaderboardEntry(rank: 2, name: "Me", score: 7200, isLocalPlayer: true),
    ])
    .frame(width: 512, height: 699)
    .background(.white)
}
