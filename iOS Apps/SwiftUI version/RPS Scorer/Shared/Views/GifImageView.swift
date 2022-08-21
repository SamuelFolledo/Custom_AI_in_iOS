//
//  GifImageView.swift
//  RPS Scorer
//
//  Created by Samuel Folledo on 8/20/22.
//

import UIKit
import SwiftUI

//MARK: - GifImage Example in SwiftUI
struct OnboardingGifImage: View {
    private let gifUrl: String
    @State private var imageData: Data? = nil
    
    init(gifUrl: String) {
        self.gifUrl = gifUrl
    }
    
    var body: some View {
        VStack {
//            GifImageView(name: "preview") //local gif
            if let data = imageData {
                GifImageView(data: data)
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            } else {
                Text("Loading...")
                    .onAppear(perform: loadData)
            }
        }
    }
    
    private func loadData() {
        let task = URLSession.shared.dataTask(with: URL(string: gifUrl)!) { data, response, error in
            imageData = data
        }
        task.resume()
    }
}

//MARK: - SwiftUI

struct GifImageView: UIViewRepresentable {
    private let data: Data?
    private let name: String?
    
    init(data: Data) {
        self.data = data
        self.name = nil
    }
    
    public init(name: String) {
        self.data = nil
        self.name = name
    }
    
    func makeUIView(context: Context) -> UIGifImageView {
        if let data = data {
            return UIGifImageView(data: data)
        } else {
            return UIGifImageView(name: name ?? "")
        }
    }
    
    func updateUIView(_ uiView: UIGifImageView, context: Context) {
        if let data = data {
            uiView.updateGIF(data: data)
        } else {
            uiView.updateGIF(name: name ?? "")
        }
    }
}

//MARK: - UIKit
class UIGifImageView: UIView {
    private let imageView = UIImageView()
    private var data: Data?
    private var name: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(name: String) {
        self.init()
        self.name = name
        initView()
    }
    
    convenience init(data: Data) {
        self.init()
        self.data = data
        initView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        self.addSubview(imageView)
    }
    
    func updateGIF(data: Data) {
        imageView.image = UIImage.gifImage(data: data)
    }
    
    func updateGIF(name: String) {
        imageView.image = UIImage.gifImage(name: name)
    }
    
    private func initView() {
        imageView.contentMode = .scaleAspectFit
    }
}
