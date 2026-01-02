//
//  DonationStatus.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 30/11/2025.
//

import Foundation
import UIKit

enum DonationStatus: String, Codable {
    case pending
    case accepted
    case collected
    case delivered
    
    
    /// Consistent status color across the app
    var color: UIColor {
        switch self {
        case .pending:
            return UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1)   // Amber
        case .accepted:
            return UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 1)    // Blue
        case .collected:
            return UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 1)   // Purple
        case .delivered:
            return UIColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1)    // Green
        }
    }
    
}
