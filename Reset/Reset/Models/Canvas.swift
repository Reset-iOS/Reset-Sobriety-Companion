import Foundation
import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

enum CanvasItem: Codable {
    case image(String) // Store image file path as a String
    case text(String)  // Store text as String
    
    private enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    private enum ItemType: String, Codable {
        case image, text
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ItemType.self, forKey: .type)
        
        switch type {
        case .image:
            let filePath = try container.decode(String.self, forKey: .data)
            self = .image(filePath)
        case .text:
            let text = try container.decode(String.self, forKey: .data)
            self = .text(text)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .image(let filePath):
            try container.encode(ItemType.image, forKey: .type)
            try container.encode(filePath, forKey: .data)
        case .text(let text):
            try container.encode(ItemType.text, forKey: .type)
            try container.encode(text, forKey: .data)
        }
    }
    
    func imageURL() -> URL? {
        if case .image(let filePath) = self {
            return URL(string: filePath)
        }
        return nil
    }
}

class Model: NSObject {
    var items: [CanvasItem] = []
    private let firestore = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private let userDefaultsKey = "canvasItems"
    private let imagesDirectoryURL: URL
    
    override init() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        imagesDirectoryURL = documentsURL.appendingPathComponent("CanvasImages")
        
        if !fileManager.fileExists(atPath: imagesDirectoryURL.path) {
            try? fileManager.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        super.init()
        loadItems()
    }
    
    func fetchCanvasItems(completion: @escaping (Result<[CanvasItem], Error>) -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        firestore.collection("Canvas/\(userUID)/canvasItems").order(by: "timestamp").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            var fetchedItems: [CanvasItem] = []
            for document in documents {
                let data = document.data()
                if let type = data["type"] as? String, let content = data["data"] as? String {
                    switch type {
                    case "image":
                        fetchedItems.append(.image(content))
                    case "text":
                        fetchedItems.append(.text(content))
                    default:
                        break
                    }
                }
            }
            
            self.items = fetchedItems
            completion(.success(fetchedItems))
        }
    }
    
    func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save items: \(error.localizedDescription)")
        }
    }
    
    func loadItems() {
        guard let savedData = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        
        do {
            let decodedItems = try JSONDecoder().decode([CanvasItem].self, from: savedData)
            items = decodedItems
        } catch {
            print("Failed to load items: \(error.localizedDescription)")
        }
    }
    
    func saveImage(_ image: UIImage) -> URL? {
        let imageData = image.pngData()!
        let imageName = UUID().uuidString + ".png"
        let imageURL = imagesDirectoryURL.appendingPathComponent(imageName)
        
        do {
            try imageData.write(to: imageURL)
            return imageURL
        } catch {
            print("Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.pngData() else {
            completion(.failure(NSError(domain: "Invalid image data", code: -1, userInfo: nil)))
            return
        }
        
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let imageName = UUID().uuidString + ".png"
        let storageRef = storage.child("CanvasImages/\(userUID)/\(imageName)")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                }
            }
        }
    }
    
    func saveText(_ text: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        firestore.collection("Canvas/\(userUID)/canvasItems").addDocument(data: [
            "type": "text",
            "data": text,
            "timestamp": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func saveImageMetadata(_ imageURL: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        firestore.collection("Canvas/\(userUID)/canvasItems").addDocument(data: [
            "type": "image",
            "data": imageURL,
            "timestamp": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
