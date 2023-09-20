//
//  CreateNewPost.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/1/31.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage

struct CreateNewPost: View {
    // call back
    var onPost: (Post)->()
    // Post properties
    @State private var postText: String = ""
    @State private var postImageData: Data?
    // Stored User Data from UserDefaults(@AppStorage)
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var  userName: String = ""
    @AppStorage("user_UID") private var  userUID: String = ""
    // View Properties
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var showKeyboard: Bool
    
    var body: some View {
        VStack{
            // Cancel, Post
            HStack{
                Menu{
                    Button("Cancel",role: .destructive){
                        dismiss()
                    }
                }label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.black)
                }
                .hAlign(.leading)
                
                Button(action: createPost){
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal,20)
                        .padding(.vertical,6)
                        .background(.black, in: Capsule())
                }
                .disableWithOpacity(postText == "") // 沒內容不能post
                
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background{
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
                
            }
            
            //撰寫區
            ScrollView(.vertical, showsIndicators: false){
                VStack(spacing: 15){
                    //提示字
                    TextField("What's happening?", text: $postText, axis: .vertical)
                        .focused($showKeyboard)
                    //有圖的話，規定大小 圓邊
                    if let postImageData, let image = UIImage(data: postImageData){
                        GeometryReader{
                            let size = $0.size
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                // Delete photo button
                                .overlay(alignment: .topTrailing){
                                    Button{
                                        withAnimation(.easeInOut(duration: 0.25)){
                                            self.postImageData = nil
                                        }
                                    }label: {
                                        Image(systemName: "trash")
                                            .fontWeight(.bold)
                                            .tint(.red)
                                    }
                                    .padding(10)
                                }
                        }
                        .clipped()
                        .frame(height: 220)
                    }
                }
                .padding(15)
            }
            
            Divider() // 分割線
            
            HStack{
                Button{
                    showImagePicker.toggle()
                }label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                }
                .hAlign(.leading)
                
                Button("Done"){
                    showKeyboard = false
                }
            }
            .foregroundColor(.black)
            .padding(.horizontal,15)
            .padding(.vertical,10)
        }
        .vAlign(.top)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem){ newValue in
            if let newValue{
                Task{
                    if let rawImageData = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: rawImageData),
                       //壓縮圖檔節整空間（可選）
                       let compressedImageData = image.jpegData(compressionQuality: 0.5){
                        // UI must be done in Main Thread
                        await MainActor.run(body: {
                            postImageData = compressedImageData //決定顯示圖檔（壓縮過）
                            photoItem = nil     //結束photoPicker
                        })
                    }
                       
                }
            }
            
        }
        .alert(errorMessage, isPresented: $showError,actions: {})
        // Loading View
        .overlay{
            LoadingView(show: $isLoading)
        }
    }
    // MRAK : post content to Firebase
    func createPost() {
        isLoading = true
        showKeyboard = false
        Task{
            do{
                guard let profileURL = profileURL else{return}
                // Step1: Uploading Image if any
                let imageReferenceID = "\(userUID)\(Date())"
                let storageRef = Storage.storage().reference().child("Post_Images").child(imageReferenceID)
                if let postImageData{
                    let _ = try await storageRef.putDataAsync(postImageData)
                    let downloadURL = try await storageRef.downloadURL()
                    //Step3: Create Post Object with Image Id and URL
                    let post = Post(text: postText, imageURL: downloadURL ,imageReferenceID: imageReferenceID,userName: userName, userUID: userUID, userProfileURL: profileURL)
                    try await createDocumentAtFirebase(post)
                }else{
                    //Step2: Directly Post Teat Data to Firebase(sincee there is no image present)
                    let post = Post(text: postText,userName: userName, userUID: userUID, userProfileURL: profileURL)
                    try await createDocumentAtFirebase(post)
                }
            }catch{
                await setError(error)
            }
        }
    }
    
    // MARK: Create document in Firebase
    func createDocumentAtFirebase(_ post: Post)async throws{
        // Writing Document to Firebase FireStore
        let doc = Firestore.firestore().collection("Posts").document()
        let _ = try doc.setData(from: post, completion: {error in
            if error == nil{
                //Post Successfully Stored at Firebase
                isLoading = false
                var updatedPost = post
                updatedPost.id = doc.documentID
                onPost(updatedPost)
                dismiss()
            }
        })
    }
    
    // MARK: display errors as alert
    func setError(_ error:Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct CreateNewPost_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewPost{_ in
            
        }
    }
}
