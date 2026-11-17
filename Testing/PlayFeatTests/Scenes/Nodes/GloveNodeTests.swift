//
//  GloveNodeTests.swift
//  PlayFeatTests
//  Created by kyky on 16/11/26.
//

import Testing
@testable import PlayFeat

struct GloveNodeTests {

    /// The art is a right hand.
    @Test func theRightHandUsesTheArtAsDrawn() {
        #expect(!GloveNode.isMirrored(for: .right))
    }

    @Test func theLeftHandIsFlipped() {
        #expect(GloveNode.isMirrored(for: .left))
    }
}
