//
//  PaperTexture.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  The faint crayon scribble the Sunrise designs lay over every flat fill,
//  so buttons and panels look hand-made rather than flat.
//

import SwiftUI

extension View {
    func paperTexture<S: Shape>(clippedTo shape: S, opacity: Double = 1) -> some View {
        overlay {
            // Color.clear takes the view's size, so the filled image is
            // clipped to this view rather than to its own, larger frame.
            Color.clear
                .overlay {
                    Image("PaperTexture")
                        .resizable()
                        .scaledToFill()
                }
                .opacity(opacity)
                .clipShape(shape)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
