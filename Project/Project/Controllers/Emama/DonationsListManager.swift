//import UIKit
//
//enum Role {
//    case admin, ngo, donor
//}
//
//class DonationsListManager: NSObject {
//
//    // MARK: - Properties
//    private let searchContainer: UIView
//    private let filterContainer: UIView
//    private let tableView: UITableView
//    private let currentRole: Role
//    private let currentUserId: String
//
//    private var allItems: [Donation] = []
//    private var filteredItems: [Donation] = []
//
//    private var searchText = ""
//    private var selectedFilter = "All"
//
//    // MARK: - Init
//    init(searchContainer: UIView,
//         filterContainer: UIView,
//         tableView: UITableView,
//         role: Role,
//         currentUserId: String) {
//
//        self.searchContainer = searchContainer
//        self.filterContainer = filterContainer
//        self.tableView = tableView
//        self.currentRole = role
//        self.currentUserId = currentUserId
//        super.init()
//        setup()
//    }
//
//    // MARK: - Setup
//    private func setup() {
//        loadSearchBar()
//        loadFilterBar()
//        fetchData()
//    }
//
//    // MARK: - Load XIBs
//    private func loadSearchBar() {
//        let searchBar: SearchBarView = SearchBarView.fromNib()
//        searchBar.delegate = self
//        searchContainer.addSubview(searchBar)
//        searchBar.frame = searchContainer.bounds
//    }
//
//    private func loadFilterBar() {
//        let filterBar: FilterBarView = FilterBarView.fromNib()
//        filterBar.delegate = self
//        filterContainer.addSubview(filterBar)
//        filterBar.frame = filterContainer.bounds
//
//        // Configure filters
//        switch currentRole {
//        case .admin, .ngo:
//            filterBar.configure(filters: ["All", "A to Z", "Z to A"])
//        case .donor:
//            filterBar.configure(filters: ["All", "Pending", "Accepted", "Completed"])
//        }
//    }
//
//    // MARK: - Fetch Firestore
//    private func fetchData() {
//        DonationService.fetchDonations { [weak self] donations in
//            guard let self = self else { return }
//
//            switch self.currentRole {
//            case .admin:
//                self.allItems = donations
//            case .ngo:
//                self.allItems = donations.filter { $0.collectorId == self.currentUserId }
//            case .donor:
//                self.allItems = donations.filter { $0.donorId == self.currentUserId }
//            }
//
//            self.applyFilters()
//        }
//    }
//
//    // MARK: - Apply Filters
//    private func applyFilters() {
//        filteredItems = allItems
//
//        // SEARCH
//        if !searchText.isEmpty {
//            filteredItems = filteredItems.filter {
//                $0.item.lowercased().contains(searchText.lowercased()) ||
//                $0.category.lowercased().contains(searchText.lowercased())
//            }
//        }
//
//        // FILTER
//        if currentRole == .donor && selectedFilter != "All" {
//            filteredItems = filteredItems.filter {
//                $0.status.lowercased() == selectedFilter.lowercased()
//            }
//        }
//
//        if selectedFilter == "A to Z" {
//            filteredItems.sort { $0.item < $1.item }
//        } else if selectedFilter == "Z to A" {
//            filteredItems.sort { $0.item > $1.item }
//        }
//
//        tableView.reloadData()
//    }
//}
//
//// MARK: - SearchBarViewDelegate
//extension DonationsListManager: SearchBarViewDelegate {
//    func didSearch(text: String) {
//        searchText = text
//        applyFilters()
//    }
//}
//
//// MARK: - FilterBarViewDelegate
//extension DonationsListManager: FilterBarViewDelegate {
//    func didSelectFilter(_ filter: String) {
//        selectedFilter = filter
//        applyFilters()
//    }
//}
