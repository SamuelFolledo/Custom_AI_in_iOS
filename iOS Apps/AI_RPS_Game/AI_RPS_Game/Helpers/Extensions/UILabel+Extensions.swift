//
//  UILabel+Extensions.swift
//  StrepScan
//
//  Created by Mark Kim on 12/7/20.
//  Copyright © 2020 SamuelFolledo. All rights reserved.
//

import UIKit.UILabel

extension UILabel {
    func addSpacing(spacingValue: CGFloat = 2) {
        guard let textString = text else { return }
        let attributedString = NSMutableAttributedString(string: textString)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spacingValue
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedString.length)
        )
        attributedText = attributedString
    }
}
