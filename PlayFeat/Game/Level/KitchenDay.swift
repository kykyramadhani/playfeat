//
//  KitchenDay.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  One stretch of play in a planet kitchen, a story day or a whole marathon
//  run: the play clock, who stands at the counter, and the score. Scored as
//  in the prototype: a served dish adds its ingredients' points and a tip; a
//  customer who gives up takes 10 points off, never below zero. The total
//  (points plus tips) is what stars are counted from. Ticked by KitchenScene
//  every frame and read by the SwiftUI layers.
//

import Foundation

@Observable
final class KitchenDay {
    let level: LevelData
    /// What each ingredient is worth; the marathon's cards raise them mid-run.
    var pricing: DishPricing
    /// Stretches the patience of every customer who steps up from now on.
    var patienceScale = 1.0
    /// The plates and glasses on the counter; the marathon adds some mid-run.
    var tools: KitchenTools
    /// End of the marathon round being played, in play time. Nil on a story day.
    var roundEndsAt: TimeInterval?

    private(set) var elapsed: TimeInterval = 0
    /// Off during the countdown and while paused: the clock holds and hands
    /// can't touch anything.
    private(set) var isRunning = false
    private(set) var ordersDelivered = 0
    /// Points the served dishes have earned.
    private(set) var dishEarnings = 0
    private(set) var ordersMissed = 0
    /// Points the missed orders actually took off: the score never drops below zero.
    private(set) var pointsLost = 0
    private(set) var tips = 0
    /// The most recent customer's tip, shown beside the marathon's coins.
    private(set) var lastTip = 0
    private(set) var counter: Counter

    @ObservationIgnored private var flow: any CustomerFlow
    @ObservationIgnored private var clock: PlayClock?

    /// - Parameter positionTypes: the counter's positions and who each takes.
    init(
        level: LevelData,
        flow: any CustomerFlow,
        positionTypes: [CustomerType],
        pricing: DishPricing = .unupgraded,
        tools: KitchenTools
    ) {
        self.level = level
        self.flow = flow
        self.pricing = pricing
        self.tools = tools
        counter = Counter(positionTypes: positionTypes)
        // Whoever steps up at the opening bell waits through the countdown.
        advance(to: 0)
    }

    /// A story day of `level`, its customers stepping up as the level says.
    convenience init(
        storyLevel level: LevelData,
        positionTypes: [CustomerType],
        pricing: DishPricing = .unupgraded,
        tools: KitchenTools,
        random: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.init(
            level: level, flow: RefillFlow(level: level, random: random),
            positionTypes: positionTypes, pricing: pricing, tools: tools
        )
    }

    // MARK: - Score

    /// Dish points less what missed orders took off.
    var points: Int { dishEarnings - pointsLost }
    /// Points plus tips: the day's income, and what its stars count from.
    var total: Int { points + tips }
    var stars: Int { StarRating.stars(for: total, targets: level.starTargets) }

    // MARK: - Clock

    /// What the HUD clock shows: the day's time left, or the marathon round's.
    var timeLeft: TimeInterval { max((roundEndsAt ?? level.durationSec) - elapsed, 0) }
    var isOver: Bool {
        flow.isFinished(at: elapsed, lostCustomers: ordersMissed, counterIsEmpty: counter.isEmpty)
    }
    var isRoundOver: Bool { roundEndsAt.map { elapsed >= $0 } ?? false }

    var presentCustomers: [SeatedCustomer] { counter.present }
    /// What the bubbles can bring now.
    var bubblePool: [String] { flow.bubblePool }
    /// Seconds between marathon customers; nil on a story day.
    var customerSpacing: TimeInterval? { flow.customerSpacing }

    func start() { isRunning = true }
    func pause() { isRunning = false }

    /// Credits play time up to `wallTime` while running; otherwise just
    /// remembers it, so a resume doesn't credit the pause.
    func tick(at wallTime: TimeInterval) {
        var clock = clock ?? PlayClock(wallTime: wallTime)
        if isRunning, !isOver, !isRoundOver {
            clock.advance(to: wallTime)
        } else {
            clock.hold(at: wallTime)
        }
        self.clock = clock
        guard clock.elapsed != elapsed else { return }
        elapsed = clock.elapsed
        advance(to: elapsed)
    }

    // MARK: - Serving

    /// Hands `dish` to whoever stands at `seat`. Only the dish they ordered
    /// counts: then they pay its points, tip, and leave.
    /// - Returns: whether the dish was served.
    func serve(_ dish: String, at seat: Int) -> Bool {
        guard wants(dish, at: seat), let customer = counter.serve(seat: seat) else { return false }
        ordersDelivered += 1
        dishEarnings += pricing.pay(for: dish)
        lastTip = flow.tip(from: customer, at: elapsed)
        tips += lastTip
        flow.spotFreed(at: elapsed)
        flow.dishServed(totalServed: ordersDelivered)
        return true
    }

    /// Whether the customer at `seat`, if any, ordered `dish`.
    func wants(_ dish: String, at seat: Int) -> Bool {
        counter.seats.indices.contains(seat) && counter.seats[seat]?.dish == dish
    }

    /// Whether anyone stands at `seat`.
    func isOccupied(_ seat: Int) -> Bool {
        counter.seats.indices.contains(seat) && counter.seats[seat] != nil
    }

    // MARK: - Customers

    /// Steps customers up, stands them at the counter, and sends away anyone
    /// whose patience ran out, in the prototype's order.
    private func advance(to time: TimeInterval) {
        let arrivals = flow.arrivals(at: time, atCounter: counter.headcount).map { arrival in
            Arrival(type: arrival.type, dish: arrival.dish, patienceSec: arrival.patienceSec * patienceScale)
        }
        counter.arrive(arrivals)
        counter.seatWaiting(at: time, spots: flow.counterSpots)
        for _ in counter.removeGiveUps(at: time) { loseCustomer(at: time) }
        counter.seatWaiting(at: time, spots: flow.counterSpots)
    }

    private func loseCustomer(at time: TimeInterval) {
        ordersMissed += 1
        pointsLost += min(KitchenRules.lostCustomerPenalty, points)
        flow.spotFreed(at: time)
    }
}
