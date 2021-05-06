//
//  UIStackView+Extensions.swift
//  StrepScan
//
//  Created by Samuel Folledo on 8/2/20.
//  Copyright © 2020 SamuelFolledo. All rights reserved.
//

import UIKit

extension UIStackView {
    
    convenience init(arrangedSubviews: [UIView],
                     axis:  NSLayoutConstraint.Axis,
                     alignment: Alignment,
                     distribution: Distribution,
                     spacing: CGFloat) {
        self.init(arrangedSubviews: arrangedSubviews)
        self.axis = axis
        self.alignment = alignment
        self.distribution = distribution
        self.spacing = spacing
    }
    
    convenience init(axis: NSLayoutConstraint.Axis, spacing: CGFloat, distribution: UIStackView.Distribution, alignment: UIStackView.Alignment) {
        self.init()
        self.translatesAutoresizingMaskIntoConstraints = false
        self.distribution = distribution
        self.axis = axis
        self.alignment = alignment
        self.spacing = spacing
    }
    
/// setup vertical stackView
    func setupStandardVertical(spacing: CGFloat = 0) -> UIStackView {
        return UIStackView(axis: .vertical, spacing: spacing, distribution: .fill, alignment: .fill)
    }
    
/// setup horizontail stackView
    func setupStandardHorizontal(spacing: CGFloat = 0) -> UIStackView {
        return UIStackView(axis: .horizontal, spacing: spacing, distribution: .fill, alignment: .fill)
    }
}
