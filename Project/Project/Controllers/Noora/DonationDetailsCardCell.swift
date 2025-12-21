import UIKit

final class DonationDetailsCell: UITableViewCell {
//
    @IBOutlet weak var donationImageView: UIImageView!

//    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var itemValueLabel: UILabel!
    @IBOutlet weak var quantityValueLabel: UILabel!
    @IBOutlet weak var categoryValueLabel: UILabel!
    @IBOutlet weak var impactValueLabel: UILabel!

    override func awakeFromNib() {
        
        super.awakeFromNib()
        selectionStyle = .default

        donationImageView.layer.cornerRadius = 10
        donationImageView.clipsToBounds = true
    }

    func configure(
        item: String,
        quantity: String,
        category: String,
        impact: String,
        imageUrlString: String?
    ) {
        itemValueLabel.text = item
        quantityValueLabel.text = quantity
        categoryValueLabel.text = category
        impactValueLabel.text = impact
//
        loadImage(urlString: imageUrlString)
    }
    
//    private func setupCard() {
//           cardView.layer.cornerRadius = 16
//           cardView.layer.shadowColor = UIColor.black.cgColor
//           cardView.layer.shadowOpacity = 0.1
//           cardView.layer.shadowRadius = 8
//           cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
//        cardView.layer.masksToBounds = false   // 🔴 REQUIRED
//
//       }
    private func loadImage(urlString: String?) {
        donationImageView.image = UIImage(named: "placeholder") // optional

        guard let urlString = urlString,
              !urlString.isEmpty,
              let url = URL(string: urlString) else {
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let img = UIImage(data: data) else { return }

            DispatchQueue.main.async {
                self.donationImageView.image = img
            }
        }.resume()
    }

}
