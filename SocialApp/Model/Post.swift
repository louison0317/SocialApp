//
//  Post.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/1/31.
//

import SwiftUI
import FirebaseFirestoreSwift

// Post Model
struct Post: Identifiable,Codable,Equatable,Hashable{
    @DocumentID var id: String?
    var text: String
    var imageURL: URL?
    var imageReferenceID: String = ""
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var dislikedIDs: [String] = []
    // Basic User Info
    var userName: String
    var userUID: String
    var userProfileURL: URL
    
    enum Codingkeys: CodingKey{
        case id
        case text
        case imageURL
        case imageReferenceID
        case publishedDate
        case likedIDs
        case dislikedIDs
        case userName
        case userUID
        case userProfileURL
    }
    
}
