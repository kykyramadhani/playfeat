//
//  ScheduledCustomer.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  A level customer with a real dish, after `OrderDealer` dealt the
//  `random` orders.
//

import Foundation

nonisolated struct ScheduledCustomer: Equatable {
    let arriveAt: TimeInterval
    let type: CustomerType
    let dish: String
    let patienceSec: TimeInterval
}
