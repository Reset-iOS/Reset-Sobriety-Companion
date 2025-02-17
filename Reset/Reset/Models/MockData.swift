////
////  MockData.swift
////  Reset
////
////  Created by Prasanjit Panda on 06/01/25.
////
//
//
//import Foundation
//import UIKit
//
//// Mock Data Generator
//func generateMockPosts(count: Int = 10) -> [Post] {
//    var posts: [Post] = []
//    
//    let sampleUsernames = [
//        "john_doe", "jane_smith", "alex_007", "travel_junkie", "foodie_heaven"
//    ]
//    
//    let sampleCaptions = [
//        "Enjoying a beautiful sunset at the beach!jklkhbdclhhblaebwlkcblbceleblblihALIClbaliewhfziuhlkebWLIcbelabeclabl",
//        "Just finished a great workout session 💪",
//        "Coffee time! ☕️ #coffeelover",
//        "Exploring the streets of Paris 🇫🇷",
//        "Best pizza ever! 🍕 #foodie",
//        "Weekend hike to the mountains 🏔️",
//        "Feeling grateful for the little things in life 🌸",
//        "Movie night with friends 🎥🍿",
//        "Tried something new today! 🎨",
//        "Chasing dreams, one step at a time ✨"
//    ]
//    
//    for _ in 1...count {
//        let randomUsername = sampleUsernames.randomElement()!
//        let randomCaption = sampleCaptions.randomElement()!
//        let randomLikeCount = Int.random(in: 50...1000)
//        let randomCommentCount = Int.random(in: 10...300)
//        
//        let post = Post(
//            profileImage: UIImage(systemName: "person.circle.fill")!,
//            username: randomUsername,
//            image: UIImage(systemName: "photo.fill")!,
//            likeCount: randomLikeCount,
//            commentCount: randomCommentCount,
//            caption: randomCaption
//        )

//
//        posts.append(post)
//    }
//    
//    return posts
//}
