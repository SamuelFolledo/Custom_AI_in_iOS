//
//  UITextField+Extensions.swift
//  StrepScan
//
//  Created by Samuel Folledo on 7/27/20.
//  Copyright © 2020 SamuelFolledo. All rights reserved.
//

import UIKit.UITextField

extension UITextField {
    func hasError() {
//        self.layer.borderWidth = 1.5
//        self.layer.borderColor = UIColor.red.cgColor
        self.textColor = .systemRed
    }
    
    func hasNoError() {
//        self.layer.borderColor = UIColor.clear.cgColor
        self.textColor = .black
    }
    
    func setPadding(left: CGFloat, right: CGFloat) {
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: left, height: frame.size.height))
        leftView = leftPadding
        leftViewMode = .always
        let rightPadding = UIView(frame: CGRect(x: 0, y: 0, width: right, height: frame.size.height))
        rightView = rightPadding
        rightViewMode = .always
    }
}
