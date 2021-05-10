//
//  UIView+Extensions.swift
//  StrepScan
//
//  Created by Samuel Folledo on 7/27/20.
//  Copyright © 2020 SamuelFolledo. All rights reserved.
//

import UIKit.UIView

extension UIView {
    fileprivate struct Constants {
        static let externalBorderName = "externalBorder"
    }
    
    func addTightOuterRoundedBorder(borderWidth: CGFloat = 2.0, borderColor: UIColor = UIColor.white) {
        let externalBorder = CALayer()
        externalBorder.frame = CGRect(x: -borderWidth, y: -borderWidth, width: frame.size.width + 2 * borderWidth, height: frame.size.height + 2 * borderWidth)
        externalBorder.borderColor = borderColor.cgColor
        externalBorder.borderWidth = borderWidth
        externalBorder.cornerRadius = (frame.size.width + 2 * borderWidth) / 2
        externalBorder.name = Constants.externalBorderName
        layer.insertSublayer(externalBorder, at: 0)
        layer.masksToBounds = false
    }
    
    ///outer border with with slight gap
    func addOuterRoundedBorder(borderWidth: CGFloat = 2.0, borderColor: UIColor = UIColor.white) {
        let externalBorder = CALayer()
        //Note: If you want extra space
        externalBorder.frame = CGRect(x: -borderWidth*1.5, y: -borderWidth*1.5, width: frame.size.width + 3 * borderWidth, height: frame.size.height + 3 * borderWidth) //1.5 * 2 = 3
        externalBorder.cornerRadius = (frame.size.width + 3 * borderWidth) / 2
        //Note: If you dont want extra space outside the border
//        externalBorder.frame = CGRect(x: -borderWidth, y: -borderWidth, width: frame.size.width + 2 * borderWidth, height: frame.size.height + 2 * borderWidth)
//        externalBorder.cornerRadius = (frame.size.width + 2 * borderWidth) / 2
        externalBorder.borderColor = borderColor.cgColor
        externalBorder.borderWidth = borderWidth
        externalBorder.name = Constants.externalBorderName
        layer.insertSublayer(externalBorder, at: 0)
        layer.masksToBounds = false
//        return externalBorder
    }

    func removeOuterBorders() {
        layer.sublayers?.filter() { $0.name == Constants.externalBorderName }.forEach() {
            $0.removeFromSuperlayer()
        }
    }

    func removeOuterBorder(externalBorder: CALayer) {
        guard externalBorder.name == Constants.externalBorderName else { return }
        externalBorder.removeFromSuperlayer()
    }
    
    /// Flip view horizontally.
    func flipX() {
        transform = CGAffineTransform(scaleX: -transform.a, y: transform.d)
    }

    /// Flip view vertically.
    func flipY() {
        transform = CGAffineTransform(scaleX: transform.a, y: -transform.d)
    }
}

//MARK: Glow effect
extension UIView {
    enum GlowEffect: Float {
      case small = 0.4, medium = 5, large = 10, extraLarge = 15
    }
    
    func addGlowAnimation(withColor color: UIColor, withEffect effect: GlowEffect = .medium) {
      layer.masksToBounds = false
      layer.shadowColor = color.cgColor
      layer.shadowRadius = 0
      layer.shadowOpacity = 1
      layer.shadowOffset = CGSize(width: 0, height: 3)
      let glowAnimationRadius = CABasicAnimation(keyPath: "shadowRadius")
      glowAnimationRadius.fromValue = 0
      glowAnimationRadius.toValue = effect.rawValue
      glowAnimationRadius.beginTime = CACurrentMediaTime()+0.3
      glowAnimationRadius.duration = CFTimeInterval(1.3)
      glowAnimationRadius.fillMode = .removed
      glowAnimationRadius.autoreverses = true
      glowAnimationRadius.repeatCount = .infinity
      layer.add(glowAnimationRadius, forKey: "shadowGlowingAnimationRadius")
      let glowAnimationOpacity = CABasicAnimation(keyPath: "shadowOpacity")
      glowAnimationOpacity.fromValue = 0
      glowAnimationOpacity.toValue = 1
      glowAnimationOpacity.beginTime = CACurrentMediaTime()+0.3
      glowAnimationOpacity.duration = CFTimeInterval(1.3)
      glowAnimationOpacity.fillMode = .removed
      glowAnimationOpacity.autoreverses = true
      glowAnimationOpacity.repeatCount = .infinity
      layer.add(glowAnimationOpacity, forKey: "shadowGlowingAnimationOpacity")
    }
}

