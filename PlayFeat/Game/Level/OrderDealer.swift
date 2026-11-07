//
//  OrderDealer.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  Turns a level's customer list into real orders by dealing the shuffled
//  `orderPool` to every `random` customer.
//

import Foundation

nonisolated enum OrderDealer {
    /// Fixed orders (the first customer, angry aliens) stay as written. The
    /// dish counts are the same every play; only their order changes. Pass a
    /// seeded generator to replay a bug.
    static func schedule(
        _ level: LevelData,
        using generator: inout some RandomNumberGenerator
    ) -> [ScheduledCustomer] {
        var shuffledPool = dishes(in: level.orderPool ?? [:]).shuffled(using: &generator)
        return level.customers.map { entry in
            let dish = entry.takesRandomOrder ? shuffledPool.removeFirst() : entry.order
            return ScheduledCustomer(
                arriveAt: entry.arriveAt,
                type: entry.type,
                dish: dish,
                patienceSec: entry.patienceSec
            )
        }
    }

    /// Sorted first so the same seed always gives the same deal, whatever
    /// order the dictionary iterates in.
    private static func dishes(in pool: [String: Int]) -> [String] {
        pool.keys.sorted().flatMap { dish in
            Array(repeating: dish, count: pool[dish] ?? 0)
        }
    }
}
