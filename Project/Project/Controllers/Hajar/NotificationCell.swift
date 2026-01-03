import UIKit
import FirebaseFirestore

final class NotificationCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()

        // We will render BOTH title+subtitle inside titleLabel
        titleLabel.numberOfLines = 0
        subTitleLabel.isHidden = true
    }

    func configure(title: String, subtitle: String, iconName: String, createdAt: Timestamp?) {
        iconImageView.image = UIImage(named: iconName) ?? UIImage(named: "notif_user")

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 12          // ✅ controls the gap
        paragraph.paragraphSpacing = 0

        let attr = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                .paragraphStyle: paragraph
            ]
        )

        attr.append(NSAttributedString(string: "\n"))

        attr.append(NSAttributedString(
            string: subtitle,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .regular),
                .paragraphStyle: paragraph
            ]
        ))

        titleLabel.attributedText = attr

        if let createdAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            timeLabel?.text = formatter.localizedString(for: createdAt.dateValue(), relativeTo: Date())
        } else {
            timeLabel?.text = ""
        }
    }
}
