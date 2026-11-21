//
//  PlanetNoticePopup.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  The short notes that answer a tap on something not open yet, or on a
//  counter: a locked level or marathon, a planet that can't be left yet,
//  the energy and the gas; and the marathon's spoiler warning. A tap
//  anywhere closes it.
//

import SwiftUI

enum PlanetNotice: Equatable {
    case lockedLevel
    case lockedMarathon
    /// The tank is full but some levels are still unplayed.
    case unplayedLevels
    case energy
    /// PLAY, NEXT or RETRY on a level that costs more energy than is left.
    case notEnoughEnergy
    case gas
    /// The marathon serves what the story hasn't shown yet.
    case marathonSpoiler

    var message: Text {
        switch self {
        case .lockedLevel: Text("Complete previous level to unlock this level")
        case .lockedMarathon: Text("Complete the first level to unlock marathon mode")
        case .unplayedLevels: Text("You have to finish all six levels to continue to the next planet")
        case .energy: Text("One energy comes back every 5 minutes")
        case .notEnoughEnergy: Text("Not enough energy. One comes back every 5 minutes")
        case .gas: Text("Collect \(PlanetProgress.starsToLeave) stars to fill the tank for the next planet")
        case .marathonSpoiler:
            Text("Marathon is open! Heads up: it serves dishes and customers you haven't met yet in the story. It can be hard, so have fun and learn as you go.")
        }
    }

    /// The picture over the message; the warnings have none.
    var icon: String? {
        switch self {
        case .energy, .notEnoughEnergy: "EnergyIcon"
        case .gas: "GasCan"
        case .lockedLevel, .lockedMarathon, .unplayedLevels, .marathonSpoiler: nil
        }
    }
}

struct PlanetNoticePopup: View {
    let notice: PlanetNotice
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            if let icon = notice.icon {
                NoticeCard { pictured(icon) }
            } else {
                NoticeCard(bottomMargin: 44) { warning }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onClose)
        .designScaled()
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
    }

    private var warning: some View {
        styled(notice.message)
            .frame(width: 619, alignment: .leading)
            .padding(.vertical, 48)
    }

    private func pictured(_ icon: String) -> some View {
        VStack(spacing: 10) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .accessibilityHidden(true)
            styled(notice.message)
                .multilineTextAlignment(.center)
                .frame(width: 619, height: 70)
        }
        .frame(height: 280)
    }

    private func styled(_ message: Text) -> some View {
        message
            .font(.atkinson(size: 28, weight: .bold))
            .tracking(0.56)
            .lineSpacing(7)
            .foregroundStyle(Color.purple900)
    }
}

#Preview {
    PlanetNoticePopup(notice: .energy, onClose: {})
}
