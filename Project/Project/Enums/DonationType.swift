//
//  DonationType.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 01/12/2025.
//

import Foundation
import UIKit

enum DonationType: String, Codable, CaseIterable {
    case mealsProvided = "Meals Provided"
    case wastePrevented = "Waste Prevented"
    case other = "Other"
    
    
    /// Color used in impact pie chart
    var chartColor: UIColor {
        switch self {
        case .mealsProvided:
            // Meals Provided → Warm red
            return UIColor(hex: "B35D4C")
            
        case .wastePrevented:
            // Waste Prevented → Soft orange
            return UIColor(hex: "DF9B6D")
            
        case .other:
            // Other → Neutral blue-gray
            return UIColor(hex: "738290")
        }
    }
}
