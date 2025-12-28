//
//  DonationStatusActionCellTableViewCell.swift
//  Takaffal
//
//  Created by Noora Humaid on 19/12/2025.
//
//
import UIKit

final class DonationStatusActionCell: UITableViewCell {

    @IBOutlet weak var statusValueLabel: UILabel!
    @IBOutlet weak var changeStatusButton: UIButton!

    private var onChangeTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        changeStatusButton.layer.cornerRadius = 10
    }

    func configure(
        currentStatus: String,
        buttonTitle: String = "Change Status",
        onChangeTapped: @escaping () -> Void
    ) {
        statusValueLabel.text = currentStatus.capitalized
        changeStatusButton.setTitle(buttonTitle, for: .normal)
        self.onChangeTapped = onChangeTapped
    }

    @IBAction func changeTapped(_ sender: UIButton) {
        onChangeTapped?()
    }
    
    func setButton(title: String, enabled: Bool) {
        changeStatusButton.setTitle(title, for: .normal)
        changeStatusButton.isEnabled = enabled
        changeStatusButton.alpha = enabled ? 1.0 : 0.6
    }

}
