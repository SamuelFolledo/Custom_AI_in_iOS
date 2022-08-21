//
//  OnboardingView.swift
//  RPS Scorer
//
//  Created by Samuel Folledo on 8/20/22.
//

import SwiftUI
import AVFoundation

struct OnboardingView: View {
    // MARK: - Properties
    @AppStorage("onboarding") var isOnboardingViewActive: Bool = true
    @State private var showCameraErrorAlert = false
    
    private let gifUrl = "https://media2.giphy.com/media/3KQFqhgLN9ngkYr0qS/giphy.gif?cid=790b761143147a59db89e90c603d888cc5800a108db444c3&rid=giphy.gif&ct=g"
    
    //MARK: - Body
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea(.all, edges: .all)
            VStack {
                // MARK: - header
                Spacer()
                
                headerView
                
                Spacer()
                
                OnboardingGifImage(gifUrl: gifUrl)
                
                startButton
                
                Spacer()
            } //: VSTACK
        } //: ZSTACK
        .alert(isPresented: $showCameraErrorAlert) {
            Alert(title: Text("Camera Error"), message: Text("Please allow this app to access your camera in order to enable live object detection"), dismissButton: .default(Text("OK")))
        }
    }
    
    //MARK: - UI properties
    
    var headerView: some View {
        return VStack(spacing: 0) {
            Text("RPS Scorer")
                .font(.system(size: 44))
                .fontWeight(.heavy)
                .foregroundColor(Color(UIColor.label))
            
            // for long text, wrap with 3 """
            Text("""
            Point your phone's rear camera while playing rock-paper-scissor game
            """)
            .font(.title3)
            .fontWeight(.light)
            .foregroundColor(Color(UIColor.label))
            .multilineTextAlignment(.center)
            .padding(EdgeInsets(
                top: 10, leading: 20, bottom: 0, trailing: 20
            ))
            .lineLimit(2)
        } //: header
    }
    
    var startButton: some View {
        Button(action: {
            if hasCameraPermissions() {
                isOnboardingViewActive = false
            } else {
                AVCaptureDevice.requestAccess(for: .video) { (granted: Bool) in
                    isOnboardingViewActive = granted
                }
            }
        }, label: {
            Text("Start")
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: UIScreen.main.bounds.width * 2/3, minHeight: 40, maxHeight: 60, alignment: .center)
        })
        .padding(.horizontal, 20)
        .background(LinearGradient(gradient: Gradient(colors: [Color("ColorBlue"), Color("ColorPink")]), startPoint: .leading, endPoint: .trailing))
        .cornerRadius(40)
    }
}

//MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

//MARK: - Private Extensions
private extension OnboardingView {
    func hasCameraPermissions() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined, .restricted, .denied:
            break
        @unknown default:
            break
        }
        return false
    }
}
