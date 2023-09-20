//
//  ReusableProfileContent.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/1/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct ReusableProfileContent: View {
    var user: User
    @State private var fetchedPosts: [Post] = [] //該用戶張貼的貼文
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack{
                HStack(spacing: 12){
                    WebImage(url: user.userProfileURL).placeholder{
                        // Placeholder Image
                        Image("NullProfile")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6){
                        Text(user.username)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(user.userBio)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(3)
                        // Displaying Bio Link ,If have BioLink
                        if let bioLink = URL(string: user.userBioLink){
                            Link(user.userBioLink, destination:bioLink )
                                .font(.callout)
                                .tint(.blue)
                                .lineLimit(1)
                        }
                        
                    }
                    .hAlign(.leading)
                }
                
                Text("Post's")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .hAlign(.leading)
                    .padding(.vertical,15)
                
                //顯示該用戶張貼過的貼文
                ReusablePostsView(basedOnUID: true, uid: user.userUID ,posts: $fetchedPosts) 
            }
            .padding(15)
        }
    }
}

