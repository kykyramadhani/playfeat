//
//  KitchenDay.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  One day in a planet kitchen: the level's clock and who is waiting at
//  which seat. Ticked by KitchenScene every frame and read by the kitchen's
//  SwiftUI layers for the timer and the customers' patience bars.
//

import Foundation

@Observable
final class KitchenDay {
    let level: LevelData
    let customers: [SeatedCustomer]

    private(set) var elapsed: TimeInterval = 0
    /// Off during the countdown and while paused: the clock holds and hands
    /// can't touch anything.
    private(set) var isRunning = false

    @ObservationIgnored private var clock: PlayClock?

    init(level: LevelData, seatCount: Int, using generator: inout some RandomNumberGenerator) {
        self.level = level
        let schedule = OrderDealer.schedule(level, using: &generator)
        customers = CustomerSeating.seat(schedule, seatCount: min(seatCount, level.maxWaiting))
    }

    var timeLeft: TimeInterval { max(level.durationSec - elapsed, 0) }
    var isOver: Bool { elapsed >= level.durationSec }

    var presentCustomers: [SeatedCustomer] {
        customers.filter { $0.isPresent(at: elapsed) }
    }

    func start() { isRunning = true }
    func pause() { isRunning = false }

    /// Credits play time up to `wallTime` while running; otherwise just
    /// remembers it, so a resume doesn't credit the pause.
    func tick(at wallTime: TimeInterval) {
        var clock = clock ?? PlayClock(wallTime: wallTime)
        if isRunning, !isOver {
            clock.advance(to: wallTime)
        } else {
            clock.hold(at: wallTime)
        }
        self.clock = clock
        if clock.elapsed != elapsed { elapsed = clock.elapsed }
    }
}
