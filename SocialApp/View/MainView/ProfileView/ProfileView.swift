//
//  ProfileView.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/1/13.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    // My Profile Data
    @State private var myProfile: User?
    @AppStorage("log_status") var logStatus: Bool = false
    // Error Message
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    // View Properties
    @State var isLoading: Bool = false
    
    var body: some View {
        NavigationStack{
            VStack{
                if let myProfile{
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            // Refresh User Data
                            self.myProfile = nil
                            await fetchUserData()
                        }
                }else{
                    ProgressView() //進度條
                }
            }
            .navigationTitle("My Profile")
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Menu{
                        // Two Actions
                        // 1. Logout
                        // 2. Delete Account
                        Button("Logout",action: logOutUser)
                        Button("Delete Account", role: .destructive, action: deleteAccount)
                        
                    }label: {
                        //點點條
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .overlay{
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError){
        }
        .task {
            // This Modifer is like onAppear
            // So Fetching for first time only
            if myProfile != nil{return}
            // Fetch User Data
            await fetchUserData()
        }
        
    }
    //Fetching user data
    func fetchUserData() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else{return}
        await MainActor.run(body: {
            myProfile = user
        })
        
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
    //Setting Error
    func setErrror(_ error:Error)async{
        //UI Must be Updated on Main thread
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle() //出錯就顯示錯誤原因
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
