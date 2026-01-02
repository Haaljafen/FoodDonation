import UIKit

class NGOCell: UITableViewCell {
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.layer.cornerRadius = 12
        cardView.layer.masksToBounds = true
    }
    
    // ✅ CHANGE THIS FUNCTION
    func configure(with user: User) {
        nameLabel.text = user.organizationName ?? "Unknown NGO"
        
        // Load image from URL if available
        if let urlString = user.profileImageUrl, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.iconImageView.image = image
                    }
                }
            }.resume()
        }
    }
}
