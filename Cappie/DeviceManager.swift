//
//  DeviceAccess.swift
//  Cappie.v1
//
//  Created by Jared Terrance on 8/30/22.
//

import Cocoa
import AVFoundation

class DeviceManager
{
    private var session: AVCaptureSession!
    private var devices: [DeviceInterface]!
    
    var queue: DispatchQueue = DispatchQueue(label: "com.cappie.DeviceManager")
    
    func configure(captureDevices: [AVCaptureDevice])
    {
        self.devices = [DeviceInterface]()
        
        session = AVCaptureSession()
        session.beginConfiguration()
        
        captureDevices.forEach() { device in
            let deviceInterface = DeviceInterface(searchName: device.localizedName)
            self.configure(interface: deviceInterface)
            self.devices.append(deviceInterface)
        }
    }
    
    func configure(deviceInterfaces: [DeviceInterface])
    {
        self.devices = deviceInterfaces
        
        session = AVCaptureSession()
        session.beginConfiguration()
        
        self.devices.forEach() { device in
            self.configure(interface: device)
        }
    }
    
    func configure(interface: DeviceInterface)
    {
        queue.async {
            let input = try? AVCaptureDeviceInput(device: interface.device)
            
            let mediaType = interface.mediaType
            
            switch AVCaptureDevice.authorizationStatus(for: mediaType)
            {
            case .authorized:
                self.addInput(input: input)
                
            case .notDetermined:
                if self.requestAccess(mediaType: mediaType) {
                    self.configure(interface: interface)
                }
                
            case .restricted:
                return
                
            case .denied:
                return
                
            @unknown default:
                return
            }
        }
    }
    
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
    
    func startRunning()
    {
        session.commitConfiguration()
        session.startRunning()
    }
    
    func addInput(input: AVCaptureDeviceInput?)
    {
        if input == nil { return }
        
        if session.canAddInput(input!) {
            session.addInput(input!)
        }
    }
    
    func addInput(inputs: [AVCaptureDeviceInput])
    {
        for input in inputs {
            self.addInput(input: input)
        }
    }
    
    func addInput(interface: DeviceInterface)
    {
        let input = try? AVCaptureDeviceInput(device: interface.device)
        self.addInput(input: input)
    }
    
    func resetInputs()
    {
        session.inputs.forEach { input in
            session.removeInput(input)
        }
    }
    
    func getSession() -> AVCaptureSession
    {
        return self.session
    }
    
    func getDevices() -> [DeviceInterface]!
    {
        return self.devices
    }
    
    static func getAllDevices(mediaType: AVMediaType) -> [DeviceInterface]
    {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.externalUnknown, .builtInMicrophone, .builtInWideAngleCamera],
            mediaType: mediaType,
            position: .unspecified
        )
        
        var deviceInterfaces = [DeviceInterface]()
        
        discoverySession.devices.forEach { device in
            let interface = DeviceInterface(searchName: device.localizedName, mediaType: mediaType)
            deviceInterfaces.append(interface)
        }
        
        return deviceInterfaces
    }
}
