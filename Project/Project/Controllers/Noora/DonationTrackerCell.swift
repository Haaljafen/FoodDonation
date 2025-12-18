//import UIKit
//
//final class DonationTrackerCell: UITableViewCell {
//
//    @IBOutlet weak var circle1: UIImageView!
//    @IBOutlet weak var circle2: UIImageView!
//    @IBOutlet weak var circle3: UIImageView!
//
//    @IBOutlet weak var label1: UILabel! // Accepted
//    @IBOutlet weak var label2: UILabel! // Collected
//    @IBOutlet weak var label3: UILabel! // Delivered
//
//    func configure(currentStatus: String) {
//        selectionStyle = .none
//
//        circle1.image = UIImage(systemName: "circle")
//        circle2.image = UIImage(systemName: "circle")
//        circle3.image = UIImage(systemName: "circle")
//
//        let s = currentStatus.lowercased()
//
//        // step 1 = accepted/pending
//        // step 2 = collected/received
//        // step 3 = delivered
//        let step: Int
//        if s == "delivered" { step = 3 }
//        else if s == "collected" || s == "received" { step = 2 }
//        else { step = 1 } // pending / accepted / anything else
//
//        if step >= 1 { circle1.image = UIImage(systemName: "checkmark.circle.fill") }
//        if step >= 2 { circle2.image = UIImage(systemName: "checkmark.circle.fill") }
//        if step >= 3 { circle3.image = UIImage(systemName: "checkmark.circle.fill") }
//    }
//}


//
//  DonationTrackerCell 2.swift
//  Takaffal
//
//  Created by Eshraq Mohamed on 18/12/2025.
//


import UIKit

final class DonationTrackerCell: UITableViewCell {

    @IBOutlet weak var circle1: UIImageView! // Pending
    @IBOutlet weak var circle2: UIImageView! // Accepted
    @IBOutlet weak var circle3: UIImageView! // Collected
    @IBOutlet weak var circle4: UIImageView! // Delivered

    @IBOutlet weak var label1: UILabel! // Pending
    @IBOutlet weak var label2: UILabel! // Accepted
    @IBOutlet weak var label3: UILabel! // Collected
    @IBOutlet weak var label4: UILabel! // Delivered

    func configure(currentStatus: String) {
        selectionStyle = .none

        let circles = [circle1, circle2, circle3, circle4]

        // reset all
        circles.forEach {
            $0?.image = UIImage(systemName: "circle")
            $0?.tintColor = .systemGray3
        }

        let s = currentStatus.lowercased()

        let step: Int
        switch s {
        case "pending":
            step = 1
        case "accepted":
            step = 2
        case "collected", "received":
            step = 3
        case "delivered":
            step = 4
        default:
            step = 1 // fallback safety
        }

        // fill completed steps
        for i in 0..<step {
            circles[i]?.image = UIImage(systemName: "checkmark.circle.fill")
//            circles[i]?.tintColor = .systemGreen
        }
    }
}
