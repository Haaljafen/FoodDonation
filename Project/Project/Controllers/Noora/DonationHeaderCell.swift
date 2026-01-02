//
//  DonationHeaderCell.swift
//  Takaffal
//
//  Created by Noora Humaid on 18/12/2025.
//
import UIKit

final class DonationHeaderCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!

    func configure(title: String, donationID: String) {
        selectionStyle = .none
        titleLabel.text = title
        
        let shortID = donationID.components(separatedBy: "-").first ?? donationID
        idLabel.text = "#ID: \(shortID)"
    }
}
