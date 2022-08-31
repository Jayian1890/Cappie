//
//  CaptureDevice.swift
//  Cappie
//
//  Created by Jared Terrance on 8/31/22.
//

import Foundation
import AVFoundation

class DeviceInterface: NSObject {
    internal init
    (
        searchName: String,
        deviceType: [AVCaptureDevice.DeviceType] = [.externalUnknown, .builtInMicrophone, .builtInWideAngleCamera],
        mediaType: AVMediaType = .video,
        position: AVCaptureDevice.Position = .unspecified)
    {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceType, mediaType: mediaType, position: position)
        let devices = discoverySession.devices
        
        self.device = devices.first { $0.localizedName.contains(searchName) } ?? AVCaptureDevice.default(for: mediaType)!
        
        self.deviceName = device.localizedName
        self.deviceType = [device.deviceType]
        self.mediaType = mediaType
        self.position = device.position
    }
    
    var deviceName: String
    var deviceType: [AVCaptureDevice.DeviceType]
    var mediaType: AVMediaType
    var position: AVCaptureDevice.Position
    var device: AVCaptureDevice
}
