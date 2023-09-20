//
//  View+Extensions.swift
//  SocialApp
//
//  Created by Louison Lu on 2023/1/13.
//

import SwiftUI

//自訂排版
extension View{
    //closing all Activity keyboard
    func closeKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    //沒有填完不能按送出（透明度自動改變）
    func disableWithOpacity( _ condition: Bool) -> some View {
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1)
    }
    
    //平行對齊
    func hAlign(_ alignment: Alignment) -> some View{
        self.frame(maxWidth: .infinity, alignment: alignment)
    }
    //垂直對齊
    func vAlign(_ alignment: Alignment) -> some View{
        self.frame(maxHeight:.infinity, alignment: alignment)
    }
    //邊框造型（輸入框）
    func border(_ width: CGFloat, _ color: Color) -> some View{
        self
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background{
                RoundedRectangle(cornerRadius: 5,style: .continuous)
                    .stroke(color, lineWidth: width)
            }
        
    }
    //邊框造型（輸入框）
    func fillView(_ color: Color) -> some View{
        self
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background{
                RoundedRectangle(cornerRadius: 5,style: .continuous)
                    .fill(color)
            }
        
    }
}
