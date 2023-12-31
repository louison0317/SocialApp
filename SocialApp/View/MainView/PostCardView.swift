//
//  PostCardView.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/3/25.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct PostCardView: View {
    var post: Post
    // CallBacks
    var onUpdate: (Post) -> ()
    var onDelete: ()->()
    // View Properties
    @AppStorage("user_UID") var userUID : String = ""
    // For Live Updated (即時更新)
    @State private var docListener: ListenerRegistration?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12){
            WebImage(url: post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 6){
                Text(post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted( date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical,8)
                
                // Post Image if any
                if let postImageURL = post.imageURL{
                    GeometryReader{
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame( width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        
                    }
                    .frame(height: 200)
                }
                
                PostInteraction()
                
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            // Display Delete Button (if it's Author of that post )
            if post.userUID == userUID{
                Menu{
                    Button("Delete Post",role: .destructive,action: deletePost)
                }label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .tint(Color("iconColor"))
                        .padding(8)
                        .clipShape(Rectangle())
                    
                }
                .offset(x: 8)
            }
        })
        .onAppear{
            // Adding only once
            if docListener == nil{
                guard let postID = post.id else{return}
                docListener = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({snapshot,error in
                    if let snapshot{
                        if snapshot.exists{
                            // Document updated
                            // Fetching Updated Document
                            if let updatedPost = try? snapshot.data(as: Post.self){
                                onUpdate(updatedPost)
                            }
                                
                        }else{
                            // Document Deleted
                            onDelete()
                        }
                    }
                })
            }
        }
        .onDisappear{
            // MARK: Applying Snapshot Listener Only when the Post is Available on the Screen (節省讀取次數)
            // Else Removing the listener (It saves unwanted live updates from the posts which was swiped away from Screen)
            if let docListener{
                docListener.remove()
                self.docListener = nil
            }
        }
    }
    // MARK: Like/Dislike interaction
    @ViewBuilder
    func PostInteraction() -> some View {
        HStack(spacing: 6){
            Button (action: likePost){
                //該用戶有按過讚的話就填滿，表示有按過
                Image(systemName: post.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .tint(Color("iconColor"))
            }
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: dislikePost){
                //該用戶有按過讚的話就填滿，表示有按過
                Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .tint(Color("iconColor"))
            }
            .padding(.leading,25)
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical,8)
    }
    // Liking Post
    func likePost(){
        Task{
            guard let postID = post.id else{return}
            //如果已經按過再按一次，就是取消按讚
            if post.likedIDs.contains(userUID){
                // Remove UserId from Firebase
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
            }else{
                // Adding User ID to Liked Array and Removing ID from Disliked Array(if Added in piror)
                // 沒按過就加入喜歡，並且移除不喜歡 (FieldValue.arrayUnion 加入 , .arrayRemove 移除)
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID]),
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            }
        }
    }
    
    // Disliking Post
    func dislikePost(){
        Task{
            guard let postID = post.id else{return}
            //如果已經按過再按一次，就是取消按讚
            if post.dislikedIDs.contains(userUID){
                // Remove UserId from Firebase
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            }else{
                // Adding User ID to Liked Array and Removing ID from Disliked Array(if Added in piror)
                // 沒按過就加入不喜歡，並且移除喜歡 (FieldValue.arrayUnion 加入 , .arrayRemove 移除)
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "dislikedIDs": FieldValue.arrayUnion([userUID]),
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
            }
        }
    }
    
    // Deleting Post
    func deletePost(){
        Task{
            // Step1: Delete Image from Firebase Storage if present
            do{
                if post.imageReferenceID != ""{
                    try await Storage.storage().reference().child("Post_Images").child(post.imageReferenceID).delete()
                }
                // Step2: Delete Firestore Document
                guard let postID = post.id else{return}
                try await Firestore.firestore().collection("Posts").document(postID).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    
}

