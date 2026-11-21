//
//  IntroStoryPanel.swift
//  PlayFeat
//  Created by kyky on 21/11/26.
//
//  The intro story's script: one entry per comic panel, with the Lottie
//  animation that draws its artwork and the line read under it. The caption
//  stays out of the animation so it can be translated and set in Atkinson.
//

import Foundation

struct IntroStoryPanel {
    /// Bundled Lottie file, without `.json`.
    let animationName: String
    let caption: String.LocalizationValue
    /// Seconds into the panel before its caption rises in, as in the Figma
    /// motion: each caption waits for that panel's artwork to land.
    let captionDelay: TimeInterval

    static let all: [IntroStoryPanel] = [
        IntroStoryPanel(
            animationName: "IntroStoryPanel1",
            caption: "Once upon a time, there was an astronaut who had just finished his research at a foreign planet and he wanted to go back home.",
            captionDelay: 0.6
        ),
        IntroStoryPanel(
            animationName: "IntroStoryPanel2",
            caption: "Suddenly, his spaceship crashed midway on his journey back home due to an asteroid collision.",
            captionDelay: 1.25
        ),
        IntroStoryPanel(
            animationName: "IntroStoryPanel3",
            caption: "The crash made the spaceship plunge down and fell upon another planet.",
            captionDelay: 1.35
        ),
        IntroStoryPanel(
            animationName: "IntroStoryPanel4",
            caption: "Sadly, the spaceship became damaged and ran out of fuel. The astronaut had no idea how to get back.",
            captionDelay: 1.35
        ),
        IntroStoryPanel(
            animationName: "IntroStoryPanel5",
            caption: "Then he met a local alien of the planet. The alien said he needed to get stars for the fuel by selling food for the aliens.",
            captionDelay: 1.35
        ),
        IntroStoryPanel(
            animationName: "IntroStoryPanel6",
            caption: "Ever since then, the astronaut had to sell food for aliens in order to get back home.",
            captionDelay: 1.59
        ),
    ]
}
