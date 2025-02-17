//
//  AccountViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 08/01/25.
//


import UIKit

class AccountViewController: UIViewController {
    
    // MARK: - Properties
    private let accountLabel: UILabel = {
        let label = UILabel()
        label.text = "account"
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "username"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameValueLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "email"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailValueLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let deactivateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("deactivate account", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchUserData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(closeButton)
        view.addSubview(accountLabel)
        view.addSubview(cardView)
        view.addSubview(deactivateButton)
        
        cardView.addSubview(usernameLabel)
        cardView.addSubview(usernameValueLabel)
        cardView.addSubview(emailLabel)
        cardView.addSubview(emailValueLabel)
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        deactivateButton.addTarget(self, action: #selector(deactivateButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Close Button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Account Label
            accountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            accountLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            
            // Card View
            cardView.topAnchor.constraint(equalTo: accountLabel.bottomAnchor, constant: 24),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Username Label
            usernameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            usernameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            // Username Value
            usernameValueLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            usernameValueLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            // Email Label
            emailLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 24),
            emailLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            emailLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            
            // Email Value
            emailValueLabel.centerYAnchor.constraint(equalTo: emailLabel.centerYAnchor),
            emailValueLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            // Deactivate Button
            deactivateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            deactivateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            deactivateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            deactivateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Data Fetching
    private func fetchUserData() {
        AuthService.shared.fetchUser { [weak self] user, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    // Handle error - show alert
                    print("Error fetching user: \(error)")
                    return
                }
                
                if let user = user {
                    self.usernameValueLabel.text = user.username
                    self.emailValueLabel.text = user.email
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func deactivateButtonTapped() {
        let alert = UIAlertController(
            title: "Deactivate Account",
            message: "Are you sure you want to deactivate your account? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Deactivate", style: .destructive) { [weak self] _ in
            // Handle account deactivation
            self?.handleAccountDeactivation()
        })
        
        present(alert, animated: true)
    }
    
    private func handleAccountDeactivation() {
        // Here you would implement the account deactivation logic
        // This could involve calling an API endpoint or Firebase function
        print("Account deactivation requested")
    }
}
