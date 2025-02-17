//
//  Comment.swift
//  Reset
//
//  Created by Prasanjit Panda on 14/12/24.
//

import Foundation

struct Comment: Codable {
    let id: UUID
    let postID: UUID
    let userName: String
    let profileImage: String
    let commentText: String
}
