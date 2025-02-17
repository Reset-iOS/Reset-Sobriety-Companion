//
//  AppDelegate.swift
//  Reset
//
//  Created by Prasanjit Panda on 03/01/25.
//

import UIKit
import FirebaseCore
import SendbirdChatSDK
import SendbirdUIKit
import FirebaseAuth
import FirebaseFirestore
import BackgroundTasks
import WidgetKit
import FirebaseMessaging
import UserNotifications
import FirebaseAnalytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        if #available(iOS 18.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]){
                granted, error in
                print("Permission Granted")
            }
            UNUserNotificationCenter.current().delegate = self
            
        }
        application.registerForRemoteNotifications()
        
        let APP_ID = "A753CB38-2215-485D-8F45-D26BD5FA2EDC"
        SendbirdUI.initialize(applicationId: APP_ID) { error in
                if let error = error {
                    print("Sendbird initialization failed: \(error.localizedDescription)")
                } else {
                    print("Sendbird initialized successfully.")
                }
            }
        
        setupSendbirdUser()
        
        syncUrgesWithFirebase()
        updateSoberStreak()
        
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([[.banner,.list,.sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: NSNotification.Name("PushNotification"), object: nil,userInfo: userInfo)
        completionHandler()
    }
    
    func updateSoberStreak() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)

        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error)")
                return
            }
            
            if let document = document, document.exists,
               let soberSinceTimestamp = document.data()?["soberSince"] as? Timestamp {
                
                let soberSinceDate = soberSinceTimestamp.dateValue()
                let soberStreak = self.calculateStreak(soberSinceDate: soberSinceDate)
                
                // Update the streak in Firebase and in the app
                userRef.updateData(["soberStreak": soberStreak]) { error in
                    if let error = error {
                        print("Error updating soberStreak: \(error)")
                    } else {
                        print("Sober streak updated successfully: \(soberStreak)")
                    }
                }
            }
        }
    }

    // Helper function to calculate the streak
    func calculateStreak(soberSinceDate: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfSoberDate = calendar.startOfDay(for: soberSinceDate)
        
        let components = calendar.dateComponents([.day], from: startOfSoberDate, to: startOfToday)
        return components.day ?? 0
    }
    @objc func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase TOKEN: \(String(describing: fcmToken))")
        
        guard let token = fcmToken else { return }
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let userId = currentUser.uid
        
        // Save the token to Firestore
        db.collection("users").document(userId).setData([
            "fcmToken": token,
            "lastTokenUpdate": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("Error saving FCM token: \(error.localizedDescription)")
            } else {
                print("FCM token successfully saved to Firestore")
            }
        }
        
        // Save token locally if needed
        UserDefaults.standard.set(token, forKey: "fcmToken")
    }
    
    private func setupSendbirdUser(){
        guard let currentUser = Auth.auth().currentUser else {
            print("No logged-in user.")
            return
        }

        let userID = currentUser.uid
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch user data: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(),
                          let username = data["username"] as? String,
                          let imageUrl = data["imageUrl"] as? String else {
                        print("User data is missing or invalid.")
                        return
            }
            
            let sendbirdUser = SBUUser(userId: userID, nickname: username, profileURL: imageUrl)
            SBUGlobals.currentUser = sendbirdUser
            print("Sendbird user set: \(userID) with nickname: \(username)")
            
        }
    }
    
    func syncUrgesWithFirebase() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No logged-in user. Cannot sync urges.")
            return
        }
        
        let sharedDefaults = UserDefaults(suiteName: "group.com.reset.urges")
        let timestamps = sharedDefaults?.array(forKey: "urgeTimestamps") as? [Date] ?? []

        guard !timestamps.isEmpty else {
            print("No new urges to sync")
            return
        }

        let db = Firestore.firestore()
        let userId = currentUser.uid
        let urgesRef = db.collection("users").document(userId).collection("urges")

        let batch = db.batch()
        for timestamp in timestamps {
            let docRef = urgesRef.document("\(timestamp.timeIntervalSince1970)")
            batch.setData([
                "timestamp": Timestamp(date: timestamp),
                "reason": "",  // Initially empty reason
                "createdAt": FieldValue.serverTimestamp()
            ], forDocument: docRef, merge: true) // Use `merge: true` in case reason is updated later
        }

        batch.commit { error in
            if let error = error {
                print("Error syncing urges: \(error.localizedDescription)")
            } else {
                print("Urges synced successfully!")

                // Notify Widget to refresh
                WidgetCenter.shared.reloadAllTimelines()

                // Delay clearing UserDefaults to prevent immediate data loss
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    sharedDefaults?.removeObject(forKey: "urgeTimestamps")
                    sharedDefaults?.synchronize()
                }
            }
        }
    }
    
    


    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

