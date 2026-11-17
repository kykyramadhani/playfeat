//
//  MarathonOverlays.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  What shows over the kitchen in a marathon: the break between rounds,
//  with one upgrade card to pick (and a countdown that moves on by itself),
//  and the end-of-run report. Its pause card is the shared PausePopup.
//

import SwiftUI

// MARK: - Round complete

/// The break after a marathon round: pick one of the cards on offer that
/// the marathon coins cover, or none to save them. A countdown moves on by
/// itself, buying whatever is picked.
struct RoundCompleteOverlay: View {
    let session: MarathonSession
    /// The card picked; nil when the player skipped.
    let onContinue: (MarathonCard?) -> Void

    @State private var picked: MarathonCard?
    @State private var secondsLeft = MarathonSession.breakSec

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: 40) {
                VStack(alignment: .trailing, spacing: 32) {
                    header
                    HStack(spacing: 32) {
                        ForEach(session.offer, id: \.self) { card in
                            cardView(for: card)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                RaisedTextButton(title: "Continue", palette: .start) { onContinue(picked) }
                    .fixedSize()
            }
            .frame(width: 1181)
            .padding(.top, 280)
        }
        .designScaled()
        .task { await countDown() }
    }

    private var header: some View {
        HStack(spacing: 6) {
            HStack(spacing: 24) {
                CountdownRing(secondsLeft: secondsLeft, total: MarathonSession.breakSec)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Round \(session.round) Complete!")
                        .font(.atkinson(size: 32, weight: .bold))
                        .tracking(0.64)
                        .textCase(.uppercase)
                    Text(session.offer.isEmpty ? "Nothing left to buy. Take a breather."
                        : "Choose 1 upgrade for the next round, or skip to save your coins.")
                        .font(.atkinson(size: 20, weight: .regular))
                        .tracking(0.4)
                }
                .foregroundStyle(.white)
                .frame(width: 726, alignment: .leading)
            }
            MarathonCoinsPill(coins: coinsLeft)
        }
    }

    private func cardView(for card: MarathonCard) -> some View {
        let isPicked = picked == card
        return MarathonUpgradeCard(
            card: card,
            isSelected: isPicked,
            canAfford: isPicked || session.coins >= card.price
        ) {
            picked = isPicked ? nil : card
        }
    }

    /// The coins still free once the picked card is paid for.
    private var coinsLeft: Int {
        session.coins - (picked?.price ?? 0)
    }

    /// Ticks down once a second, then moves on with whatever is picked.
    private func countDown() async {
        while secondsLeft > 0 {
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
            secondsLeft -= 1
        }
        onContinue(picked)
    }
}

/// "50 marathon coins" on a cream pill, the coin overlapping its left end.
private struct MarathonCoinsPill: View {
    let coins: Int

    var body: some View {
        ZStack(alignment: .topLeading) {
            label
                .frame(width: 265, height: 51)
                .background(Color.neutralElevated, in: RoundedRectangle(cornerRadius: 21.8))
                .overlay(RoundedRectangle(cornerRadius: 21.8).strokeBorder(.white.opacity(0.5), lineWidth: 1.3))
                .shadow(color: .black.opacity(0.2), radius: 0, y: 1.4)
                .offset(x: 34.9, y: 10.6)
            Image("HUDCoinsIcon")
                .resizable()
                .frame(width: 73, height: 69)
        }
        .frame(width: 300, height: 70, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }

    private var label: some View {
        Text("\(Text(coins, format: .number).font(.atkinson(size: 24, weight: .bold))) marathon coins")
            .font(.atkinson(size: 24, weight: .regular))
            .tracking(0.48)
            .foregroundStyle(Color.purple900)
            .offset(x: 10.6)
    }
}

/// The white ring round the seconds left to choose, emptying as they run out.
private struct CountdownRing: View {
    let secondsLeft: Int
    let total: Int

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.3), lineWidth: 12)
            Circle()
                .trim(from: 0, to: CGFloat(secondsLeft) / CGFloat(max(total, 1)))
                .stroke(Color.green500, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: secondsLeft)
            Text(secondsLeft, format: .number)
                .font(.atkinson(size: 32, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(6)
        .frame(width: 112, height: 112)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(secondsLeft) seconds left"))
    }
}

/// One upgrade on offer: its icon, name, what it changes, and its price in
/// marathon coins. Picked, it turns white with a green rim.
struct MarathonUpgradeCard: View {
    let card: MarathonCard
    let isSelected: Bool
    let canAfford: Bool
    let action: () -> Void

    private static let shape = RoundedRectangle(cornerRadius: 31.1)

    var body: some View {
        ClickButton(action: action) {
            VStack(spacing: 7.9) {
                Image("EnergyIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 111, height: 111)
                VStack(spacing: 0) {
                    Text(card.name)
                        .font(.atkinson(size: 24, weight: .bold))
                        .tracking(0.48)
                        .frame(height: 39.7)
                    Text(card.effectText)
                        .font(.atkinson(size: 20, weight: .regular))
                        .tracking(0.4)
                        .frame(height: 39.7)
                    price
                }
            }
            .foregroundStyle(Color.purple900)
            .multilineTextAlignment(.center)
            .frame(width: 372.2, height: 266.6)
            .background {
                Self.shape.fill(
                    (isSelected ? Color.white : Color.purple50)
                        .shadow(.inner(color: .black.opacity(0.37), radius: 1.35, y: -2.7))
                        .shadow(.inner(color: .black.opacity(0.39), radius: 0.8, y: 2.7))
                )
            }
            .overlay {
                if isSelected { Self.shape.strokeBorder(Color.green300, lineWidth: 11) }
            }
            .opacity(canAfford ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!canAfford)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var price: some View {
        HStack(spacing: 0) {
            Image("CoinsIcon")
                .resizable()
                .frame(width: 34, height: 34)
            Text(card.price, format: .number)
                .font(.atkinson(size: 24, weight: .bold))
                .tracking(0.48)
                .shadow(color: .black.opacity(0.15), radius: 0, y: 1.4)
        }
    }
}

extension MarathonCard {
    var name: LocalizedStringResource {
        switch self {
        case .fasterGrill1: "Faster Grill I"
        case .fasterGrill2: "Faster Grill II"
        case .secondGrillSpot: "Second Grill Spot"
        case .cozySeats: "Cozy Seats"
        case .blazingPepper: "Blazing Pepper"
        case .royalMushroom: "Royal Glowy Mushroom"
        case .doubleTentacle: "Double Tentacle"
        case .slimierSlime: "Extra Slimy Slime"
        case .goldenFlatbread: "Golden Flatbread"
        }
    }

    /// What buying it changes, as the prototype words it.
    var effectText: LocalizedStringResource {
        switch self {
        case .fasterGrill1: "Bake time 6 s → 4.5 s"
        case .fasterGrill2: "Bake time 4.5 s → 3 s"
        case .secondGrillSpot: "Grill holds 2 flatbreads at once"
        case .cozySeats: "New customers wait \(20)% longer"
        case .blazingPepper: "Pepper Flatbread 20 → 28 points"
        case .royalMushroom: "Mushroom Flatbread 25 → 34 points"
        case .doubleTentacle, .slimierSlime: "Slimy Tentacles 15 → 22 points"
        case .goldenFlatbread: "Both flatbreads +6 points"
        }
    }
}

// MARK: - Report

struct MarathonReportView: View {
    let session: MarathonSession
    let onNext: () -> Void

    var body: some View {
        ReportPopup(
            title: Text("Marathon Complete"),
            rows: [
                .init(count: nil, label: "Rounds Played", value: session.roundsPlayed),
                .init(count: nil, label: "Average Dishes / Round", value: session.averageDishesPerRound),
                .init(count: nil, label: "Customers Served", value: session.dishesServed),
            ],
            totalLabel: "Total Points",
            total: session.coinsEarned,
            buttons: [.next(onNext)]
        ) {
            VStack(spacing: 18) {
                Text("Total Marathon Points")
                    .font(.atkinson(size: 32, weight: .bold))
                    .textCase(.uppercase)
                Text(session.points, format: .number)
                    .font(.atkinson(size: 64, weight: .bold))
            }
            .foregroundStyle(Color.purple900)
            .frame(height: 187)
        }
    }
}
