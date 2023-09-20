//
//  SocialAppApp.swift
//  SocialApp
//
//  Created by Louison Lu on 2022/12/30.
//

import SwiftUI
import Firebase

@main
struct SocialAppApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
