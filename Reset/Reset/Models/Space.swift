//
//  Space.swift
//  Reset
//
//  Created by Prasanjit Panda on 10/12/24.
//

import Foundation

struct Space:Codable {
    let roomID:String
    let title: String
    let host: String
    let description: String
    let listenersCount: Int
    let liveDuration: String
}
var mockSpaces: [Space] = SpacesDataPersistence.shared.loadSpaces()


