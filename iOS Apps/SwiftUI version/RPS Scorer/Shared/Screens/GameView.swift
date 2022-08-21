//
//  GameView.swift
//  RPS Scorer
//
//  Created by Samuel Folledo on 8/20/22.
//

import SwiftUI

struct GameView: View {
    
    @AppStorage("onboarding") var isOnboardingViewActive: Bool = false
    
    var body: some View {
        ZStack {
            CameraCapturePreviewView()
                .ignoresSafeArea(.all, edges: .all)
            
            VStack {
                Spacer()
                quitButton
            }
        }
        .onAppear {
            
        }
    }
    
    //MARK: - UI properties
    
    var quitButton: some View {
        Button(action: {
            isOnboardingViewActive.toggle()
        }, label: {
            Text("Quit")
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: UIScreen.main.bounds.width * 2/3, minHeight: 40, maxHeight: 60, alignment: .center)
        })
        .padding(.horizontal, 20)
        .background(LinearGradient(gradient: Gradient(colors: [Color("ColorPink"), Color("ColorBlue")]), startPoint: .leading, endPoint: .trailing))
        .cornerRadius(40)
    }
}

//MARK: - Previews

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
