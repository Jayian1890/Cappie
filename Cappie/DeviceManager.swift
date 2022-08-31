//
//  DeviceAccess.swift
//  Cappie.v1
//
//  Created by Jared Terrance on 8/30/22.
//

import Cocoa
import AVFoundation

struct DeviceManager
{
    internal init(devices: [DeviceInterface])
    {
        self.session = AVCaptureSession()
        self.session.beginConfiguration()
        
        getAuthorization(devices: devices)
    }
    
    var session: AVCaptureSession! = AVCaptureSession()
    
    func requestAccess(mediaType: AVMediaType) -> Bool
    {
        var hasAccess: Bool = false
        
        AVCaptureDevice.requestAccess(for: mediaType)
        {
            granted in
            if granted
            {
                hasAccess = true
            }
        }
        
        return hasAccess
    }
    
    func getAuthorization(devices: [DeviceInterface])
    {
        let mediaType = devices.first?.mediaType ?? .video
        
        switch AVCaptureDevice.authorizationStatus(for: mediaType)
        {
        case .authorized:
            setupCaptureSession(devices: devices)
            
        case .notDetermined:
            if requestAccess(mediaType: mediaType)
            {
                for device in devices {
                    getAuthorization(devices: [device])
                }
            }
            
        case .restricted:
            return
            
        case .denied:
            return
            
        @unknown default:
            return
        }
    }
    
    func startRunning()
    {
        session.commitConfiguration()
        session.startRunning()
    }
    
    func setupCaptureSession(devices: [DeviceInterface]! = nil)
    {
        for device in devices {
            addCaptureSessionInput(device: device)
        }
    }
    
    func addCaptureSessionInput(device: DeviceInterface)
    {
        let deviceInput = try? AVCaptureDeviceInput(device: device.device)
        if deviceInput == nil { return }
        
        if session.canAddInput(deviceInput!) {
            session.addInput(deviceInput!)
        }
    }
}
