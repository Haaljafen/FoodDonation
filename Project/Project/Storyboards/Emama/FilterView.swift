import UIKit

enum FilterType {
    case foodCategories
    case donorHistory
    case ngoBrowsing
    case adminUserManagement // For the White toggle style
}

protocol FilterViewDelegate: AnyObject {
    func didSelectCategory(_ category: String)
}

class FilterView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    weak var delegate: FilterViewDelegate?
    
    private var currentType: FilterType = .foodCategories

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
        self.currentType = type
        
        // Find the template button you designed in the XIB
        guard let templateButton = stackView.arrangedSubviews.first as? UIButton else { return }
        templateButton.isHidden = true
        
        // Remove old buttons but keep the hidden template
        stackView.arrangedSubviews.forEach { if $0 != templateButton { $0.removeFromSuperview() } }

        let categories: [String]
        switch type {
        case .foodCategories: categories = ["All", "Meals", "Beverages", "Bakery"]
        case .donorHistory: categories = ["All", "Pending", "Accepted"]
        case .ngoBrowsing: categories = ["All", "A to Z", "Z to A"]
        case .adminUserManagement: categories = ["NGO", "Doner"]
        }

        for title in categories {
            let newButton = UIButton(type: .system)
            
            // Set Base Colors
            if type == .adminUserManagement {
                newButton.backgroundColor = .white
                newButton.setTitleColor(UIColor(red: 26/255, green: 71/255, blue: 112/255, alpha: 1.0), for: .normal)
            } else {
                newButton.backgroundColor = templateButton.backgroundColor
                newButton.setTitleColor(.white, for: .normal)
            }
            
            newButton.layer.cornerRadius = templateButton.layer.cornerRadius
            newButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            newButton.setTitle(title, for: .normal)
            newButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            
            newButton.addTarget(self, action: #selector(btnTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(newButton)
        }
        
        // Select first button by default
        if let firstBtn = stackView.arrangedSubviews.filter({ !$0.isHidden }).first as? UIButton {
            applySelectedStyle(to: firstBtn)
        }
    }

    @objc func btnTapped(_ sender: UIButton) {
        // Reset all buttons to unselected state
        stackView.arrangedSubviews.forEach { subview in
            if let btn = subview as? UIButton {
                if currentType == .adminUserManagement {
                    btn.backgroundColor = .white
                    btn.setTitleColor(UIColor(red: 26/255, green: 71/255, blue: 112/255, alpha: 1.0), for: .normal)
                } else {
                    btn.backgroundColor = UIColor(red: 26/255, green: 71/255, blue: 112/255, alpha: 1.0)
                    btn.setTitleColor(.white, for: .normal)
                }
                btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            }
        }
        
        applySelectedStyle(to: sender)
        delegate?.didSelectCategory(sender.titleLabel?.text ?? "")
    }
    
    private func applySelectedStyle(to button: UIButton) {
        if currentType == .adminUserManagement {
            button.backgroundColor = UIColor(white: 0.95, alpha: 1.0) // Light gray highlight
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        } else {
            button.backgroundColor = .systemBlue
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        }
    }
}
