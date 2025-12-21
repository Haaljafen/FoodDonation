//
//  ProfileViewController.swift
//  Takaffal
//
//  Created by Mariam Sharaf on 20/12/2025.
//

import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var navContainer: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        loadHeader()
        loadNav()

    }
    
    private func loadHeader() {
        guard let header = Bundle.main
            .loadNibNamed("HeaderView", owner: nil, options: nil)?
            .first as? HeaderView else {
            print("HeaderView not loaded")
            return
        }

        header.frame = headerContainer.bounds
        header.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        header.backBtn.isHidden = true
        header.takaffalLabel.text = "Profile"
        header.search.isHidden = true
        headerContainer.addSubview(header)
    }
    
    
    private func loadNav() {
        guard let nav = Bundle.main
            .loadNibNamed("BottomNavView", owner: nil, options: nil)?
            .first as? BottomNavView else {
            print("BottomNavView not loaded")
            return
        }

        nav.frame = navContainer.bounds
        nav.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        navContainer.addSubview(nav)
    }

    
}
