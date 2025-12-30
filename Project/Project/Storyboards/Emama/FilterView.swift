import UIKit

enum FilterType {
    case foodCategories
    case donorHistory
    case ngoBrowsing
}

protocol FilterViewDelegate: AnyObject {
    func didSelectCategory(_ category: String)
}

class FilterView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    weak var delegate: FilterViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("FilterView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func setupFilter(for type: FilterType) {
        // 1. Find your "Template" button inside the Stack View
        guard let templateButton = stackView.arrangedSubviews.first as? UIButton else { return }
        
        // 2. Hide the template so the "big blue block" disappears
        templateButton.isHidden = true
        
        // 3. Remove any dynamic buttons from previous runs, but keep the template
        stackView.arrangedSubviews.forEach { if $0 != templateButton { $0.removeFromSuperview() } }

        let categories: [String]
        switch type {
        case .foodCategories: categories = ["All", "Meals", "Beverages", "Bakery"]
        case .donorHistory: categories = ["All", "Pending", "Accepted"]
        case .ngoBrowsing: categories = ["All", "A to Z", "Z to A"]
        }

        for title in categories {
            let newButton = UIButton(type: .system)
            
            // --- COPIES YOUR STORYBOARD DESIGN ---
            newButton.backgroundColor = templateButton.backgroundColor
            newButton.setTitleColor(templateButton.titleColor(for: .normal), for: .normal)
            newButton.layer.cornerRadius = templateButton.layer.cornerRadius
            newButton.titleLabel?.font = templateButton.titleLabel?.font
            
            newButton.setTitle(title, for: .normal)
            
            // Adds padding so buttons aren't too small
            newButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            
            newButton.addTarget(self, action: #selector(btnTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(newButton)
        }
        
        // Bold the first button ("All") by default
        if let firstBtn = stackView.arrangedSubviews.last as? UIButton {
             firstBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        }
    }

    @objc func btnTapped(_ sender: UIButton) {
        // 1. Reset all buttons to regular font and original blue color
        stackView.arrangedSubviews.forEach { subview in
            if let btn = subview as? UIButton {
                btn.backgroundColor = UIColor(red: 26/255, green: 71/255, blue: 112/255, alpha: 1.0)
                btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            }
        }
        
        // 2. Highlight the clicked button with BOLD font and brighter blue
        sender.backgroundColor = .systemBlue
        sender.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        
        // 3. Inform the controller of the selection
        delegate?.didSelectCategory(sender.titleLabel?.text ?? "")
    }
}
