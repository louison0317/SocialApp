//
//  SearchUserView.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/3/26.
//

import SwiftUI
import FirebaseFirestore

struct SearchUserView: View {
    // View Property
    @State private var fetchedUsers: [User] = []
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        List{
            ForEach(fetchedUsers){ user in
                NavigationLink{
                    ReusableProfileContent(user: user)
                }label: {
                    Text(user.username)
                        .font(.callout)
                        .hAlign(.leading)
                }
            }
        }
        .listStyle(.plain)   //表格風格
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search User")
        .searchable(text: $searchText)  //搜尋欄
        .onSubmit (of: .search,{
            // Fetch User from Firebase
            Task{await searchUsers()}
        })
        .onChange(of: searchText, perform: { newValue in
            if newValue.isEmpty{
                fetchedUsers = []
            }
        })
    }
    func searchUsers() async {
        do{
            // 因為firebse 沒有 .contains()，所以只能查 >大寫 與 < 小寫＋\u{f8ff}(some Unicode)
            // A~Z(65~90), a~z(97~122)
            // 所以會剛好在區間內 效果近似.contains()
            // 但最好的方式還是用戶名創建時只能全小寫
            let documents = try await Firestore.firestore().collection("Users")
                .whereField("username", isGreaterThanOrEqualTo: searchText)
                .whereField("username", isLessThanOrEqualTo: "\(searchText)\u{f8ff}")
                .getDocuments()
            
            let users = try documents.documents.compactMap{ doc -> User? in
                try doc.data(as: User.self)
            }
            
            // UI must be Updated on Main Thread
            await MainActor.run(body: {
                fetchedUsers = users
            })
            
        }catch{
            print(error.localizedDescription)
        }
    }
}

struct SearchUserView_Previews: PreviewProvider {
    static var previews: some View {
        SearchUserView()
    }
}
