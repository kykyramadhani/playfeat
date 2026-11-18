//
//  SeatedAlien.swift
//  PlayFeat
//  Created by Owen Limantoro on 18/11/26.
//
//  One customer at the counter, drawn on the kitchen art in its seat's pose
//  (see KitchenLayout.AlienPose) and its current mood.
//

import SwiftUI

struct SeatedAlien: View {
    let imageName: String
    let pose: KitchenLayout.AlienPose

    var body: some View {
        Image(imageName)
            .scaleEffect(x: pose.isMirrored ? -1 : 1, y: 1)
            .rotationEffect(.degrees(pose.turnDegrees))
            .position(pose.center)
    }
}

#Preview {
    ZStack(alignment: .topLeading) {
        ForEach(KitchenLayout.seats.indices, id: \.self) { index in
            SeatedAlien(imageName: AlienSpecies.regular.imageName(in: .yellow),
                        pose: KitchenLayout.seats[index].alienPose)
        }
        Image("KitchenCounter")
    }
    .frame(width: KitchenLayout.artSize.width, height: KitchenLayout.artSize.height, alignment: .topLeading)
    .scaleEffect(0.5)
}
