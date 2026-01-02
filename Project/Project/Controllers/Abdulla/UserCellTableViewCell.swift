import UIKit

class UserCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var donationsLabel: UILabel!
    @IBOutlet weak var statusBadge: UILabel!
    @IBOutlet weak var chevronIcon: UIImageView!
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        styleCell()
    }
    
    // MARK: - Styling
    private func styleCell() {
        // Status badge styling
        statusBadge.layer.cornerRadius = 14
        statusBadge.layer.masksToBounds = true
        statusBadge.textAlignment = .center
        
        // Cell styling
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    // ✅ NEW METHOD - Use this one!
    func configure(with user: User, donationCount: Int = 0) {
        nameLabel.text = user.organizationName ?? user.username ?? "Unknown"
        donationsLabel.text = "\(donationCount) donations"
        
        // ✅ PROPER STATUS HANDLING
        if let status = user.status {
            configureStatus(status: status)
        } else {
            statusBadge.text = "Unknown"
            statusBadge.backgroundColor = .systemGray
            statusBadge.textColor = .white
        }
    }
    
    // ✅ HELPER: Handle ALL status types
    private func configureStatus(status: UserStatus) {
        statusBadge.textColor = .white
        
        switch status {
        case .verified:
            statusBadge.text = "Verified"
            statusBadge.backgroundColor = .systemGreen
            
        case .pending:
            statusBadge.text = "Pending"
            statusBadge.backgroundColor = .systemOrange
            
        case .suspended:
            statusBadge.text = "Suspended"
            statusBadge.backgroundColor = .systemRed
            
        case .rejected:
            statusBadge.text = "Rejected"  // ✅ NOW HANDLES REJECTED!
            statusBadge.backgroundColor = .systemRed
            
        case .active:
            statusBadge.text = "Active"
            statusBadge.backgroundColor = .systemBlue
        }
    }
}
