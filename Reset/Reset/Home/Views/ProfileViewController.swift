import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ProfileViewController: UIViewController {
    
    private var user: User?
    private var soberStatLabel: UILabel?
    private var resetsStatLabel: UILabel?
    private var longestStreakStatLabel: UILabel?
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 60
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.systemBrown.cgColor  // Changed to brown
        imageView.image = UIImage(named: "onboarding1")
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // Add shadow
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        imageView.layer.shadowRadius = 4
        imageView.layer.shadowOpacity = 0.2
        return imageView
    }()

    // Update the edit profile button color
    private let editProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit Profile", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBrown.cgColor  // Changed to brown
        button.tintColor = .systemBrown  // Changed to brown
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let gearImage = UIImage(systemName: "gearshape.fill", withConfiguration: config)
        button.setImage(gearImage, for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let statsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        // Add shadow
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var collectionView: UICollectionView!
    private var userPosts: [Post] = []
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemBlue
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        setupCollectionView()
        fetchUser()
        
        // Add notification observer
           NotificationCenter.default.addObserver(self,
                                                selector: #selector(refreshProfileImage),
                                                name: NSNotification.Name("ProfileImageUpdated"),
                                                object: nil)
    }
    
    @objc private func refreshProfileImage() {
        if let user = self.user {
            self.fetchProfileImage(from: user.imageURL)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add main components
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [profileImageView, usernameLabel, editProfileButton, settingsButton,
         statsContainerView, activityIndicator].forEach { contentView.addSubview($0) }
        
        statsContainerView.addSubview(statsStackView)
        
        // Create stat views
        let (soberStatView, soberLabel) = createStatView(title: "Sober Since", value: "0 Days")
        let (resetsStatView, resetsLabel) = createStatView(title: "Resets", value: "0")
        let (longestStreakStatView, longestStreakLabel) = createStatView(title: "Longest Streak", value: "0 Days")
        
        soberStatLabel = soberLabel
        resetsStatLabel = resetsLabel
        longestStreakStatLabel = longestStreakLabel
        
        [soberStatView, resetsStatView, longestStreakStatView].forEach { statsStackView.addArrangedSubview($0) }
        
        setupConstraints()
    }
    
    private func createStatView(title: String, value: String) -> (UIStackView, UILabel) {
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return (stackView, valueLabel)
    }
    
    private func setupConstraints() {
        let padding: CGFloat = 20
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            usernameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            usernameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            editProfileButton.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 12),
            editProfileButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            editProfileButton.widthAnchor.constraint(equalToConstant: 120),
            editProfileButton.heightAnchor.constraint(equalToConstant: 30),
            
            settingsButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            settingsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            statsContainerView.topAnchor.constraint(equalTo: editProfileButton.bottomAnchor, constant: 24),
            statsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            statsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            statsStackView.topAnchor.constraint(equalTo: statsContainerView.topAnchor, constant: 20),
            statsStackView.leadingAnchor.constraint(equalTo: statsContainerView.leadingAnchor, constant: padding),
            statsStackView.trailingAnchor.constraint(equalTo: statsContainerView.trailingAnchor, constant: -padding),
            statsStackView.bottomAnchor.constraint(equalTo: statsContainerView.bottomAnchor, constant: -20),
            
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    private func setupGestures() {
        let usernameTapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameLabelTapped))
        usernameLabel.addGestureRecognizer(usernameTapGesture)
        
        let profileImageTapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(profileImageTapGesture)
        
        settingsButton.addTarget(self, action: #selector(openSettingsView), for: .touchUpInside)
        editProfileButton.addTarget(self, action: #selector(profileImageTapped), for: .touchUpInside)
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (view.frame.size.width - 4) / 3, height: (view.frame.size.width - 4) / 3)
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.register(ProfilePostCollectionViewCell.self, forCellWithReuseIdentifier: ProfilePostCollectionViewCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: statsContainerView.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: view.frame.width), // Make it square
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func usernameLabelTapped() {
        let changeUsernameVC = ChangeUsernameViewController()
        present(changeUsernameVC, animated: true)
    }
    
    @objc private func openSettingsView() {
        let settingsVC = UINavigationController(rootViewController: SettingsViewController())
        present(settingsVC, animated: true)
    }
    
    @objc private func profileImageTapped() {
        let vc = ChangePhotoViewController()
        present(vc, animated: true)
    }
    
    // MARK: - Data Fetching
    
    private func fetchUser() {
        activityIndicator.startAnimating()
        
        AuthService.shared.fetchUser { [weak self] user, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                if let error = error {
                    print("Failed to fetch user: \(error.localizedDescription)")
                    return
                }
                
                if let user = user {
                    self.user = user
                    self.updateUI(with: user)
                    self.fetchProfileImage(from: user.imageURL)
                }
            }
        }
    }
    
    private func updateUI(with user: User) {
        usernameLabel.text = user.username
        soberStatLabel?.text = "\(Int(user.soberStreak)) days"
        resetsStatLabel?.text = "\(Int(user.numberOfResets))"
        longestStreakStatLabel?.text = "\(Int(user.soberStreak)) days"
    }
    
    private func fetchProfileImage(from url: String) {
        if let cachedImageData = UserDefaults.standard.data(forKey: "profileImage"),
           let cachedImage = UIImage(data: cachedImageData) {
            self.profileImageView.image = cachedImage
            return
        }
        
        let storageRef = Storage.storage().reference(forURL: url)
        storageRef.getData(maxSize: 5 * 1024 * 1024) { [weak self] data, error in
            if let error = error {
                print("Failed to fetch profile image: \(error.localizedDescription)")
                return
            }
            
            guard let imageData = data,
                  let image = UIImage(data: imageData) else {
                print("Failed to create image from data.")
                return
            }
            
            UserDefaults.standard.set(imageData, forKey: "profileImage")
            
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }
    }
}
