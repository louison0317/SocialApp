//
//  PostsView.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/3/23.
//

import SwiftUI

struct PostsView: View {
    @State private var recentPosts: [Post] = []
    @State private var createNewPost: Bool = false
    // dark mode
    @AppStorage("isDarkMode") var isDarkMode = false
    var body: some View {
        NavigationStack{
            ReusablePostsView(posts: $recentPosts)
                .hAlign(.center)
                .vAlign(.center)
                .overlay(alignment: .bottomTrailing){
                    Button{
                        createNewPost.toggle()
                    }label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(isDarkMode ? .black : .white)
                            .padding(13)
                            .background(isDarkMode ? .white : .black, in: Circle())
                    }
                    .padding(15)
                }
                // 搜尋欄（放大鏡）
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarTrailing){
                        NavigationLink{
                            SearchUserView()
                        }label: {
                            Image(systemName:"magnifyingglass")
//                                .tint(.black)
                                .scaleEffect(0.9)
                        }
                    }
                })
                .navigationTitle("Post's")
        }
        //按加號就用CreateNewPost覆蓋
        .fullScreenCover(isPresented: $createNewPost){
            CreateNewPost{ post in
                // Adding created post at the top of the Recent Posts
                recentPosts.insert(post, at: 0)
                
            }
        }
        //sheet or Cover要加這段，不會自動變
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct PostsView_Previews: PreviewProvider {
    static var previews: some View {
        PostsView()
    }
}
