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
    
    @AppStorage("selectedLanguage") var selectedLanguage: Language = .english_us
    
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("log_status") var logStatus: Bool = false
    
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, .init(identifier: selectedLanguage.rawValue))
                .environment(\.colorScheme, isDarkMode ? .dark : .light )

        }
    }
}

