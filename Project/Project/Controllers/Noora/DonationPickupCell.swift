
import UIKit

final class DonationPickupCell: UITableViewCell {

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var methodLabel: UILabel!

    func configure(address: String, dateTime: String, method: String) {
        selectionStyle = .none
        addressLabel.text = address
        dateTimeLabel.text = dateTime
        methodLabel.text = methodDisplay(method)
    }

    private func methodDisplay(_ raw: String) -> String {
        let s = raw.lowercased()
        if s == "dropoff" { return "Drop-off at facility" }
        if s == "pickup" { return "Pickup from address" }
        return raw
    }
}
