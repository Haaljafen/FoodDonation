import UIKit

final class DonationHeaderCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!

    func configure(title: String, donationID: String) {
        selectionStyle = .none
        titleLabel.text = title
        idLabel.text = "#ID: \(donationID)"
    }
}
