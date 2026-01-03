import UIKit

class DonationCellHajar: UITableViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var donorNameLabel: UILabel!
    @IBOutlet weak var expiryDateLabel: UILabel!
    @IBOutlet weak var donationImageView: UIImageView!
    @IBOutlet weak var categoryChipView: UIView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    
    
    override func awakeFromNib() {
            super.awakeFromNib()

            backgroundColor = .clear
            contentView.backgroundColor = .clear
            selectionStyle = .none

            setupCard()
            setupChip()
        setupImage()   // ✅ ADD THIS LINE
        
        contentView.bringSubviewToFront(cardView)
        cardView.bringSubviewToFront(donationImageView)    // ✅ ensure image is above card
        cardView.bringSubviewToFront(categoryChipView)     // ✅ chip above image

        setupButtons()

        donationImageView.contentMode = .scaleAspectFill
        donationImageView.clipsToBounds = true

        donationImageView.isUserInteractionEnabled = false
        acceptButton.isHidden = true
        rejectButton.isHidden = true
        acceptButton.isEnabled = false
        rejectButton.isEnabled = false

//        cardView.bringSubviewToFront(categoryChipView)
//        contentView.bringSubviewToFront(cardView)

        }

        // MARK: - Setup UI

        private func setupCard() {
            
            cardView.layer.cornerRadius = 18
            cardView.layer.masksToBounds = false
            cardView.backgroundColor = UIColor(white: 0.92, alpha: 1.0)

            cardView.layer.shadowColor = UIColor.black.cgColor
            cardView.layer.shadowOpacity = 0.08
            cardView.layer.shadowOffset = CGSize(width: 0, height: 6)
            cardView.layer.shadowRadius = 12
        }
    
    private func setupChip() {
        categoryChipView.backgroundColor = UIColor(red: 0.06, green: 0.14, blue: 0.22, alpha: 1.0)
        categoryChipView.layer.cornerRadius = 13
        categoryChipView.clipsToBounds = true

        categoryLabel.textColor = .white
        categoryLabel.font = .systemFont(ofSize: 12, weight: .semibold)
    }


//        private func setupChip() {
//            categoryChipView.backgroundColor = UIColor(
//                red: 0.06,
//                green: 0.14,
//                blue: 0.22,
//                alpha: 1.0
//            )

//            categoryChipView.layer.cornerRadius = 13
//            categoryChipView.clipsToBounds = true

//            categoryLabel.textColor = .white
//            categoryLabel.font = .systemFont(ofSize: 12, weight: .semibold)
            
//            categoryLabel.font = .systemFont(ofSize: 11, weight: .semibold)
//            categoryChipView.layer.cornerRadius = 12
//            categoryChipView.alpha = 0.95
//            
//            categoryChipView.backgroundColor = .systemRed
//            categoryLabel.textColor = .white
//            categoryLabel.text = "TEST"
//            categoryChipView.isHidden = false
//            categoryLabel.isHidden = false
//            categoryChipView.alpha = 1
//
//
//        }

        // MARK: - Configure cell data
        func configure(with item: DonationItem) {
            categoryLabel.text = item.category
            itemNameLabel.text = item.name
            quantityLabel.text = item.quantity
            locationLabel.text = item.location
            expiryDateLabel.text = item.expiryDate
            donorNameLabel.text = item.donorName
            loadImage(from: item.imageURL)   // ✅ THIS IS THE KEY LINE

    }
    
    private var currentImageURL: String?

    private func setupImage() {
        donationImageView.contentMode = .scaleAspectFill
        donationImageView.clipsToBounds = true
        donationImageView.layer.cornerRadius = 12
    }

    private func loadImage(from urlString: String) {

        // 🔹 Transform Cloudinary image (THIS is the important part)
        let transformedURL = urlString.replacingOccurrences(
            of: "/upload/",
            with: "/upload/w_500,h_350,c_fill,q_auto,f_auto/"
        )

        guard let url = URL(string: transformedURL) else {
            donationImageView.image = UIImage(systemName: "photo")
            return
        }

        // Reset image before loading (prevents reuse bugs)
        donationImageView.image = nil

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard
                let self = self,
                let data = data,
                let image = UIImage(data: data)
            else { return }

            DispatchQueue.main.async {
                self.donationImageView.image = image
            }
        }.resume()
    }



    override func prepareForReuse() {
        super.prepareForReuse()
        currentImageURL = nil
        donationImageView.image = nil
    }

    private func setupButtons() {
        acceptButton.setTitle("Accept", for: .normal)
//        acceptButton.backgroundColor = UIColor(
//            red: 0.06,
//            green: 0.14,
//            blue: 0.22,
//            alpha: 1.0
//        )
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.layer.cornerRadius = 10
        acceptButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)

        rejectButton.setTitle("Reject", for: .normal)
//        rejectButton.backgroundColor = UIColor(
//            red: 0.72,
//            green: 0.35,
//            blue: 0.30,
//            alpha: 1.0
//        )
        rejectButton.setTitleColor(.white, for: .normal)
        rejectButton.layer.cornerRadius = 10
        rejectButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
    }

}
