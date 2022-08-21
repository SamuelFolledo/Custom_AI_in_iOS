//
//  Move.swift
//  RPS Scorer (iOS)
//
//  Created by Samuel Folledo on 8/21/22.
//

import UIKit

struct Move {
    private var object: DetectedObject
    
    var isP1: Bool
    var type: DetectedObjectType
    var location: CGRect
    
    init(detectedObject: DetectedObject) {
        self.object = detectedObject
        self.type = detectedObject.type
        self.location = detectedObject.location
        if detectedObject.location.isOnTheLeftScreen() {
            //if object's midX is on the left half of the screen, assume it is p1's move
            print("move created for p1 = \(detectedObject.type)")
            isP1 = true
        } else {
            print("move created for p2 = \(detectedObject.type)")
            isP1 = false
        }
    }
    
    func isOnTheLeftSideOfScreen() -> Bool {
        return location.isOnTheLeftScreen()
    }
}
