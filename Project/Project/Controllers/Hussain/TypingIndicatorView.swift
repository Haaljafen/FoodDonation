import UIKit

class TypingIndicatorView: UIView {

    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        animate()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        animate()
    }

    private func setup() {
        let stack = UIStackView(arrangedSubviews: [dot1, dot2, dot3])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center

        [dot1, dot2, dot3].forEach {
            $0.backgroundColor = .white
            $0.layer.cornerRadius = 4
            $0.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $0.widthAnchor.constraint(equalToConstant: 8),
                $0.heightAnchor.constraint(equalToConstant: 8)
            ])
        }

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func animate() {
        let dots = [dot1, dot2, dot3]

        for (i, dot) in dots.enumerated() {
            UIView.animate(
                withDuration: 0.6,
                delay: Double(i) * 0.2,
                options: [.repeat, .autoreverse],
                animations: {
                    dot.alpha = 0.3
                }
            )
        }
    }
}
