//
//  UIImage+Extensions.swift
//  StrepScan
//
//  Created by Samuel Folledo on 8/30/20.
//  Copyright © 2020 SamuelFolledo. All rights reserved.
//

import UIKit.UIImage

extension UIImage {
    
    ///convert image to data (conform UIImage to Encodable)
    func base64() -> String? {
        let imageData: Data = self.pngData()!
        return imageData.base64EncodedString()
    }
    
    func withOriginalOrientation() -> UIImage {
        var rotatedImage = self
        switch self.imageOrientation {
        case .right:
            rotatedImage = UIImage(cgImage: self.cgImage!, scale: 1.0, orientation: .down)
        case .down:
            rotatedImage = UIImage(cgImage: self.cgImage!, scale: 1.0, orientation: .left)
        case .left:
            rotatedImage = UIImage(cgImage: self.cgImage!, scale: 1.0, orientation: .up)
        default:
            rotatedImage = UIImage(cgImage: self.cgImage!, scale: 1.0, orientation: .right)
        }
        return rotatedImage
    }
}
