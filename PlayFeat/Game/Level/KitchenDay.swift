//
//  KitchenDay.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  One day in a planet kitchen: the level's clock, who is waiting at which
//  seat, and what serving them has earned. Ticked by KitchenScene every frame
//  and read by the kitchen's SwiftUI layers for the timer, the counters and
//  the customers' patience bars.
//

import Foundation

@Observable
final class KitchenDay {
    /// Paid for every dish served.
    /// ponytail: borrowed from the classic run's dish price and the marathon's
    /// tip rule until the level design settles what a served dish pays.
    static let coinsPerDish = 10

    let level: LevelData

    private(set) var elapsed: TimeInterval = 0
    /// Off during the countdown and while paused: the clock holds and hands
    /// can't touch anything.
    private(set) var isRunning = false
    private(set) var coins = 0
    private(set) var tips = 0
    private(set) var seating: CustomerSeating

    @ObservationIgnored private var clock: PlayClock?

    init(level: LevelData, seatCount: Int, using generator: inout some RandomNumberGenerator) {
        self.level = level
        let schedule = OrderDealer.schedule(level, using: &generator)
        seating = CustomerSeating(customers: schedule, seatCount: min(seatCount, level.maxWaiting))
        // Whoever arrives at the opening bell is already waiting during the countdown.
        _ = seating.advance(to: 0)
    }

    var timeLeft: TimeInterval { max(level.durationSec - elapsed, 0) }
    var isOver: Bool { elapsed >= level.durationSec }
    /// What the day's stars are counted from.
    var score: Int { coins + tips }

    var presentCustomers: [SeatedCustomer] { seating.present }

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
        guard clock.elapsed != elapsed else { return }
        elapsed = clock.elapsed
        _ = seating.advance(to: elapsed)
    }

    /// Hands `dish` to whoever sits at `seat`. Only the dish they ordered
    /// counts: then they pay, tip for the patience they had left, and leave.
    /// - Returns: whether the dish was served.
    func serve(_ dish: String, at seat: Int) -> Bool {
        guard wants(dish, at: seat),
              let customer = seating.serve(seat: seat, at: elapsed) else { return false }
        coins += Self.coinsPerDish
        tips += MarathonRun.tip(for: customer.type, patienceLeft: customer.leavesAt - elapsed)
        return true
    }

    /// Whether the customer at `seat`, if any, ordered `dish`.
    func wants(_ dish: String, at seat: Int) -> Bool {
        seating.seats.indices.contains(seat) && seating.seats[seat]?.dish == dish
    }
}
