import UIKit
import SendbirdUIKit
import SendbirdChatSDK
import FirebaseAuth

class ChatListViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let channelListVC = SBUGroupChannelListViewController()

    private let supportGroupLabel: UILabel = {
        let label = UILabel()
        label.text = "Grow Your Support Group\nThe journey together is better."
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 2
        label.alpha = 0.7
        return label
    }()

    private var users: [SBUUser] = []
    private var filteredUsers: [SBUUser] = []
    private var isSearching = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupSearchBar()
        addTapGestureToDismissKeyboard()
    }

    private func setupSearchBar() {
        searchBar.placeholder = "Search users..."
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        navigationItem.titleView = searchBar
    }

    private func addTapGestureToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !tableView.frame.contains(location) {
            dismissKeyboardAndResetSearch()
        }
    }

    private func dismissKeyboardAndResetSearch() {
        searchBar.resignFirstResponder()
        if !tableView.isDragging && !tableView.isDecelerating {
            resetSearch()
        }
    }

    private func resetSearch() {
        if isSearching {
            searchBar.text = ""
            isSearching = false
            filteredUsers.removeAll()
            tableView.isHidden = true
            channelListVC.view.isHidden = false
            supportGroupLabel.isHidden = false
            tableView.reloadData()
        }
    }

    private func setupUI() {
        view.backgroundColor = .white

        // Add TableView for Search Results
        tableView.isHidden = true
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add Channel List VC
        addChild(channelListVC)
        view.addSubview(channelListVC.view)
        channelListVC.view.translatesAutoresizingMaskIntoConstraints = false
        channelListVC.didMove(toParent: self)
        
        // Add Support Group Label
        view.addSubview(supportGroupLabel)
        supportGroupLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([
            // TableView constraints
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Channel List VC constraints
            channelListVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            channelListVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            channelListVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            channelListVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Support Group Label constraints
            supportGroupLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            supportGroupLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            supportGroupLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            supportGroupLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
    }

    // MARK: - Search Bar Delegates
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        resetSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            resetSearch()
        } else {
            isSearching = true
            supportGroupLabel.isHidden = true
            channelListVC.view.isHidden = true
            tableView.isHidden = false
            fetchUsers(query: searchText)
        }
    }

    private func fetchUsers(query: String) {
        guard let currentUser = Auth.auth().currentUser else { return }

        let params = ApplicationUserListQueryParams()
        params.nicknameStartsWithFilter = query
        
        let userQuery = SendbirdChat.createApplicationUserListQuery(params: params)
        userQuery.loadNextPage { [weak self] users, error in
            guard let self = self, error == nil, let allUsers = users else { return }

            self.getExistingChannels { existingUserIds in
                self.filteredUsers = allUsers
                    .filter { !existingUserIds.contains($0.userId) }
                    .map { SBUUser(user: $0) }
                self.showSearchResults()
            }
        }
    }

    private func getExistingChannels(completion: @escaping ([String]) -> Void) {
        let query = GroupChannel.createMyGroupChannelListQuery { params in
            params.includeEmptyChannel = false
        }
        query.loadNextPage { channels, error in
            guard let channels = channels, error == nil else {
                completion([])
                return
            }

            let existingUserIds = channels.flatMap { $0.members.map { $0.userId } }
            completion(Set(existingUserIds).map { $0 })
        }
    }

    private func showSearchResults() {
        DispatchQueue.main.async {
            self.channelListVC.view.isHidden = true
            self.supportGroupLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }

    // MARK: - TableView Delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        let user = filteredUsers[indexPath.row]
        cell.textLabel?.text = user.nickname
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedUser = filteredUsers[indexPath.row]
        
        // Only dismiss keyboard without resetting search
        searchBar.resignFirstResponder()
        
        print("Selected User Details:")
        print("User ID: \(selectedUser.userId)")
        print("Nickname: \(selectedUser.nickname ?? "No nickname")")
        print("Profile URL: \(selectedUser.profileURL ?? "No profile URL")")
        
        let userDetailVC = UserDetailViewController(userId: selectedUser.userId)
        navigationController?.pushViewController(userDetailVC, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ChatListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: view)
        return !tableView.frame.contains(location)
    }
}
