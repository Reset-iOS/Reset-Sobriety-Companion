//
//  SpacesCollectionViewCell 2.swift
//  Reset
//
//  Created by Prasanjit Panda on 07/02/25.
//


import UIKit

class SBSpacesCollectionViewCell: UICollectionViewCell {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 2
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray
        label.numberOfLines = 2
        return label
    }()
    
    private let hostLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .darkGray
        return label
    }()
    
    private let listenersCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        return label
    }()
    
    private let liveDurationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemRed
        return label
    }()
    
    private let participantsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = -10
        stack.alignment = .center
        return stack
    }()
    
    private let liveIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 4
        return view
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(hostLabel)
        containerView.addSubview(participantsStackView)
        containerView.addSubview(listenersCountLabel)
        containerView.addSubview(liveIndicator)
        containerView.addSubview(liveDurationLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        hostLabel.translatesAutoresizingMaskIntoConstraints = false
        participantsStackView.translatesAutoresizingMaskIntoConstraints = false
        listenersCountLabel.translatesAutoresizingMaskIntoConstraints = false
        liveIndicator.translatesAutoresizingMaskIntoConstraints = false
        liveDurationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            hostLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            hostLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            participantsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            participantsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            participantsStackView.heightAnchor.constraint(equalToConstant: 32),
            
            listenersCountLabel.centerYAnchor.constraint(equalTo: participantsStackView.centerYAnchor),
            listenersCountLabel.leadingAnchor.constraint(equalTo: participantsStackView.trailingAnchor, constant: 8),
            
            liveIndicator.centerYAnchor.constraint(equalTo: liveDurationLabel.centerYAnchor),
            liveIndicator.trailingAnchor.constraint(equalTo: liveDurationLabel.leadingAnchor, constant: -4),
            liveIndicator.widthAnchor.constraint(equalToConstant: 8),
            liveIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            liveDurationLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            liveDurationLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    func configureCell(with space: Space, profileImages: [UIImage]) {
        titleLabel.text = space.title
        descriptionLabel.text = space.description
        hostLabel.text = "Host: \(space.host)"
        listenersCountLabel.text = "\(space.listenersCount) listening"
        liveDurationLabel.text = space.liveDuration
        
        // Clear existing profile images
        participantsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add profile images (limited to 5)
        for (index, image) in profileImages.prefix(5).enumerated() {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 16
            imageView.layer.borderWidth = 2
            imageView.layer.borderColor = UIColor.white.cgColor
            
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 32),
                imageView.heightAnchor.constraint(equalToConstant: 32)
            ])
            
            participantsStackView.addArrangedSubview(imageView)
        }
        
        // Add remaining count if there are more participants
        if profileImages.count > 5 {
            let remainingLabel = UILabel()
            remainingLabel.text = "+\(profileImages.count - 5)"
            remainingLabel.font = .systemFont(ofSize: 12, weight: .medium)
            remainingLabel.textColor = .gray
            participantsStackView.addArrangedSubview(remainingLabel)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        participantsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
