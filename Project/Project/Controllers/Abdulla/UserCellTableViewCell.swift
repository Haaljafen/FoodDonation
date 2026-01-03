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
        statusBadge.layer.cornerRadius = 14
        statusBadge.layer.masksToBounds = true
        statusBadge.textAlignment = .center
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    // ✅ UPDATED: Handle nil status intelligently
    func configure(with user: User, donationCount: Int = 0) {
        nameLabel.text = user.organizationName ?? user.username ?? "Unknown"
        donationsLabel.text = "\(donationCount) donations"
        
        // ✅ Handle status (or lack of it)
        if let status = user.status {
            // User HAS status field - use it
            configureStatus(status: status)
        } else {
            // User DOESN'T have status field - set default based on role
            configureDefaultStatus(for: user.role)
        }
    }
    
    // ✅ HELPER: Handle explicit status values
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
            statusBadge.text = "Rejected"
            statusBadge.backgroundColor = .systemRed
            
        case .active:
            statusBadge.text = "Active"
            statusBadge.backgroundColor = .systemBlue
        }
    }
    
    // ✅ NEW: Set default status based on role when status field is missing
    private func configureDefaultStatus(for role: UserRole) {
        statusBadge.textColor = .white
        
        switch role {
        case .donor:
            // Donors without status = Active (normal users)
            statusBadge.text = "Active"
            statusBadge.backgroundColor = .systemBlue
            
        case .ngo:
            // NGOs without status = Pending (waiting approval)
            statusBadge.text = "Pending"
            statusBadge.backgroundColor = .systemOrange
            
        case .admin:
            // Admins without status = Active
            statusBadge.text = "Active"
            statusBadge.backgroundColor = .systemGreen
        }
    }
}
