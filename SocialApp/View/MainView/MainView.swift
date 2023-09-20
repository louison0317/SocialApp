//
//  MainView.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/1/13.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView{
            PostsView()
                .tabItem{
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                    Text("Post's")
                }
            ProfileView()
                .tabItem{
                    Image(systemName: "gear")
                    Text("Profile")
                }
        }
        // Changing Tab Lable to Black
        .tint(.black)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
