//
//  ReusablePostsView.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/3/25.
//

import SwiftUI
import Firebase

struct ReusablePostsView: View {
    var basedOnUID: Bool = false
    var uid: String = ""
    @Binding var posts: [Post]
    // View Properties
    @State private var isFetching: Bool = true
    // Pagination
    @State private var paginationDoc: QueryDocumentSnapshot?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack{
                if isFetching{
                    ProgressView()  //進度條
                        .padding(.top,30)
                }else{
                    if posts.isEmpty{
                        // No Post's found in Firebase
                        Text("No Post's found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top,30)
                    }else{
                        // Displaying Posts
                        Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {   //下滑重整
            guard !basedOnUID else{return} // disabling refresh for uid based Posts
            isFetching = true   //跑進度條
            posts = []          //清空 Arrray
            paginationDoc = nil // resetting paginationDoc
            await fetchPosts()
        }
        .task { //有這個才會讀取（同步作業）
            // Fetching for one time
            guard posts.isEmpty else{return}
            await fetchPosts()
        }
    }
    // Display fetched post
    @ViewBuilder
    func Posts() -> some View {
        ForEach(posts){post in
            PostCardView(post: post){ updatedPost in
                //Updating Post in the Array
                if let index = posts.firstIndex(where: { post in
                    post.id == updatedPost.id
                    
                }){
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs = updatedPost.dislikedIDs
                }
            } onDelete:{
                //Removing Post from the Array
                withAnimation(.easeInOut(duration: 0.25)){
                    posts.removeAll{post.id == $0.id}
                }
                
            }
            .onAppear{ //滑到底部時再讀取更多貼文（20則）
                // When Last Post appears, Fetching New Post (If there)
                if post.id == posts.last?.id && paginationDoc != nil{
                    Task{await fetchPosts()}
                }
            }
            Divider()
                .padding(.horizontal,-15)
        }
        
    }
    
    // Fetching Post
    func fetchPosts()async {
        do{
            var query: Query!
            // Implementing pagination
            if let paginationDoc{
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true) //照刊登時間, 近到遠
                    .start(afterDocument: paginationDoc) //在最後一則後讀取
                    .limit(to: 20) //限制一次讀取20則
            }else{
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true) //照刊登時間, 近到遠
                    .limit(to: 20) //限制一次讀取20則
            }
            // New Quary for UID based Document Fetched
            // Simply filter the Posts which is belongs to this UID
            // 設一個新的query，裡面只有『 搜尋的 』這個uid的 po文
            // 這邊第一次會在console跑出firebase的網址要進去手動生成這個query
            //（我比影片多了一個 _name_ 屬性 但目前正常）
            if basedOnUID{
                query = query
                    .whereField("userUID",isEqualTo: uid)
            }
            
            let docs = try await query.getDocuments()
            let fetchedPost = docs.documents.compactMap{docs -> Post? in
                try? docs.data(as: Post.self)
            }
            await MainActor.run(body: {
                posts.append(contentsOf: fetchedPost) //posts加上新讀取的貼文
                paginationDoc = docs.documents.last   //paginationDoc = 最後一則
                isFetching = false
            })
        }catch{
            print(error.localizedDescription)
        }
    }
}

struct ReusablePostsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
