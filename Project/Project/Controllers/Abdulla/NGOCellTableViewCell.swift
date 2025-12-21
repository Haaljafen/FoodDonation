import UIKit

class NGOCell: UITableViewCell {
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Apply corner radius
        cardView.layer.cornerRadius = 12
        cardView.layer.masksToBounds = true
    }
    
    func configure(with ngoName: String) {
        nameLabel.text = ngoName
    }
    
    
}
