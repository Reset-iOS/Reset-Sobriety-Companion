//
//  SummaryHeaderView.swift
//  Reset
//
//  Created by Prasanjit Panda on 07/01/25.
//

import UIKit

class SummaryHeaderView: UIView {
    weak var parentViewController: UIViewController?

    private let dateLabel = UILabel()
    private let titleLabel = UILabel()
    private let profileImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateDateLabel()
        if let cachedImageData = UserDefaults.standard.data(forKey: "profileImage"),
           let cachedImage = UIImage(data: cachedImageData) {
            profileImageView.image = cachedImage
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        updateDateLabel()
    }
    
    private func setupView() {
        // View setup
        // backgroundColor = UIColor(red: 0.98, green: 0.94, blue: 0.90, alpha: 1.0) // Peach/beige color
        
        // Date label setup
        dateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        dateLabel.textColor = .gray
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dateLabel)
        
        // Title label setup
        titleLabel.text = "Summary"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // Profile image setup
        profileImageView.backgroundColor = UIColor(red: 0.97, green: 0.76, blue: 0.19, alpha: 1.0) // Golden yellow
        profileImageView.layer.cornerRadius = 25
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(named: "person.fill")
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.isUserInteractionEnabled = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileImageView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openProfileViewController))
        profileImageView.addGestureRecognizer(tapGesture)
        setupConstraints()
    }
    
    private func updateDateLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE dd MMM"
        let currentDate = Date()
        dateLabel.text = formatter.string(from: currentDate)
    }
    
    @objc private func openProfileViewController() {
        guard let parentVC = parentViewController else {
            print("Parent view controller is not set.")
            return
        }
        let profileVC = UINavigationController(rootViewController: ProfileViewController())
        parentVC.present(profileVC, animated: true)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Date label constraints
            dateLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            
            // Title label constraints
            titleLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            
            // Profile image constraints
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
