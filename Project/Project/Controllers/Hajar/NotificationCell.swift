import UIKit

final class NotificationCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!

    func configure(title: String, subtitle: String, iconName: String) {
        titleLabel.text = title
        subTitleLabel.text = subtitle
        iconImageView.image = UIImage(named: iconName)
    }
}
