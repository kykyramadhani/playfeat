//
//  AnyRandomNumberGenerator.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  Any random number generator as one concrete type, so a game rule can
//  keep the one it was handed (the system's in play, a seeded one in tests)
//  and still pass it on to the standard library's random functions.
//

nonisolated struct AnyRandomNumberGenerator: RandomNumberGenerator {
    private var base: any RandomNumberGenerator

    init(_ base: any RandomNumberGenerator) {
        self.base = base
    }

    mutating func next() -> UInt64 {
        base.next()
    }
}
