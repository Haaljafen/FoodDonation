//
//  ChatCell.swift
//  AI
//
//  Created by wny on 24/12/2025.
//

import UIKit

class ChatCell: UITableViewCell {
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var bubbleView: UIView!
    
    private var bubbleLeading: NSLayoutConstraint!
    private var bubbleTrailing: NSLayoutConstraint!
    private var bubbleWidth: NSLayoutConstraint!
    
    private var didSetupConstraints = false

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
       // bubbleView?.layer.cornerRadius = 16
       // bubbleView?.layer.masksToBounds = true
        
        messageLabel?.numberOfLines = 0
        messageLabel?.lineBreakMode = .byWordWrapping
        
        setupConstraintsIfNeeded()
    
        // Initialization code
    }
    
    //MARK: -
    
    private func setupConstraintsIfNeeded(){
        guard let messageLabel = messageLabel,
                let bubbleView = bubbleView,
            !didSetupConstraints else {return}
        
        
        
        didSetupConstraints = true
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant:  12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
        ])
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
        
        bubbleLeading = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        
        bubbleTrailing = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        bubbleWidth = bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        
        bubbleWidth?.isActive = true
 
        
    }
    
    
    
    // MARK: - Reuse
    
    override func prepareForReuse(){
        super.prepareForReuse()
       // messageLabel?.text = nil
        bubbleLeading?.isActive = false
        bubbleTrailing?.isActive = false
        
    
    }
    
    // MARK: - Configure
    
    func configure(text: String, isUser:Bool){
        messageLabel?.text = text
        
        bubbleLeading?.isActive = false
        bubbleTrailing?.isActive = false
        
        bubbleView?.layer.cornerRadius = 16
        
        
        if isUser{
            bubbleTrailing?.isActive = true
            bubbleView?.backgroundColor = .systemBlue
            messageLabel?.textColor = .white
            
            bubbleView?.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
                
            ]
         
        }else {
            bubbleLeading?.isActive = true
            bubbleView?.backgroundColor = .systemGray
            messageLabel?.textColor = .white
            
            bubbleView?.layer.maskedCorners = [
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
          
        }
        
        
        //contentView.setNeedsLayout()
        //contentView.layoutIfNeeded()
       // self.setNeedsLayout()
    }
    
    
    func configureTyping(_ isTyping: Bool) {

        // remove any old typing indicator
        bubbleView.subviews.forEach {
            if $0 is TypingIndicatorView {
                $0.removeFromSuperview()
            }
        }

        if isTyping {
            // hide message
            messageLabel.isHidden = true

            // ❌ hide bubble background
            bubbleView.backgroundColor = .clear
            bubbleView.layer.cornerRadius = 0

            let dots = TypingIndicatorView()
            dots.translatesAutoresizingMaskIntoConstraints = false
            bubbleView.addSubview(dots)

            NSLayoutConstraint.activate([
                dots.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor),
                dots.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
                dots.widthAnchor.constraint(equalToConstant: 40),
                dots.heightAnchor.constraint(equalToConstant: 20)
            ])

        } else {
            // show message again
            messageLabel.isHidden = false
        }
    }

        // Configure the view for the selected state

}
