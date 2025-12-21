import UIKit

final class DonationCell: UITableViewCell {

    @IBOutlet weak var donationIDLabel: UILabel!
    @IBOutlet weak var methodLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()

        // Cell base
        backgroundColor = .clear


        // Text styling (force visible)
        donationIDLabel.textColor = .label
        methodLabel.textColor = .secondaryLabel
        dateLabel.textColor = .secondaryLabel
        statusLabel.textColor = .label

        donationIDLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        methodLabel.font = .systemFont(ofSize: 14, weight: .regular)
        dateLabel.font = .systemFont(ofSize: 13, weight: .regular)
        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
    }

}
