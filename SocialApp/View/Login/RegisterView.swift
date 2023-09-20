//
//  RegisterView.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/1/13.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

//註冊頁面
struct RegisterView: View{
    // User Input
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    // Photo Picker
    @State var userProfilePicData: Data?
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    // View Dismiss
    @Environment(\.dismiss) var dismiss
    // Error Message
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    // User Defaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    //loading view
    @State var isLoading: Bool = false
    
    var body: some View{
        VStack(spacing: 10){
            Text("Let's Register\nAccount")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text("Hello user, have a wonderful journey")
                .font(.title3)
                .hAlign(.leading)
            //為了更小的螢幕
            ViewThatFits{
                ScrollView(.vertical, showsIndicators: false){
                    HelperView()
                }
                HelperView()
            }
            //註冊鈕
            HStack{
                Text("Already have an accout ?")
                    .foregroundColor(.gray)
                Button("Login Now"){
                    dismiss()
                }
                .foregroundColor(.black)
                .fontWeight(.bold)
            }
            .font(.callout)
            .vAlign(.bottom)
            
        }
        .vAlign(.top)
        .padding(15)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem){ newValue in
            // PhotoItem => UIImage
            if let newValue{
                Task{
                    do{
                        guard let imageData = try await newValue.loadTransferable(type:
                            Data.self)else{return}
                        //UI Must Be Updated in Main Thread
                        await MainActor.run(body: {
                            userProfilePicData = imageData})
                    }catch{}
                }
            }

        }
        .alert(errorMessage, isPresented: $showError,actions: {})
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
    }
    //為了讓螢幕小的手機可以滑動（超出邊界）
    @ViewBuilder
    func HelperView() -> some View{
        //輸入區
        VStack(spacing: 12){
            //用戶圖片
            ZStack{
                if let userProfilePicData,let image = UIImage(data: userProfilePicData){
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }else{
                    Image(systemName: "person.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85,height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top,25)
            
            TextField("Username", text: $userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            SecureField("Password", text: $password)
                .textContentType(.password)
                .border(1, .gray.opacity(0.5))
            TextField("About you", text: $userBio, axis: .vertical)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            TextField("Bio Link (Optional)", text: $userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            Button(action: registerUser){
                Text("Sign up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .disableWithOpacity(userName == "" || userBio == "" || emailID == "" || password == "" || userProfilePicData == nil )
            .padding(.top,10)
            
            
        }
    }
    func registerUser() {
        isLoading = true
        closeKeyboard()
        Task{
            do{
                //Step1: Create account
                try await Auth.auth().createUser(withEmail: emailID, password: password)
                //Step2: Upload Profile into Firebase Storage
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                guard let imageData = userProfilePicData else { return }
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                //Step3: Download Photo URL
                let downloadURL = try await storageRef.downloadURL()
                //Step4: Creating a User Firestore Object
                let user = User(username: userName, userBio: userBio, userBioLink: userBioLink, userUID: userUID, userEmail: emailID, userProfileURL: downloadURL)
                //Step5: Saving User Doc into Firestore Database
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: {
                    error in
                    if error == nil{
                        print("Saved Successfully")
                        userNameStored = userName
                        self.userUID = userUID
                        profileURL = downloadURL
                        logStatus = true
                    }
                })
                
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

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
