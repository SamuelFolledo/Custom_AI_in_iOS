//
//  VisionModel.swift
//  AI_RPS_Game
//
//  Created by Samuel Folledo on 5/6/21.
//

import Foundation
import CoreML
import Vision

enum VisionModel {
    static var visionModel: VNCoreMLModel {
        get {
            guard let model = try? VNCoreMLModel(for: my_custom_model(configuration: MLModelConfiguration()).model) else {
                fatalError("Could not load model")
            }
            return model
        }
    }
}
