//
//  OnboardingScreen11ViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 08/01/25.
//


import UIKit

class CountViewController: UIViewController {
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.text = "Number of days per week do you drink?"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = .black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter no. of days"
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.keyboardType = .numberPad // Set keyboard type for integers only
        textField.becomeFirstResponder()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Let's Reset!", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 1.0, green: 0.94, blue: 0.88, alpha: 1.0)
        
        view.addSubview(questionLabel)
        view.addSubview(inputTextField)
        view.addSubview(nextButton)
        view.addSubview(loadingIndicator)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Question Label Constraints
            questionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
            questionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Input TextField Constraints
            inputTextField.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 20),
            inputTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            inputTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            inputTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            inputTextField.heightAnchor.constraint(equalToConstant: 55),
            
            // Loading Indicator Constraints
            loadingIndicator.centerXAnchor.constraint(equalTo: nextButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor),
            
            // Next Button Constraints
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            nextButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    @objc private func nextButtonTapped() {
        guard let daysText = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !daysText.isEmpty,
              let days = Int(daysText) else {
            showAlert(message: "Please enter a valid number of days")
            return
        }
        
        // Validate input range (0-7 days)
        guard days >= 0 && days <= 7 else {
            showAlert(message: "Please enter a number between 0 and 7")
            return
        }
        
        // Show loading indicator and disable button
        loadingIndicator.startAnimating()
        nextButton.isEnabled = false
        
        // Update Firebase
        AuthService.shared.updateDrinksPerWeek(to: days) { [weak self] error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.nextButton.isEnabled = true
                
                if let error = error {
                    self?.showAlert(message: "Error saving data: \(error.localizedDescription)")
                } else {
                    // Check authentication using SceneDelegate
                    if let self = self,
                       let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate {
                        sceneDelegate.checkAuthentication()
                    }
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
