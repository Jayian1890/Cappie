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
    
    func getCaptureDevice(deviceName: String) -> AVCaptureDevice!
    {
        var devices = DeviceManager.getCaptureDevices(mediaType: .video)
        for device in devices {
            if device.localizedName.contains(deviceName) {
                return device
            }
        }
        
        devices = DeviceManager.getCaptureDevices(mediaType: .audio)
        for device in devices {
            if device.localizedName.contains(deviceName) {
                return device
            }
        }
        return nil
    }
    
    func setupCaptureSession(devices: [AVCaptureDevice]! = nil)
    {
        for device in devices {
            addCaptureSessionInput(device: device)
        }
        
        //addCaptureSessionOutput()
    }
    
    func addCaptureSessionInput(device: AVCaptureDevice)
    {
        let deviceInput = try? AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(deviceInput!) {
            captureSession.addInput(deviceInput!)
        }
    }
    
    func addCaptureSessionOutput()
    {
        let deviceOutput = AVCaptureVideoDataOutput()
        guard captureSession.canAddOutput(deviceOutput) else { return }
        captureSession.sessionPreset = .high
        captureSession.addOutput(deviceOutput)
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
    
    internal static func getCaptureDevices(mediaType: AVMediaType = .video) -> [AVCaptureDevice]
    {
        var discoverySession: AVCaptureDevice.DiscoverySession
        
        switch mediaType
        {
        case .audio:
            let device = AVCaptureDevice.default(for: AVMediaType.audio)
            return [ device! ]
            
        case .video:
            discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [
                .builtInWideAngleCamera, .builtInMicrophone, .externalUnknown
            ], mediaType: .video, position: .unspecified)
            
        default:
            return [AVCaptureDevice]()
        }
        
        if (discoverySession.devices.isEmpty)
        { return [AVCaptureDevice]() }
        
        return discoverySession.devices
    }
}
