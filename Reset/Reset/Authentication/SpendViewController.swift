//
//  OnboardingScreen11ViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 08/01/25.
//


import UIKit

class SpendViewController: UIViewController {
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.text = "How much did you typically spend\non alcohol per day?"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = .black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter amount"
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.keyboardType = .decimalPad // Set keyboard type for numerical input
        textField.becomeFirstResponder()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Loading indicator
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
        guard let amountText = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !amountText.isEmpty,
              let amount = Double(amountText) else {
            showAlert(message: "Please enter a valid amount")
            return
        }
        
        // Show loading indicator and disable button
        loadingIndicator.startAnimating()
        nextButton.isEnabled = false
        
        // Update Firebase
        AuthService.shared.updateAverageSpend(to: amount) { [weak self] error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.nextButton.isEnabled = true
                
                if let error = error {
                    self?.showAlert(message: "Error saving data: \(error.localizedDescription)")
                } else {
                    // Navigate to next screen or perform next action
                    // TODO: Add navigation logic here
                    let countViewController = CountViewController()
                    // Use push navigation if we're in a navigation controller
                    if let navigationController = self?.navigationController {
                        navigationController.pushViewController(countViewController, animated: true)
                    } else {
                        // If not in a navigation controller, present modally
                        countViewController.modalPresentationStyle = .fullScreen
                        self?.present(countViewController, animated: true)
                    }
                    print("Successfully updated average spend")
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
