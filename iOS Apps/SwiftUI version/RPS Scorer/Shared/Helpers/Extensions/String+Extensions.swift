//
//  String+Extensions.swift
//  RPS Scorer (iOS)
//
//  Created by Samuel Folledo on 8/21/22.
//

import UIKit

extension String {
    var trimWhiteSpace: String {
        return self.trimmingCharacters(in: .whitespaces)
    }
    
    ///removes string's left and right white spaces and new lines
    var trimWhiteSpacesAndLines: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

extension String {
    ///convert string to image (conform UIImage to Decodable)
    func imageFromBase64() -> UIImage? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return UIImage(data: data)
    }
}

extension String {
    static func randomString(length: Int = 12) -> String {
        enum s {
            static let c = Array("abcdefghjklmnpqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ12345789")
            static let k = UInt32(c.count)
        }
        var result = [Character](repeating: "-", count: length)
        for i in 0..<length {
            let r = Int(arc4random_uniform(s.k))
            result[i] = s.c[r]
        }
        return String(result)
    }
}
