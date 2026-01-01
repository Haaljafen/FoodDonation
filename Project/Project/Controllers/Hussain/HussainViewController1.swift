//
//  ViewController.swift
//  scroll view practice
//
//  Created by wny on 15/12/2025.
//

import UIKit

class HussainViewController1: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var badge1: UIView!
    @IBOutlet weak var badge2: UIView!
    @IBOutlet weak var badge3: UIView!
    @IBOutlet weak var badge4: UIView!
    @IBOutlet weak var badge5: UIView!
    @IBOutlet weak var badge6: UIView!
    @IBOutlet weak var badge7: UIView!
    @IBOutlet weak var badge8: UIView!
    @IBOutlet weak var badge9: UIView!
    @IBOutlet weak var badge10: UIView!
    
    @IBOutlet weak var viewsDate: UIView!
    @IBOutlet weak var viewsDate2: UIView!
    @IBOutlet weak var viewsDate3: UIView!
    @IBOutlet weak var viewsDate4: UIView!
    @IBOutlet weak var viewsDate5: UIView!
    @IBOutlet weak var viewsDate6: UIView!
    @IBOutlet weak var viewsDate7: UIView!
    @IBOutlet weak var viewsDate8: UIView!
    @IBOutlet weak var viewsDate9: UIView!
    @IBOutlet weak var viewsDate10: UIView!
    
    @IBOutlet weak var countUnlocked: UILabel!
    @IBOutlet weak var progress1: UIProgressView!
    @IBOutlet weak var progress2: UIProgressView!
    @IBOutlet weak var progress3: UIProgressView!
    @IBOutlet weak var progress4: UIProgressView!
    @IBOutlet weak var progress5: UIProgressView!
    @IBOutlet weak var progress6: UIProgressView!
    @IBOutlet weak var progress7: UIProgressView!
    @IBOutlet weak var progress8: UIProgressView!
    @IBOutlet weak var progress9: UIProgressView!
    @IBOutlet weak var progress10: UIProgressView!
    
    @IBOutlet weak var unlockDate1: UILabel!
    @IBOutlet weak var unlockDate2: UILabel!
    @IBOutlet weak var unlockDate3: UILabel!
    @IBOutlet weak var unlockDate4: UILabel!
    @IBOutlet weak var unlockDate5: UILabel!
    @IBOutlet weak var unlockDate6: UILabel!
    @IBOutlet weak var unlockDate7: UILabel!
    @IBOutlet weak var unlockDate8: UILabel!
    @IBOutlet weak var unlockDate9: UILabel!
    @IBOutlet weak var unlockDate10: UILabel!
    
    @IBOutlet weak var imageBadge1: UIImageView!
    @IBOutlet weak var imageBadge2: UIImageView!
    @IBOutlet weak var imageBadge3: UIImageView!
    @IBOutlet weak var imageBadge4: UIImageView!
    @IBOutlet weak var imageBadge5: UIImageView!
    @IBOutlet weak var imageBadge6: UIImageView!
    @IBOutlet weak var imageBadge7: UIImageView!
    @IBOutlet weak var imageBadge8: UIImageView!
    @IBOutlet weak var imageBadge9: UIImageView!
    @IBOutlet weak var imageBadge10: UIImageView!
    
    @IBOutlet weak var headerView: UIView!
    
    
    
    // MARK: - Lifecycle
      override func viewDidLoad() {
          super.viewDidLoad()
          self.title = "Achievements"
          setupBadges()
          updateUnlockedCount()
          
          headerView.layer.cornerRadius = 36
          headerView.layer.maskedCorners = [
            .layerMinXMaxYCorner,
            .layerMaxXMaxYCorner
          ]
      }
      
      override func viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated)
          // 🔹 NEW: Refresh progress from real data
          refreshAchievementsFromData()
      }
      
      // MARK: - Setup Badges
      private func setupBadges() {
          let badges = [
              (badge1, viewsDate),
              (badge2, viewsDate2),
              (badge3, viewsDate3),
              (badge4, viewsDate4),
              (badge5, viewsDate5),
              (badge6, viewsDate6),
              (badge7, viewsDate7),
              (badge8, viewsDate8),
              (badge9, viewsDate9),
              (badge10, viewsDate10)
          ]
          
          for (badge, dateView) in badges {
              if let badge = badge, let dateView = dateView {
                  badge.layer.cornerRadius = 18
                  badge.layer.masksToBounds = true
                  
                  //shadow
                  addSolidShadow(to: badge)
                  
                  //overlay
                  let overlay = UIView(frame: badge.bounds)
                  overlay.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
                  overlay.layer.cornerRadius = badge.layer.cornerRadius
                  overlay.isUserInteractionEnabled = false
                  overlay.tag = 999
                  overlay.isHidden = true
                  badge.addSubview(overlay)
                  
                  //progress - date UIVIEW corner radius
                  dateView.layer.cornerRadius = 18
                  dateView.layer.masksToBounds = true
                  dateView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner]
              }
          }
          
          // Hide all unlock labels initially
          let unlockLabels = [unlockDate1, unlockDate2, unlockDate3, unlockDate4, unlockDate5,
                              unlockDate6, unlockDate7, unlockDate8, unlockDate9, unlockDate10]
          for label in unlockLabels {
              label?.isHidden = true
          }
          
          // Set all badge images to lock icon initially
          let badgeImages = [imageBadge1, imageBadge2, imageBadge3, imageBadge4, imageBadge5,
                             imageBadge6, imageBadge7, imageBadge8, imageBadge9, imageBadge10]
          for imageView in badgeImages {
              imageView?.image = UIImage(named: "lock_icon")
          }
      }
      
      // MARK: - Solid Shadow Func
      func addSolidShadow(to badge: UIView, offset: CGSize = CGSize(width: 0, height: 5), radius: CGFloat = 0, opacity: Float = 1.0) {
          let shadowColor = UIColor(red: 0xAC/255.0, green: 0x79/255.0, blue: 0x57/255.0, alpha: 1.0)
          badge.layer.masksToBounds = false
          badge.layer.shadowColor = shadowColor.cgColor
          badge.layer.shadowOffset = offset
          badge.layer.shadowRadius = radius
          badge.layer.shadowOpacity = opacity
          badge.layer.shadowPath = UIBezierPath(roundedRect: badge.bounds, cornerRadius: badge.layer.cornerRadius).cgPath
      }
      
      // MARK: - Progress & Badge Logic
      func setProgress(_ value: Float, for progressBar: UIProgressView?, badge: UIView?, imageBadge: UIImageView?, unlockLabel: UILabel?) {
          guard let progressBar = progressBar, let badge = badge else { return }
          
          let clamped = min(max(value, 0.0), 1.0)
          progressBar.progress = clamped
          updateBadge(badge: badge, progressBar: progressBar, progressValue: clamped, imageBadge: imageBadge, unlockLabel: unlockLabel)
          updateUnlockedCount()
      }
      
      private func updateBadge(badge: UIView, progressBar: UIProgressView, progressValue: Float, imageBadge: UIImageView?, unlockLabel: UILabel?) {
          let unlocked = progressValue >= 1.0
          
          if let overlay = badge.viewWithTag(999) {
              overlay.isHidden = unlocked
          }
          
          progressBar.isHidden = unlocked
          
          if let imageView = imageBadge {
              imageView.image = UIImage(named: unlocked ? "badge_icon" : "lock_icon")
          }
          
          if let label = unlockLabel {
              if unlocked {
                  let formatter = DateFormatter()
                  formatter.dateStyle = .medium
                  let dateString = formatter.string(from: Date())
                  label.text = "Unlocked on \(dateString)"
                  label.isHidden = false
              } else {
                  label.isHidden = true
              }
          }
      }
      
      private func updateUnlockedCount() {
          let progressBars = [progress1, progress2, progress3, progress4, progress5,
                              progress6, progress7, progress8, progress9, progress10]
          let validProgressBars = progressBars.compactMap { $0 }
          let unlockedCount = progressBars.filter { $0?.progress ?? 0 >= 1.0 }.count
          let total = validProgressBars.count
          countUnlocked.text = "\(unlockedCount) of \(total) unlocked"
      }
      
      // MARK: - 🔹 NEW FUNCTIONS: ACHIEVEMENT DATA BINDING
      
      private func refreshAchievementsFromData() {
          let m = AchievementManager.shared
          
          let progresses: [Float] = [
              m.collectionsCompleted >= 1 ? 1.0 : 0.0,          // 1: First Step
              min(Float(m.donationCount) / 10.0, 1.0),          // 2: Food Warrior
              min(Float(m.mealsProvided) / 30.0, 1.0),          // 3: Impact Maker
              min(Float(m.uniqueNGOs.count) / 3.0, 1.0),        // 4: Variety Giver
              min(Float(m.donationCount) / 20.0, 1.0),          // 5: Zero Waste Saver
              min(Float(m.mealsProvided) / 60.0, 1.0),          // 6: Community Hero
              min(Float(m.weeklyStreak()) / 2.0, 1.0),          // 7: Community Contributor
              min(Float(m.monthlyStreak()) / 6.0, 1.0),         // 8: Monthly Supporter
              min(Float(m.weeklyStreak()) / 9.0, 1.0),          // 9: Weekly Giver
              min(Float(m.mealsProvided) / 250.0, 1.0)          // 10: Takafal Legend
          ]
          
          applyProgress(progresses)
      }
      
      private func applyProgress(_ progresses: [Float]) {
          let progressBars = [progress1, progress2, progress3, progress4, progress5,
                              progress6, progress7, progress8, progress9, progress10]
          
          let badges = [badge1, badge2, badge3, badge4, badge5,
                        badge6, badge7, badge8, badge9, badge10]
          
          let images = [imageBadge1, imageBadge2, imageBadge3, imageBadge4, imageBadge5,
                        imageBadge6, imageBadge7, imageBadge8, imageBadge9, imageBadge10]
          
          let labels = [unlockDate1, unlockDate2, unlockDate3, unlockDate4, unlockDate5,
                        unlockDate6, unlockDate7, unlockDate8, unlockDate9, unlockDate10]
          
          for i in 0..<10 {
              let progress = progresses[i]
              
              if progress >= 1.0 {
                  AchievementManager.shared.saveUnlockDateIfNeeded(id: i + 1)
              }
              
              setProgress(
                  progress,
                  for: progressBars[i],
                  badge: badges[i],
                  imageBadge: images[i],
                  unlockLabel: labels[i]
              )
              
              if let date = AchievementManager.shared.unlockDate(for: i + 1) {
                  let formatter = DateFormatter()
                  formatter.dateStyle = .medium
                  labels[i]?.text = "Unlocked on \(formatter.string(from: date))"
              }
          }
      }
  }
