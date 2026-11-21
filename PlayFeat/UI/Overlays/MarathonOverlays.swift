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
    @Environment(AudioManager.self) private var audio
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
        .task { audio.play(.cardReveal); await countDown() }
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
            if !isPicked { audio.play(.cardPicked) }
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
        ClickButton(action: action, sound: nil) {
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
        case .fasterPot: "Faster Pot"
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
        case .fasterPot: "Boil time 6 s → 4.5 s"
        }
    }
}

// MARK: - Report

/// The end of a marathon run, as in the design: the total points, a recap
/// of the run and how long it lasted on the left, every upgrade bought on
/// the right, and BACK / RESTART below.
struct MarathonReportView: View {
    @Environment(AudioManager.self) private var audio
    var isNewBest = false
    let session: MarathonSession
    let onBack: () -> Void
    let onRestart: () -> Void

    private static let cardSize = CGSize(width: 1169, height: 816)
    private static let columnWidth: CGFloat = 534
    /// The design's buttons hang off a 1024-point screen, as in ReportPopup.
    private static let fitScale: CGFloat = 0.92

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            card
                .padding(.top, 56)
                .overlay(alignment: .top) { TiltedTitleBadge(title: Text("Marathon Complete")).padding(.top, 3) }
                .overlay(alignment: .bottom) { buttons.offset(y: 59) }
                .scaleEffect(Self.fitScale)
        }
        .designScaled()
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var card: some View {
        HStack(alignment: .top, spacing: 37) {
            VStack(spacing: 0) {
                totalPoints
                recap.padding(.top, 24)
                runDuration.padding(.top, 26)
            }
            .frame(width: Self.columnWidth)
            UpgradesBoughtPanel(cards: session.bought)
        }
        .padding(.top, 40)
        .frame(width: 1078, height: 687, alignment: .top)
        .background(Color.purple50, in: RoundedRectangle(cornerRadius: 24))
        .padding(.top, 70)
        .frame(width: Self.cardSize.width, height: Self.cardSize.height, alignment: .top)
        .boardPanelBackground(cornerRadius: 46.3)
        .overlay { PopupScrews(size: 24, inset: 24) }
    }

    private var totalPoints: some View {
        VStack(spacing: 18) {
            Text("Total Marathon Points")
                .font(.atkinson(size: 32, weight: .bold))
                .textCase(.uppercase)
            Text(session.points, format: .number)
                .font(.atkinson(size: 64, weight: .bold))
        }
        .foregroundStyle(Color.purple900)
    }

    /// The RECAP tab over a cream box of the run's numbers.
    private var recap: some View {
        VStack(spacing: 0) {
            Text("Recap")
                .font(.atkinson(size: 38, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .frame(width: 340, height: 64)
                .background(Color.labelTab, in: UnevenRoundedRectangle(topLeadingRadius: 64, topTrailingRadius: 64))
            VStack(spacing: 22) {
                recapRow("Rounds Played", value: session.roundsPlayed)
                recapRow("Average Wait / Customer", value: Int(session.day.averageWaitSec.rounded()))
                recapRow("Customers Served", value: session.dishesServed)
            }
            .padding(.horizontal, 40)
            .frame(width: Self.columnWidth, height: 207)
            .creamBox(.recap)
        }
    }

    private func recapRow(_ label: LocalizedStringKey, value: Int) -> some View {
        HStack {
            Text(label)
                .font(.atkinson(size: 24, weight: .regular))
            Spacer()
            Text(value, format: .number)
                .font(.atkinson(size: 40, weight: .bold))
        }
        .foregroundStyle(Color.purple800)
        .frame(height: 30)
        .accessibilityElement(children: .combine)
    }

    private var runDuration: some View {
        HStack {
            Text("Buffet Run Duration")
                .font(.atkinson(size: 24, weight: .bold))
            Spacer()
            Image("StopwatchIcon")
                .resizable()
                .frame(width: 40, height: 40)
            Text(Duration.seconds(Int(session.day.elapsed)).formatted(.time(pattern: .minuteSecond)))
                .font(.atkinson(size: 48, weight: .bold))
        }
        .foregroundStyle(Color.purple800)
        .padding(.horizontal, 40)
        .frame(width: Self.columnWidth, height: 113)
        .creamBox(.total)
        .accessibilityElement(children: .combine)
    }

    private var buttons: some View {
        HStack(spacing: 46) {
            ReportButtonView(button: ReportButton(
                title: "Back", icon: "HomeIcon", palette: .blue, label: .white, action: onBack
            ))
            ReportButtonView(button: ReportButton(
                title: "Restart", icon: "RestartIcon", palette: .pink, label: .electricPink, action: onRestart
            ))
        }
        .task {
            audio.play(.runOver)
            if isNewBest {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                audio.play(.bestScore)
            }
        }
    }
}

/// UPGRADE BOUGHT over a scrolling two-column grid of the cards bought.
private struct UpgradesBoughtPanel: View {
    let cards: [MarathonCard]

    private static let columns = Array(repeating: GridItem(.fixed(173), spacing: 22), count: 2)

    var body: some View {
        VStack(spacing: 18) {
            Text("Upgrade Bought")
                .font(.atkinson(size: 24, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(Color.purple900)
            if cards.isEmpty {
                Text("No upgrades this run")
                    .font(.atkinson(size: 20, weight: .regular))
                    .foregroundStyle(Color.purple800)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: Self.columns, spacing: 22) {
                        ForEach(cards, id: \.self) { BoughtUpgradeTile(card: $0) }
                    }
                }
            }
        }
        .padding(.top, 24)
        .frame(width: 430, height: 603)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
    }
}

/// One card bought: its icon, name, effect and price, on a lilac tile.
private struct BoughtUpgradeTile: View {
    let card: MarathonCard

    var body: some View {
        VStack(spacing: 6) {
            Image("EnergyIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
            Text(card.name)
                .font(.atkinson(size: 18, weight: .bold))
            Text(card.effectText)
                .font(.atkinson(size: 11, weight: .regular))
            HStack(spacing: 2) {
                Image("CoinsIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                Text(card.price, format: .number)
                    .font(.atkinson(size: 20, weight: .bold))
            }
        }
        .foregroundStyle(Color.purple900)
        .multilineTextAlignment(.center)
        .padding(10)
        .frame(width: 173, height: 200)
        .background(Color.purple50, in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}
