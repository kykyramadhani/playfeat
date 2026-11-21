//
//  LandedShip.swift
//  PlayFeat
//  Created by Owen Limantoro on 21/11/26.
//
//  A planet's landed spaceship on its level board. Tapping it drops the
//  hatch open on its chains to show the chef inside; tapping again
//  closes it.
//

import SwiftUI

struct LandedShip: View {
    let planet: Planet.ID
    @Binding var isOpen: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The box the closed ship is fitted into on the board, in design points.
    static let size = CGSize(width: 764, height: 674)

    var body: some View {
        ClickButton(action: { isOpen.toggle() }, sound: isOpen ? .uiClick : .openShip) {
            shipArt
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOpen ? Text("Close the spaceship") : Text("Open the spaceship"))
    }

    private var shipArt: some View {
        let art = Self.art(for: planet)
        return ZStack(alignment: .topLeading) {
            Image(art.closed)
                .resizable()
                .scaledToFit()
                .frame(width: Self.size.width, height: Self.size.height)
            // Faded in over the closed ship, which it covers whole, so the
            // ship never turns see-through while the hatch opens.
            Image(art.open)
                .resizable()
                .frame(width: art.openFrame.width, height: art.openFrame.height)
                .offset(x: art.openFrame.minX, y: art.openFrame.minY)
                .opacity(isOpen ? 1 : 0)
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .animation(.easeOut(duration: 0.2), value: isOpen)
        .phaseAnimator([false, true], trigger: isOpen) { ship, isHopping in
            ship.scaleEffect(isHopping && !reduceMotion ? 1.03 : 1, anchor: .bottom)
        }
    }

    // MARK: - Art

    struct Art {
        let closed: String
        let open: String
        /// Where the open picture is drawn in the `size` box, so its hull
        /// lands exactly on the closed one's. Found by matching the two
        /// pictures: the Figma frames place them apart.
        let openFrame: CGRect
    }

    static func art(for planet: Planet.ID) -> Art {
        switch planet {
        case .kepler186f:
            Art(closed: "LandedSpaceship", open: "LandedSpaceshipOpen",
                openFrame: CGRect(x: 51, y: 47, width: 722, height: 544.5))
        case .k2332b:
            // The closed ship is narrower than the box, so it is centred
            // 25.9 points in, and the open one with it.
            Art(closed: "K2332bSpaceship", open: "K2332bSpaceshipOpen",
                openFrame: CGRect(x: -27.1, y: -19, width: 805, height: 761))
        }
    }
}

#Preview {
    @Previewable @State var isOpen = false
    HStack {
        LandedShip(planet: .kepler186f, isOpen: $isOpen)
        LandedShip(planet: .k2332b, isOpen: $isOpen)
    }
    .scaleEffect(0.5)
    .environment(AudioManager())
}
