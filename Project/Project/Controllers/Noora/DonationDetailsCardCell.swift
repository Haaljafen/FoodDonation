import UIKit

final class DonationDetailsCell: UITableViewCell {
//
//    @IBOutlet weak var donationImageView: UIImageView!

    @IBOutlet weak var itemValueLabel: UILabel!
    @IBOutlet weak var quantityValueLabel: UILabel!
    @IBOutlet weak var categoryValueLabel: UILabel!
    @IBOutlet weak var impactValueLabel: UILabel!

    override func awakeFromNib() {
        
        //
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 26
        contentView.layer.masksToBounds = true

        backgroundColor = .clear

        //
        super.awakeFromNib()
        selectionStyle = .default
//
//        donationImageView.layer.cornerRadius = 10
//        donationImageView.clipsToBounds = true
    }

    func configure(
        item: String,
        quantity: String,
        category: String,
        impact: String
//        imageUrlString: String
    ) {
        itemValueLabel.text = item
        quantityValueLabel.text = quantity
        categoryValueLabel.text = category
        impactValueLabel.text = impact
//
//        loadImage(urlString: imageUrlString)
    }

//    private func loadImage(urlString: String) {
//        donationImageView.image = nil
//        guard !urlString.isEmpty,
//              let url = URL(string: urlString) else { return }
//
//        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
//            guard let self = self,
//                  let data = data,
//                  let img = UIImage(data: data) else { return }
//
//            DispatchQueue.main.async {
//                self.donationImageView.image = img
//            }
//        }.resume()
//    }
}
