//
//  UIColor+Extensions.swift
//  StrepScan
//
//  Created by Samuel Folledo on 7/27/20.
//  Copyright © 2020 SamuelFolledo. All rights reserved.
//

import UIKit

extension UIColor {
    
    // currently used for positive answers in QuestionController and ReviewAnswersController
    static let strepScanAlertRed: UIColor = #colorLiteral(red: 1, green: 0.3625985256, blue: 0.3428105906, alpha: 1)
    // currently used for negative answers in QuestionController
    static let strepScanNeutralBlueGrayedOut: UIColor = #colorLiteral(red: 0.4352941176, green: 0.4941176471, blue: 0.6235294118, alpha: 1)
    // light background color - please use for all backgrounds unless otherwise confirmed with Nima
    static let strepScanBackground: UIColor = #colorLiteral(red: 0.9019607843, green: 0.9176470588, blue: 0.9058823529, alpha: 1)
    static let strepScanDarkBlue: UIColor = #colorLiteral(red: 0.2431372549, green: 0.2862745098, blue: 0.3960784314, alpha: 1)
    static let strepScanNeutralBlue: UIColor = #colorLiteral(red: 0.3568627451, green: 0.4549019608, blue: 0.7019607843, alpha: 1)
    static let strepScanDarkTeal: UIColor = #colorLiteral(red: 0.2509803922, green: 0.5921568627, blue: 0.5607843137, alpha: 1)
    static let strepScanLightTeal: UIColor = #colorLiteral(red: 0.3176470588, green: 0.7254901961, blue: 0.737254902, alpha: 1)
    static let strepScanGreen: UIColor = .systemGreen
    
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: a)
    }
}

