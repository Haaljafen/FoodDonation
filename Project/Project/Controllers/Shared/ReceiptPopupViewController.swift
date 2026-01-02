import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

final class ReceiptPopupViewController: UIViewController {

    static func makePlainTextDataUrl(from receiptText: String) -> String {
        let data = Data(receiptText.utf8)
        let b64 = data.base64EncodedString()
        return "data:text/plain;base64,\(b64)"
    }

    static func makeGithubPagesReceiptUrl(from receiptText: String) -> String {
        let data = Data(receiptText.utf8)
        var b64 = data.base64EncodedString()
        b64 = b64.replacingOccurrences(of: "+", with: "-")
        b64 = b64.replacingOccurrences(of: "/", with: "_")
        b64 = b64.replacingOccurrences(of: "=", with: "")

        return "https://haaljafen.github.io/takaffal-receipt/receipt.html?r=\(b64)"
    }

    private let receiptTitleText: String
    private let receiptBodyText: String
    private let qrPayload: String

    var onDismiss: (() -> Void)?

    private let backdropView = UIView()
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let bodyTextView = UITextView()
    private let qrImageView = UIImageView()

    private let closeButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    init(receiptTitle: String, receiptBody: String, qrPayload: String) {
        self.receiptTitleText = receiptTitle
        self.receiptBodyText = receiptBody
        self.qrPayload = qrPayload
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configure()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        backdropView.translatesAutoresizingMaskIntoConstraints = false
        backdropView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        view.addSubview(backdropView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        backdropView.addGestureRecognizer(tap)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 16
        cardView.clipsToBounds = true
        view.addSubview(cardView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        bodyTextView.isEditable = false
        bodyTextView.isScrollEnabled = true
        bodyTextView.backgroundColor = .clear
        bodyTextView.textColor = .label
        bodyTextView.font = .systemFont(ofSize: 14)
        bodyTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        qrImageView.contentMode = .scaleAspectFit

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setTitle("Share", for: .normal)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [shareButton, closeButton])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 12

        cardView.addSubview(titleLabel)
        cardView.addSubview(bodyTextView)
        cardView.addSubview(qrImageView)
        cardView.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            backdropView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.82),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            qrImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            qrImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            qrImageView.widthAnchor.constraint(equalToConstant: 160),
            qrImageView.heightAnchor.constraint(equalToConstant: 160),

            bodyTextView.topAnchor.constraint(equalTo: qrImageView.bottomAnchor, constant: 12),
            bodyTextView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            bodyTextView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            buttonStack.topAnchor.constraint(equalTo: bodyTextView.bottomAnchor, constant: 12),
            buttonStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 44),
            buttonStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }

    private func configure() {
        titleLabel.text = receiptTitleText
        bodyTextView.text = receiptBodyText
        qrImageView.image = makeQRCode(from: qrPayload)
    }

    private func makeQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaled = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    @objc private func closeTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }

    @objc private func shareTapped() {
        var items: [Any] = [receiptBodyText]
        if let img = qrImageView.image {
            items.append(img)
        }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = shareButton
            pop.sourceRect = shareButton.bounds
        }
        present(vc, animated: true)
    }
}
