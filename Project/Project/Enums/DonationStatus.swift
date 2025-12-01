//
//  DonationStatus.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 30/11/2025.
//

import Foundation

enum DonationStatus: String, Codable {
    case pending
    case accepted
    case onTheWay
    case collected
    case delivered
}
