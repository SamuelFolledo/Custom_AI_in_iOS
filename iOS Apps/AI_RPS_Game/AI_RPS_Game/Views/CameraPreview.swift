//
//  CameraPreview.swift
//  AI_RPS_Game
//
//  Created by Samuel Folledo on 5/6/21.
//

import UIKit
import AVFoundation

/// UIImageView with support for drawing bounding boxes
class CameraPreview: UIImageView {
    private var maskLayer = [CALayer]()
}

// MARK: - Public
extension CameraPreview {
    // MARK: AV capture properties
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    var session: AVCaptureSession? {
        get {
            return previewLayer.session
        }
        set {
            previewLayer.session = newValue
        }
    }

    func drawLayer(in rect: CGRect, color: UIColor = .yellow, with label: String) {
        let mask = CAShapeLayer()
        let textLayer = CATextLayer()
        mask.frame = rect
        textLayer.frame = rect
        mask.backgroundColor = color.cgColor
        mask.opacity = 0.2
        mask.borderColor = UIColor.white.cgColor
        mask.borderWidth = 2
        mask.cornerRadius = 12
        textLayer.string = " "+label
        textLayer.foregroundColor = color.cgColor
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = 12
        maskLayer.append(mask)
        maskLayer.append(textLayer)
        layer.insertSublayer(mask, at: 1)
        layer.addSublayer(textLayer)
    }

    func removeMasks() {
        for mask in maskLayer {
            mask.removeFromSuperlayer()
        }
        maskLayer.removeAll()
    }
}
