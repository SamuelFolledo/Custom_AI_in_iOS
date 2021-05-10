//
//  UITextView+Extensions.swift
//  StrepScan
//
//  Created by Anika Morris on 3/23/21.
//  Copyright © 2021 SamuelFolledo. All rights reserved.
//

import Foundation
import UIKit

extension UITextView {
    func centerTextVertically() {
        self.textAlignment = .center
        let fitSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fitSize)
        let calculate = (bounds.size.height - size.height * zoomScale) / 2
        let offset = max(1, calculate)
        contentOffset.y = -offset
    }
}
