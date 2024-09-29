//
//  floatingCard.swift
//  Sandy
//
//  Created by 郭粟閣 on 2024/9/27.
//
import SwiftUI

struct floatingCard: View {
    @State var isPresented = false
    @State var isChecked = false
     var body: some View {

        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple, Color.pink]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            // a button to show the sheet
//            Button("Floating Card") {
//                // isPresented = true # iwant it be !isPresented
//                isPresented.toggle()
//            }
//            .padding(.horizontal,16)
//            .padding(.vertical,12)
//            .foregroundColor(.white)
//            .background(Color.black)
//            .cornerRadius(300)
            Button(action:{
                withAnimation(.easeInOut(duration: 0.3)){
                    isPresented.toggle()
                    isChecked.toggle()
                }
                DispatchQueue.main.asyncAfter(deadline: .now()+1 , execute: {
                    isChecked.toggle()
                })
            }){
                ZStack{
                    Text("Pokemon")
                        .blur(radius: isChecked ? 3:0)
                    if isChecked{
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal,16)
            .padding(.vertical,12)
            .foregroundColor(.white)
            .background(Color.black)
            .cornerRadius(300)
        }
        .sheet(isPresented: $isPresented) {
            FloatingCardView(isPresented: $isPresented)
                .interactiveDismissDisabled()
                .presentationDetents([/*.fraction(0),*/ .fraction(0.3)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(36)
//                .presentationCompactAdaptation(.popover)
//                .presentationContentInteraction(.resizes)
                .presentationBackgroundInteraction(
                    .enabled(upThrough: .fraction(0.3))
                )

        }

     }
}

struct FloatingCardView: View {
    @Binding var isPresented: Bool // Add a binding variable
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                ZStack {
                    Color.white
                    VStack {
                        Spacer()
                        HStack{
                            HStack {
                                Text("Floating Card")
                                    .frame(maxWidth: .infinity)
                                Button("Close") {
                                    isPresented = false
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal,16)
                                .padding(.vertical,12)
                                .foregroundColor(.white)
                                .background(Color.black)
                                .cornerRadius(100)
                            }
                            
                        }
                        
                    }
                }
                .frame(height: geometry.size.height * 0.5)
                .cornerRadius(20)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea()
    }

}



#Preview {
    floatingCard()
}
