//
//  LoginView.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/1/2.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

//登入介面
struct LoginView: View {
    @State var emailID: String = ""
    @State var password: String = ""
    //頁面狀態
    @State var createAccount: Bool = false
    
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    // User Defaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    //loading view
    @State var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 10){
            Text("Let's Sign you in")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text("Welcome Back,\nYou have been missed")
                .font(.title3)
                .hAlign(.leading)
            //輸入區
            VStack(spacing: 12){
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top,25)
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .border(1, .gray.opacity(0.5))
                Button("Reset password?", action: resetPassword)
                    .font(.callout)
                    .fontWeight(.medium)
                    .tint(.black)
                    .hAlign(.trailing)
                Button(action: loginUser){
                    Text("Sign in")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }.padding(.top,10)
                
                
            }
            //註冊鈕
            HStack{
                Text("Don't have an accout ?")
                    .foregroundColor(.gray)
                Button("Register Now"){
                    createAccount.toggle()
                }
                .foregroundColor(.black)
                .fontWeight(.bold)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .fullScreenCover(isPresented: $createAccount){
            RegisterView()
        }
        .alert(errorMessage,isPresented: $showError, actions: {})
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
    }
    func loginUser(){
        isLoading = true
        closeKeyboard()
        Task{
            do{
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("User Found")
                try await fetchUser()
            }catch{
                await setErrror(error)
            }
        }
    }
    //if login fetch user data from firebase
    func fetchUser()async throws {
        guard let userID = Auth.auth().currentUser?.uid else { return  }
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        // UI updated must be Run on Main Thread
        await MainActor.run(body: {
            // Setting UserDefault Data and Changing App's Auth Status
            userUID = userID
            userNameStored = user.username
            profileURL = user.userProfileURL
            logStatus = true
        })
    }
    
    func resetPassword() {
        Task{
            do{
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
                print("Link Sent")
            }catch{
                await setErrror(error)
            }
        }
    }
    //Error訊息
    func setErrror(_ error:Error)async{
        //UI Must be Updated on Main thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
    
    
}



struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
