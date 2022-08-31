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
    internal init(captureSession: AVCaptureSession? = AVCaptureSession()) {
        self.captureSession = captureSession
        
        self.captureSession.beginConfiguration()
    }
    
    private var captureSession: AVCaptureSession! = AVCaptureSession()
    
    func setupConfiguration(devices: [AVCaptureDevice]! = nil, mediaType: AVMediaType = .video)
    {
        switch AVCaptureDevice.authorizationStatus(for: mediaType)
        {
        case .authorized: // The user has previously granted access to the camera.
            setupCaptureSession(devices: devices)
            
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: mediaType)
            {
                granted in
                if granted
                {
                    setupConfiguration(devices: devices)
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
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    func setupCaptureSession(devices: [AVCaptureDevice]! = nil)
    {
        for device in devices {
            addCaptureSessionInput(device: device)
        }
    }
    
    func addCaptureSessionInput(device: AVCaptureDevice)
    {
        let deviceInput = try? AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(deviceInput!) {
            captureSession.addInput(deviceInput!)
        }
    }
    
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer!
    {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.backgroundColor = CGColor.black
        return layer
    }
    
    func getSession() -> AVCaptureSession
    {
        return captureSession
    }
    
    internal static func getCaptureDevice(deviceName: String, mediaType: AVMediaType) -> AVCaptureDevice!
    {
        let devices = DeviceManager.getCaptureDevices(mediaType: mediaType)
        return devices.first { $0.localizedName.contains(deviceName) }
    }
    
    internal static func getCaptureDevices(deviceTypes: AVCaptureDevice.DeviceType = .externalUnknown, mediaType: AVMediaType = .metadata, position: AVCaptureDevice.Position = .unspecified) -> [AVCaptureDevice]
    {
        var discoverySession: AVCaptureDevice.DiscoverySession
        
        switch mediaType
        {
        case .audio:
            discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified)
            
        case .video:
            discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInMicrophone, .externalUnknown], mediaType: .video, position: .unspecified)
            
        default:
            discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [deviceTypes], mediaType: mediaType, position: position)
        }
        
        return discoverySession.devices
    }
}
