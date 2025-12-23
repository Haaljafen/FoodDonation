//
//  DashboardViewController.swift
//  Takaffal
//
//  Created by Noora Humaid on 22/12/2025.
//
import UIKit
import FirebaseFirestore
import FirebaseAuth
import Charts
import DGCharts

final class DashboardViewController: BaseChromeViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var section1TitleLabe: UILabel!
    @IBOutlet weak var section2TitleLabe: UILabel!
    @IBOutlet weak var statTitle1Label: UILabel!
    @IBOutlet weak var statValue1Label: UILabel!
    @IBOutlet weak var statTitle2Label: UILabel!
    @IBOutlet weak var statValue2Label: UILabel!
    @IBOutlet weak var statTitle3Label: UILabel!
    @IBOutlet weak var statValue3Label: UILabel!
    @IBOutlet weak var pieChartView: PieChartView!

    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let testUID: String? = "jOUkkHYArvYZvO5WAU0bgtHsqbN2" // set to nil after when done testing
    

    private var currentUID: String? {
        return testUID ?? Auth.auth().currentUser?.uid
    }

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        
        super.viewDidLoad()
        deleteDonation(donationId: "B1C0F755-2745-482F-B5ED-91527EF8F23B")

        
//                DonationInsert.insertTestDonation()

        setupPieChart()
        loadDashboard()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Load Role Based Dashboard

    private func loadDashboard() {
        guard let uid = currentUID else { return }

        db.collection("Users").document(uid).getDocument { snapshot, _ in
            guard let role = snapshot?["role"] as? String else { return }

            switch role {
            case "donor":
                self.loadDonorDashboard(uid: uid)
            case "ngo":
                self.loadNGODashboard(uid: uid)
            case "admin":
                self.loadAdminDashboard()
            default:
                break
            }
        }
    }

    
    // MARK: - DONOR DASHBOARD
    private func loadDonorDashboard(uid: String) {
        
        section1TitleLabe.text = "Your Impact"
        section2TitleLabe.text = "Your Impact Distribution"

        statTitle1Label.text = "Total Donations"
        statTitle3Label.text = "Total Impact Types"
        statTitle2Label.text = "Total Categories"
        
        listener = db.collection("donations")
            .whereField("donorId", isEqualTo: uid)
            .addSnapshotListener { snapshot, _ in
                
                let docs = snapshot?.documents ?? []
                
                let totalDonations = docs.count
//                let totalImpact = docs.reduce(0) { $0 + ($1["impactValue"] as? Int ?? 0) }
                let categories = Set(docs.compactMap { $0["category"] as? String })
                
                self.statValue1Label.text = "\(totalDonations)"
                self.statValue3Label.text = "\(Set(docs.compactMap { $0["impactType"] as? String }).count)"
                self.statValue2Label.text = "\(categories.count)"
                
                self.updateImpactChart(docs)
            }
    }
    
    // MARK: - NGO DASHBOARD
    private func loadNGODashboard(uid: String) {
        
        section1TitleLabe.text = "Your Impact"
        section2TitleLabe.text = "Your Impact Distribution"


        statTitle1Label.text = "Accepted Donations"
        statTitle2Label.text = "Collected Donations"
        statTitle3Label.text = "Delivered Donations"
        
        listener = db.collection("donations")
            .whereField("ngoId", isEqualTo: uid)
            .addSnapshotListener { snapshot, _ in
                
                let docs = snapshot?.documents ?? []
                
                let accepted = docs.filter { $0["status"] as? String == "accepted" }.count
                let collected = docs.filter { $0["status"] as? String == "collected" }.count
                let delivered = docs.filter { $0["status"] as? String == "delivered" }.count
                
                self.statValue1Label.text = "\(accepted)"
                self.statValue2Label.text = "\(collected)"
                self.statValue3Label.text = "\(delivered)"
                
                let acceptedDocs = docs.filter { $0["status"] as? String == "accepted" }
                self.updateImpactChart(acceptedDocs)
            }
    }
    
    // MARK: - ADMIN DASHBOARD
    private func loadAdminDashboard() {
        
        section1TitleLabe.text = "Takaffal Users"
        section2TitleLabe.text = "User's Impact Distribution"


        statTitle1Label.text = "Total Donors"
        statTitle2Label.text = "Total NGOs"
        statTitle3Label.text = "Total Donations"
        
        db.collection("Users").whereField("role", isEqualTo: "donor")
            .addSnapshotListener { snap, _ in
                self.statValue1Label.text = "\(snap?.documents.count ?? 0)"
            }
        
        db.collection("Users").whereField("role", isEqualTo: "ngo")
            .addSnapshotListener { snap, _ in
                self.statValue2Label.text = "\(snap?.documents.count ?? 0)"
            }
        
        listener = db.collection("donations")
            .addSnapshotListener { snapshot, _ in
                let docs = snapshot?.documents ?? []
                self.statValue3Label.text = "\(docs.count)"
                self.updateImpactChart(docs)
            }
    }
    
    // MARK: - Chart Setup
    
    private func setupPieChart() {
        guard let pieChartView else {
            assertionFailure("❌ pieChartView outlet is nil")
            return
        }

        pieChartView.usePercentValuesEnabled = true
        pieChartView.drawEntryLabelsEnabled = false
        pieChartView.legend.enabled = false
        pieChartView.legend.form = .none
        pieChartView.holeRadiusPercent = 0.55
        pieChartView.transparentCircleRadiusPercent = 0.6
        pieChartView.chartDescription.enabled = false
    }



    
    // MARK: - Impact Percentage Chart
    private func updateImpactChart(_ docs: [QueryDocumentSnapshot]) {

        var impactCounts: [DonationType: Int] = [:]
        DonationType.allCases.forEach { impactCounts[$0] = 0 }

        docs.forEach {
            guard let raw = $0["impactType"] as? String,
                  let type = DonationType(rawValue: raw) else { return }
            impactCounts[type, default: 0] += 1
        }

        let total = impactCounts.values.reduce(0, +)
        guard total > 0 else {
            pieChartView.data = nil
            return
        }

        let entries = DonationType.allCases.compactMap { type -> PieChartDataEntry? in
            guard let count = impactCounts[type], count > 0 else { return nil }
            let percent = Double(count) / Double(total) * 100
            return PieChartDataEntry(value: percent, label: type.rawValue)
        }

        let dataSet = PieChartDataSet(entries: entries, label: "")
        dataSet.colors = [
            UIColor(hex: "B35D4C"),
            UIColor(hex: "DF9B6D"),
            UIColor(hex: "738290")
        ]
        dataSet.valueTextColor = .white
        dataSet.valueFont = .boldSystemFont(ofSize: 12)

        let data = PieChartData(dataSet: dataSet)
        data.setValueFormatter(DefaultValueFormatter(decimals: 0))

        pieChartView.data = data
        
        pieChartView.legend.enabled = false

        pieChartView.notifyDataSetChanged()
    }

}






//graph chart
//import UIKit
//import FirebaseFirestore
//import FirebaseAuth
//import Charts
//import DGCharts
//
//final class DashboardViewController: BaseChromeViewController {
//    
//    // MARK: - Outlets
//    @IBOutlet weak var statTitle1Label: UILabel!
//    @IBOutlet weak var statValue1Label: UILabel!
//    @IBOutlet weak var statTitle2Label: UILabel!
//    @IBOutlet weak var statValue2Label: UILabel!
//    @IBOutlet weak var statTitle3Label: UILabel!
//    @IBOutlet weak var statValue3Label: UILabel!
//    @IBOutlet weak var barChartView: BarChartView!
//    
//    
//    // MARK: - Properties
//    private let db = Firestore.firestore()
//    private var listener: ListenerRegistration?
////    private let uid = Auth.auth().currentUser?.uid
//    private let testUID: String? = "jOUkkHYArvYZvO5WAU0bgtHsqbN2" /// set to nil when done testing
//    
////delete it later
//    private var currentUID: String? {
//        return testUID ?? Auth.auth().currentUser?.uid
//    }
////
//    
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//                DonationInsert.insertTestDonation()
//
//        setupChart()
//        loadDashboard()
//    }
//    
//    deinit {
//        listener?.remove()
//    }
//    
//    // MARK: - Load Role Based Dashboard
////    private func loadDashboard() {
////        guard let uid else { return }
////
////        db.collection("users").document(uid).getDocument { snapshot, _ in
////            guard let role = snapshot?["role"] as? String else { return }
////
////            switch role {
////            case "donor":
////                self.loadDonorDashboard(uid: uid)
////            case "ngo":
////                self.loadNGODashboard(uid: uid)
////            case "admin":
////                self.loadAdminDashboard()
////            default:
////                break
////            }
////        }
////    }
//    private func loadDashboard() {
//        guard let uid = currentUID else { return }
//
//        db.collection("Users").document(uid).getDocument { snapshot, _ in
//            guard let role = snapshot?["role"] as? String else { return }
//
//            switch role {
//            case "donor":
//                self.loadDonorDashboard(uid: uid)
//            case "ngo":
//                self.loadNGODashboard(uid: uid)
//            case "admin":
//                self.loadAdminDashboard()
//            default:
//                break
//            }
//        }
//    }
//
//    
//    // MARK: - DONOR DASHBOARD
//    private func loadDonorDashboard(uid: String) {
//        statTitle1Label.text = "My Donations"
//        statTitle2Label.text = "Impact Types"
//        statTitle3Label.text = "Categories"
//        
//        listener = db.collection("donations")
//            .whereField("donorId", isEqualTo: uid)
//            .addSnapshotListener { snapshot, _ in
//                
//                let docs = snapshot?.documents ?? []
//                
//                let totalDonations = docs.count
//                let totalImpact = docs.reduce(0) { $0 + ($1["impactValue"] as? Int ?? 0) }
//                let categories = Set(docs.compactMap { $0["category"] as? String })
//                
//                self.statValue1Label.text = "\(totalDonations)"
//                self.statValue2Label.text = "\(Set(docs.compactMap { $0["impactType"] as? String }).count)"
//                self.statValue3Label.text = "\(categories.count)"
//                
//                self.updateImpactChart(docs)
//            }
//    }
//    
//    // MARK: - NGO DASHBOARD
//    private func loadNGODashboard(uid: String) {
//        statTitle1Label.text = "Accepted"
//        statTitle2Label.text = "Collected"
//        statTitle3Label.text = "Delivered"
//        
//        listener = db.collection("donations")
//            .whereField("ngoId", isEqualTo: uid)
//            .addSnapshotListener { snapshot, _ in
//                
//                let docs = snapshot?.documents ?? []
//                
//                let accepted = docs.filter { $0["status"] as? String == "accepted" }.count
//                let collected = docs.filter { $0["status"] as? String == "collected" }.count
//                let delivered = docs.filter { $0["status"] as? String == "delivered" }.count
//                
//                self.statValue1Label.text = "\(accepted)"
//                self.statValue2Label.text = "\(collected)"
//                self.statValue3Label.text = "\(delivered)"
//                
//                let acceptedDocs = docs.filter { $0["status"] as? String == "accepted" }
//                self.updateImpactChart(acceptedDocs)
//            }
//    }
//    
//    // MARK: - ADMIN DASHBOARD
//    private func loadAdminDashboard() {
//        statTitle1Label.text = "Total Donors"
//        statTitle2Label.text = "Total NGOs"
//        statTitle3Label.text = "Total Donations"
//        
//        db.collection("Users").whereField("role", isEqualTo: "donor")
//            .addSnapshotListener { snap, _ in
//                self.statValue1Label.text = "\(snap?.documents.count ?? 0)"
//            }
//        
//        db.collection("Users").whereField("role", isEqualTo: "ngo")
//            .addSnapshotListener { snap, _ in
//                self.statValue2Label.text = "\(snap?.documents.count ?? 0)"
//            }
//        
//        listener = db.collection("donations")
//            .addSnapshotListener { snapshot, _ in
//                let docs = snapshot?.documents ?? []
//                self.statValue3Label.text = "\(docs.count)"
//                self.updateImpactChart(docs)
//            }
//    }
//    
//    // MARK: - Chart Setup
////    private func setupChart() {
////        barChartView.legend.enabled = false
////        barChartView.rightAxis.enabled = false
////        barChartView.xAxis.labelPosition = .bottom
////        barChartView.xAxis.drawGridLinesEnabled = false
////    }
//    
//    private func setupChart() {
//        guard let barChartView else {
//            assertionFailure("❌ barChartView outlet is nil")
//            return
//        }
//
//        barChartView.legend.enabled = false
//        barChartView.rightAxis.enabled = false
//        barChartView.xAxis.labelPosition = .bottom
//        barChartView.xAxis.drawGridLinesEnabled = false
//    }
//
//    
//    // MARK: - Impact Percentage Chart
//    private func updateImpactChart(_ docs: [QueryDocumentSnapshot]) {
//        
//        var impactCounts: [DonationType: Int] = [:]
//        DonationType.allCases.forEach { impactCounts[$0] = 0 }
//        
//        docs.forEach {
//            guard let raw = $0["impactType"] as? String,
//                  let type = DonationType(rawValue: raw) else { return }
//            impactCounts[type, default: 0] += 1
//        }
//        
//        let total = impactCounts.values.reduce(0, +)
//        guard total > 0 else {
//            barChartView.data = nil
//            return
//        }
//        
//        let entries = DonationType.allCases.enumerated().map { index, type in
//            let percent = Double(impactCounts[type] ?? 0) / Double(total) * 100
//            return BarChartDataEntry(x: Double(index), y: percent)
//        }
//        
//        let dataSet = BarChartDataSet(entries: entries, label: "Impact %")
//        dataSet.colors = [.systemRed, .systemGreen, .systemOrange]
//        dataSet.valueFormatter = DefaultValueFormatter(decimals: 0)
//        
//        barChartView.data = BarChartData(dataSet: dataSet)
//        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(
//            values: DonationType.allCases.map { $0.rawValue }
//        )
//    }
//}
//
//
