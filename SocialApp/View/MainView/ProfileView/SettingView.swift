//
//  SettingView.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/11/5.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct SettingView: View {
    @AppStorage("selectedLanguage") var selectedLanguage: Language = .english_us
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("log_status") var logStatus: Bool = false
    // View Properties
    @State var isLoading: Bool = false
    // Error Message
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Language")) {
                Picker("Select Language", selection: $selectedLanguage) {
                    Text("English").tag(Language.english_us)
                    Text("中文").tag(Language.chinese)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Appearance")) {
                Toggle(isOn: $isDarkMode) {
                    HStack {
                        Text(isDarkMode ? "Dark Mode" : "Light Mode")
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(isDarkMode ? .white : .yellow)
                    }
                }
            }
            
            Section {
                Button("Logout", action: logOutUser)
                    .foregroundColor(.red)
                Button("Delete Account", action: deleteAccount)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Settings")
        .overlay{
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError){
        }
    }
    
    //Logout
    func logOutUser() {
        try? Auth.auth().signOut()
        logStatus = false
    }
    //Delete Account
    func deleteAccount() {
        isLoading = true
        Task {
            do{
                guard let userUID = Auth.auth().currentUser?.uid else{ return }
                // Step 1: Deleting Profile Image from Storage
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                // Step 2: Deleting Firestore User Document
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                // Step 3: Deleting Auth Account and Setting logStatus to False
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            }catch{
                await setErrror(error)
            }
            
        }
    }
    
    func setErrror(_ error:Error)async{
        //UI Must be Updated on Main thread
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle() //出錯就顯示錯誤原因
        })
    }
}


#Preview {
    SettingView()
}
