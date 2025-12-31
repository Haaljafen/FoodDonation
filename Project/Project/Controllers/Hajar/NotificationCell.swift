import UIKit

final class NotificationCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        preservesSuperviewLayoutMargins = false
        separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 16)
        layoutMargins = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 16)

        selectionStyle = .none
    }

    func configure(title: String, subtitle: String, iconName: String) {
        titleLabel.text = title
        subTitleLabel.text = subtitle
        iconImageView.image = UIImage(named: iconName)
    }
}
