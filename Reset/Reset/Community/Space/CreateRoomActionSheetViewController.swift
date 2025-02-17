//
//  CreateRoomActionSheetViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 04/02/25.
//


import UIKit
import FirebaseFirestore
import SendBirdCalls

class CreateRoomActionSheetViewController: UIViewController {
    
    // MARK: - UI Components
    private let cancelButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
        return button
    }()
    
    private let roomNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter room name..."
        textField.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        textField.textAlignment = .left
        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let descriptionTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter room description..."
        textField.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        textField.textAlignment = .left
        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let startNowLabel: UILabel = {
        let label = UILabel()
        label.text = "Start Now"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let startNowSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isOn = false
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    private let createButton: UIButton = {
        let button = UIButton()
        button.setTitle("Create Room", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    private var keyboardHeight: CGFloat = 0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        setupTapGesture()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Create Your Space"
        
        // Add Cancel button to navigation bar
        navigationItem.leftBarButtonItem = cancelButton
        cancelButton.target = self
        cancelButton.action = #selector(dismissSheet)
        
        // Add UI components
        view.addSubview(roomNameTextField)
        view.addSubview(descriptionTextField)
        view.addSubview(startNowLabel)
        view.addSubview(startNowSwitch)
        view.addSubview(createButton)
        
        // Add separators for text fields
        let roomNameSeparator = createSeparator()
        let descriptionSeparator = createSeparator()
        view.addSubview(roomNameSeparator)
        view.addSubview(descriptionSeparator)
        
        NSLayoutConstraint.activate([
            // Room Name TextField
            roomNameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            roomNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            roomNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            roomNameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Room Name Separator
            roomNameSeparator.topAnchor.constraint(equalTo: roomNameTextField.bottomAnchor),
            roomNameSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            roomNameSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            roomNameSeparator.heightAnchor.constraint(equalToConstant: 0),
            
            // Description TextField
            descriptionTextField.topAnchor.constraint(equalTo: roomNameSeparator.bottomAnchor, constant: 20),
            descriptionTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            descriptionTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Description Separator
            descriptionSeparator.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor),
            descriptionSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            descriptionSeparator.heightAnchor.constraint(equalToConstant: 0),
            
            // Start Now Label
            startNowLabel.topAnchor.constraint(equalTo: descriptionSeparator.bottomAnchor, constant: 30),
            startNowLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Start Now Switch
            startNowSwitch.centerYAnchor.constraint(equalTo: startNowLabel.centerYAnchor),
            startNowSwitch.leadingAnchor.constraint(equalTo: startNowLabel.trailingAnchor, constant: 10),
            
            
            // Create Button
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        createButton.addTarget(self, action: #selector(createRoomTapped), for: .touchUpInside)
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillShow),
                                             name: UIResponder.keyboardWillShowNotification,
                                             object: nil)
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillHide),
                                             name: UIResponder.keyboardWillHideNotification,
                                             object: nil)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func dismissSheet() {
        dismiss(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            let bottomPadding: CGFloat = 20
            
            UIView.animate(withDuration: 0.3) {
                self.createButton.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight + bottomPadding)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        UIView.animate(withDuration: 0.3) {
            self.createButton.transform = .identity
        }
    }
    
    @objc private func createRoomTapped() {
        // Show loading state
        createButton.isEnabled = false
        createButton.setTitle("Creating...", for: .disabled)
        
        guard let roomName = roomNameTextField.text, !roomName.isEmpty else {
            showAlert(message: "Please enter a room name")
            resetCreateButton()
            return
        }
        
        guard let description = descriptionTextField.text, !description.isEmpty else {
            showAlert(message: "Please enter a room description")
            resetCreateButton()
            return
        }
        
        // First fetch the current user
        AuthService.shared.fetchUser { [weak self] user, error in
            if let error = error {
                self?.showAlert(message: "Error fetching user: \(error.localizedDescription)")
                self?.resetCreateButton()
                return
            }
            
            guard let user = user else {
                self?.showAlert(message: "No user found")
                self?.resetCreateButton()
                return
            }
            
            let startNow = self?.startNowSwitch.isOn ?? false
            let params = RoomParams(roomType: .largeRoomForAudioOnly)
            
            SendBirdCall.createRoom(with: params) { room, error in
                guard let room = room, error == nil else {
                    self?.showAlert(message: "Failed to create room: \(error?.localizedDescription ?? "Unknown error")")
                    self?.resetCreateButton()
                    return
                }
                
                // Firestore setup
                let db = Firestore.firestore()
                let newSpace = [
                    "roomID": room.roomId,
                    "title": roomName,
                    "host": user.username,
                    "description": description,
                    "listenersCount": 0,
                    "liveDuration": startNow ? "Live" : "Not Live"
                ] as [String : Any]
                
                db.collection("spaces").addDocument(data: newSpace) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.showAlert(message: "Error adding room to Firestore: \(error.localizedDescription)")
                            self?.resetCreateButton()
                        } else {
                            // Post notification with new space data
                            NotificationCenter.default.post(name: NSNotification.Name("SpaceCreated"), object: newSpace)
                            
                            // Dismiss the modal
                            self?.dismiss(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    private func resetCreateButton() {
        DispatchQueue.main.async {
            self.createButton.isEnabled = true
            self.createButton.setTitle("Create Room", for: .normal)
        }
    }
    
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}




