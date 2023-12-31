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
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
        // Changing Tab Lable to Black
        .tint(Color("iconColor"))
        
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

#Preview ("English"){
    MainView()
}

#Preview ("Chinese Traditional"){
    MainView()
        .environment(\.locale, Locale(identifier: "zh_Hant_TW"))
}
