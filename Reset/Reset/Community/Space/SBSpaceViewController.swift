//
//  RoomCreationDelegate.swift
//  Reset
//
//  Created by Prasanjit Panda on 04/02/25.
//


//
//  SBSpaceViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 04/02/25.
//

import UIKit
import SendBirdCalls
import AVFoundation
import FirebaseFirestore
import FirebaseAuth

protocol RoomCreationDelegate: AnyObject {
    func didCreateRoom(roomId: String)
}



class SBSpaceViewController: UIViewController {
    
    
    private let createRoomButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBrown
        button.tintColor = .white
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        return button
    }()
    
    private let joinRoomButton: UIButton = {
        let button = UIButton()
        button.setTitle("Join Voice Room", for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 8
        return button
    }()
    
    private var room: Room?
    weak var delegate: RoomCreationDelegate?
    
    // MARK: - Collection View Components
    private var spacesCollectionView: UICollectionView!
    private var spaces: [Space] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSendbird()
        setupCollectionView()
        // Listen for the "SpaceCreated" notification to add new space to collection
        NotificationCenter.default.addObserver(self, selector: #selector(spaceCreated(notification:)), name: NSNotification.Name("SpaceCreated"), object: nil)
        
        loadSpaces()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        

        view.addSubview(joinRoomButton)


        createRoomButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            joinRoomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            joinRoomButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            joinRoomButton.widthAnchor.constraint(equalToConstant: 200),
            joinRoomButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        createRoomButton.addTarget(self, action: #selector(createRoomTapped), for: .touchUpInside)
        joinRoomButton.addTarget(self, action: #selector(joinRoomTapped), for: .touchUpInside)
    }
    
    // MARK: - SendBird Setup
    private func setupSendbird() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No logged-in user.")
            return
        }
        SendBirdCall.configure(appId: "A753CB38-2215-485D-8F45-D26BD5FA2EDC")
        SendBirdCall.authenticate(with: AuthenticateParams(userId: currentUser.uid as String)) { user, error in
            if let error = error {
                print("Authentication failed: \(error.localizedDescription)")
            } else {
                print("Authenticated as: \(user?.userId ?? "Unknown User")")
            }
        }
    }
       
    // MARK: - Room Actions
    @objc private func createRoomTapped() {
        let actionSheetVC = CreateRoomActionSheetViewController()
        let navController = UINavigationController(rootViewController: actionSheetVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    @objc private func joinRoomTapped() {
        let alert = UIAlertController(title: "Join Room", message: "Enter Room ID", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Room ID"
        }
        
        alert.addAction(UIAlertAction(title: "Join", style: .default, handler: { [weak self] _ in
            guard let roomId = alert.textFields?.first?.text, !roomId.isEmpty else { return }
            
            SendBirdCall.fetchRoom(by: roomId) { room, error in
                guard let room = room, error == nil else {
                    print("Failed to fetch room: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                room.enter(with: Room.EnterParams(isAudioEnabled: true)) { error in
                    if let error = error {
                        print("Error joining room: \(error.localizedDescription)")
                    } else {
                        print("Joined room: \(room.roomId)")
                        self?.presentRoomViewController(room: room)
                    }
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentRoomViewController(room: Room) {
        let roomVC = VoiceRoomViewController(room: room)
        present(roomVC, animated: true)
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        spacesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        spacesCollectionView.backgroundColor = .clear
        spacesCollectionView.showsVerticalScrollIndicator = false
        spacesCollectionView.delegate = self
        spacesCollectionView.dataSource = self
        
        // Register the custom cell
        spacesCollectionView.register(SBSpacesCollectionViewCell.self, forCellWithReuseIdentifier: "SpacesCollectionViewCell")
        
        view.addSubview(spacesCollectionView)
        view.addSubview(createRoomButton)
        
        spacesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spacesCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            spacesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            spacesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            spacesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            createRoomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createRoomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createRoomButton.widthAnchor.constraint(equalToConstant: 60),
            createRoomButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Make the create room button circular
        createRoomButton.layer.cornerRadius = 30
    }
    
    // MARK: - Load Spaces from Firestore
    private func loadSpaces() {
        let db = Firestore.firestore()
        db.collection("spaces").getDocuments { snapshot, error in
            if let error = error {
                print("Error loading spaces: \(error)")
                return
            }
            
            self.spaces = snapshot?.documents.compactMap { document in
                let data = document.data()
                return Space(
                    roomID: data["roomID"] as? String ?? "",
                    title: data["title"] as? String ?? "",
                    host: data["host"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    listenersCount: data["listenersCount"] as? Int ?? 0,
                    liveDuration: data["liveDuration"] as? String ?? ""
                )
            } ?? []
            self.spacesCollectionView.reloadData()
        }
    }
    
    // MARK: - Handle Notification when a New Space is Created
    @objc private func spaceCreated(notification: Notification) {
        if let newSpace = notification.object as? [String: Any] {
            guard let roomID = newSpace["roomID"] as? String,
                  let title = newSpace["title"] as? String,
                  let host = newSpace["host"] as? String,
                  let description = newSpace["description"] as? String,
                  let listenersCount = newSpace["listenersCount"] as? Int,
                  let liveDuration = newSpace["liveDuration"] as? String else { return }
            
            let space = Space(
                roomID: roomID,
                title: title,
                host: host,
                description: description,
                listenersCount: listenersCount,
                liveDuration: liveDuration
            )
            
            // Add new space to the collection and reload
            self.spaces.append(space)
            self.spacesCollectionView.reloadData()
        }
    }
}

extension SBSpaceViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return spaces.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SpacesCollectionViewCell", for: indexPath) as? SBSpacesCollectionViewCell else {
            fatalError("Unable to dequeue SpacesCollectionViewCell")
        }
        
        let space = spaces[indexPath.row]
        
        // Sample profile images - replace with actual user profile images
        let images: [UIImage] = [
            UIImage(named: "Emily") ?? UIImage(),
            UIImage(named: "2") ?? UIImage(),
            UIImage(named: "MichaelImage") ?? UIImage(),
            UIImage(named: "Amy") ?? UIImage()
        ]
        
        cell.configureCell(with: space, profileImages: images)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 40 // Accounting for left and right insets
        return CGSize(width: width, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedSpace = spaces[indexPath.row]
        
        SendBirdCall.fetchRoom(by: selectedSpace.roomID) { [weak self] room, error in
            guard let room = room, error == nil else {
                print("Error fetching room: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let voiceRoomVC = VoiceRoomViewController(room: room)
            self?.present(voiceRoomVC, animated: true)
        }
    }

}

