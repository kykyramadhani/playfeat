//
//  HandState.swift
//  PlayFeat
//  Created by kyky on 22/11/26.
//
//  What a hand's pose reads as this frame: open, a closed fist (holding),
//  or neither. The kitchen compares it with the last frame to grab and drop.
//

enum HandState { case unknown, open, fist }
