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
    private var videoOutput: AVCaptureMovieFileOutput!
    
    public var queue: DispatchQueue = DispatchQueue(label: "com.cappie.DeviceManager")
    
    func configure(captureDevices: [AVCaptureDevice])
    {
        devices = [DeviceInterface]()
        
        session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .hd1920x1080
        
        captureDevices.forEach() { device in
            let deviceInterface = DeviceInterface(searchName: device.localizedName)
            configure(interface: deviceInterface)
            devices.append(deviceInterface)
        }
    }
    
    func configure(deviceInterfaces: [DeviceInterface])
    {
        devices = deviceInterfaces
        
        session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .hd1920x1080
        
        devices.forEach() { device in
            configure(interface: device)
        }
    }
    
    func configure(interface: DeviceInterface)
    {
        resetInputs()
        resetOutputs()
        
        queue.async {
            let input = try? AVCaptureDeviceInput(device: interface.device)
            
            let mediaType = interface.mediaType
            
            switch AVCaptureDevice.authorizationStatus(for: mediaType)
            {
            case .authorized:
                self.addInput(input: input)
                if (mediaType == .audio) {
                    self.addAudioOutput(deviceUID: interface.device.uniqueID)
                }
                
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
            addInput(input: input)
        }
    }
    
    func addInput(interface: DeviceInterface)
    {
        let input = try? AVCaptureDeviceInput(device: interface.device)
        addInput(input: input)
    }
    
    func resetInputs()
    {
        session.inputs.forEach { input in
            session.removeInput(input)
        }
    }
    
    func addVideoOutput(deviceUID: String)
    {
        videoOutput = AVCaptureMovieFileOutput()
        
        let connection = videoOutput.connection(with: .video)
        
        // Use the H.264 codec to encode the video.
        videoOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.h264], for: connection!)
        
        session.addOutput(videoOutput)
    }
    
    func addAudioOutput(deviceUID: String)
    {
        let audioOutput = AVCaptureAudioPreviewOutput()
        audioOutput.outputDeviceUniqueID = deviceUID
        audioOutput.volume = 1
        
        session.addOutput(audioOutput)
    }
    
    func resetOutputs()
    {
        session.outputs.forEach { output in
            session.removeOutput(output)
        }
    }
    
    func getSession() -> AVCaptureSession
    {
        return session
    }
    
    func getDevices() -> [DeviceInterface]!
    {
        return devices
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
