//
//  ThroatPartType.swift
//  AI_RPS_Game
//
//  Created by Samuel Folledo on 5/6/21.
//

import UIKit.UIColor
import Vision.VNObservation

enum ThroatPartType: String {
    case pharynx, tongue, tonsil, uvula, unknown
    
    var color: UIColor {
        switch self {
        case .pharynx:
            return .yellow
        case .tongue:
            return UIColor(r: 203, g: 195, b: 227, a: 1) //light purple
        case .tonsil:
            return .cyan
        case .uvula:
            return .green
        case .unknown:
            return .clear
        }
    }
    
    init(trackedObject: VNRecognizedObjectObservation) {
        guard let label = trackedObject.labels.first?.identifier, let throatPart = ThroatPartType(rawValue: label) else {
            assertionFailure("Unable to retrieve identifier for result: \(trackedObject)")
            self = .unknown
            return
        }
        self = throatPart
    }
}

extension ThroatPartType {
    var supportedValues: [String] {
        switch self {
        case .pharynx:
            return ["pharynx"]
        case .tongue:
            return ["tongue"]
        case .tonsil:
            return ["tonsil"]
        case .uvula:
            return ["uvula"]
        case .unknown:
            return ["unknown"]
        }
    }

    static func shouldTrack(items: [ThroatPartType], for classifier: String) -> Bool {
        return items.first(where: { $0.supportedValues.contains(classifier)} ) != nil
    }
}
