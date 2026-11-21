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
    /// Whether the opening countdown is over; until then the counter's
    /// places are empty on screen, though the first customers already wait.
    private(set) var hasOpened = false
    private(set) var ordersDelivered = 0
    /// How many of each dish were served.
    private(set) var servedDishes: [String: Int] = [:]
    private(set) var angryCustomersServed = 0
    /// Points the served dishes have earned.
    private(set) var dishEarnings = 0
    private(set) var ordersMissed = 0
    /// Points the missed orders actually took off: the score never drops below zero.
    private(set) var pointsLost = 0
    private(set) var tips = 0
    /// Seconds the served customers waited at the counter, all told.
    private(set) var servedWaitSec: TimeInterval = 0
    /// The most recent customer's tip, shown beside the marathon's coins.
    private(set) var lastTip = 0
    private(set) var counter: Counter
    /// Customers just served, still drawn while their dish goes into them.
    private(set) var departures: [Departure] = []

    @ObservationIgnored private var flow: any CustomerFlow
    @ObservationIgnored private var clock: PlayClock?

    /// - Parameters:
    ///   - openSeats: the positions customers may take, picked at random by `random`.
    init(
        level: LevelData,
        flow: any CustomerFlow,
        openSeats: [Int],
        pricing: DishPricing = .unupgraded,
        tools: KitchenTools,
        random: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.level = level
        self.flow = flow
        self.pricing = pricing
        self.tools = tools
        counter = Counter(openSeats: openSeats, random: random)
        // Whoever steps up at the opening bell waits through the countdown.
        advance(to: 0)
    }

    /// A story day of `level`, its customers stepping up as the level says.
    convenience init(
        storyLevel level: LevelData,
        openSeats: [Int],
        pricing: DishPricing = .unupgraded,
        tools: KitchenTools,
        random: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.init(
            level: level, flow: RefillFlow(level: level, random: random),
            openSeats: openSeats, pricing: pricing, tools: tools, random: random
        )
    }

    // MARK: - Score

    /// How long a served customer waited at the counter, on average.
    var averageWaitSec: TimeInterval {
        ordersDelivered > 0 ? servedWaitSec / Double(ordersDelivered) : 0
    }

    /// Dish points less what missed orders took off.
    var points: Int { dishEarnings - pointsLost }
    /// Points plus tips: the day's income, and what its stars count from.
    var total: Int { points + tips }
    var stars: Int { StarRating.stars(for: total, targets: level.starTargets) }

    // MARK: - Clock

    /// What the HUD clock shows: the day's time left, or the marathon round's.
    var timeLeft: TimeInterval { max((roundEndsAt ?? level.durationSec) - elapsed, 0) }
    var isOver: Bool {
        // The day waits for the last served customer to leave, so their
        // dish's hand-over plays out before the day's end is shown.
        flow.isFinished(at: elapsed, lostCustomers: ordersMissed, counterIsEmpty: counter.isEmpty && departures.isEmpty)
    }
    var isRoundOver: Bool { roundEndsAt.map { elapsed >= $0 } ?? false }

    var presentCustomers: [SeatedCustomer] { counter.present }

    /// The aliens to draw: everyone at the counter, plus whoever was just
    /// served until the dish is in and a beat has passed.
    var aliensOnScreen: [SeatedCustomer] {
        guard hasOpened else { return [] }
        return presentCustomers + departing(for: KitchenRules.handOverSec + KitchenRules.pauseBeforeLeavingSec)
    }

    /// The order sheets to draw: a served customer's goes once the dish is in.
    var orderSheetsOnScreen: [SeatedCustomer] {
        guard hasOpened else { return [] }
        return presentCustomers + departing(for: KitchenRules.handOverSec)
    }

    /// Whether `customer` has been served and is on their way out.
    func isServed(_ customer: SeatedCustomer) -> Bool {
        departures.contains { $0.customer == customer }
    }

    /// How patient `customer` looks; a served customer's face stays as it was.
    func patienceShown(for customer: SeatedCustomer) -> Double {
        let servedAt = departures.first { $0.customer == customer }?.servedAt
        return customer.patienceLeft(at: min(elapsed, servedAt ?? elapsed))
    }

    /// What the bubbles can bring now.
    var bubblePool: [String] { flow.bubblePool }
    /// Seconds between marathon customers; nil on a story day.
    var customerSpacing: TimeInterval? { flow.customerSpacing }

    func start() {
        isRunning = true
        hasOpened = true
    }
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
        servedDishes[dish, default: 0] += 1
        if customer.type == .angry { angryCustomersServed += 1 }
        servedWaitSec += elapsed - customer.seatedAt
        dishEarnings += pricing.pay(for: dish)
        lastTip = flow.tip(from: customer, at: elapsed)
        tips += lastTip
        flow.spotFreed(at: elapsed)
        flow.dishServed(totalServed: ordersDelivered)
        departures.append(Departure(customer: customer, servedAt: elapsed))
        return true
    }

    /// Whether the customer at `seat`, if any, ordered `dish`.
    func wants(_ dish: String, at seat: Int) -> Bool {
        counter.seats[seat]?.dish == dish
    }

    /// Whether anyone stands at `seat`.
    func isOccupied(_ seat: Int) -> Bool {
        counter.seats[seat] != nil
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
        departures.removeAll { time >= $0.servedAt + KitchenRules.handOverSec + KitchenRules.pauseBeforeLeavingSec }
    }

    /// Served customers still drawn `seconds` after being served, unless
    /// someone new already stands at their position.
    private func departing(for seconds: TimeInterval) -> [SeatedCustomer] {
        departures
            .filter { elapsed < $0.servedAt + seconds && !isOccupied($0.customer.seat) }
            .map(\.customer)
    }

    private func loseCustomer(at time: TimeInterval) {
        ordersMissed += 1
        pointsLost += min(KitchenRules.lostCustomerPenalty, points)
        flow.spotFreed(at: time)
    }
}

/// A served customer on their way out.
nonisolated struct Departure: Equatable {
    let customer: SeatedCustomer
    let servedAt: TimeInterval
}
