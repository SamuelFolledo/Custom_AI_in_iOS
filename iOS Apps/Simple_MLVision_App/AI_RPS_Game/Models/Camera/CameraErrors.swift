//
//  CameraErrors.swift
//  AI_RPS_Game
//
//  Created by Samuel Folledo on 5/6/21.
//

import Foundation

extension Camera {
    public enum Error: Swift.Error {
        case noCameraDevicesAvailable
        case noCameraSelected
        case captureSessionUndefined
        case invalidCameraInput
        case invalidOutput

        case undefined
    }
}
