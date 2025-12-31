//
//  DonationDetailsCardCell.swift
//  Takaffal
//
//  Created by Noora Humaid on 18/12/2025.
//

import UIKit

final class DonationDetailsCell: UITableViewCell {

    @IBOutlet weak var donationImageView: UIImageView!
    @IBOutlet weak var itemValueLabel: UILabel!
    @IBOutlet weak var quantityValueLabel: UILabel!
    @IBOutlet weak var expiryValueLabel: UILabel!
    @IBOutlet weak var impactValueLabel: UILabel!

    override func awakeFromNib() {
        
        super.awakeFromNib()
        selectionStyle = .default

        donationImageView.layer.cornerRadius = 10
        donationImageView.clipsToBounds = true
    }

    func configure(
        item: String,
        quantity: String,
        expiryDate: String,
        impact: String,
        imageUrlString: String?
    ) {
        itemValueLabel.text = item
        quantityValueLabel.text = quantity
        expiryValueLabel.text = expiryDate
        impactValueLabel.text = impact
        
        loadImage(urlString: imageUrlString) 
    }

    

    private func loadImage(urlString: String?) {
        donationImageView.image = UIImage(named: "placeholder") // optional

        guard let urlString = urlString,
              !urlString.isEmpty,
              let url = URL(string: urlString) else {
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let img = UIImage(data: data) else { return }

            DispatchQueue.main.async {
                self.donationImageView.image = img
            }
        }.resume()
    }

}
