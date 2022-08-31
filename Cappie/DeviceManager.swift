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
    func setupConfiguration(devices: [AVCaptureDevice]! = nil) -> AVCaptureSession
    {
        var captureSession: AVCaptureSession = AVCaptureSession()
        
        switch AVCaptureDevice.authorizationStatus(for: .video)
        {
        case .authorized: // The user has previously granted access to the camera.
            captureSession = setupCaptureSession(devices: devices)
            
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video)
            {
                granted in
                if granted
                {
                    captureSession = setupConfiguration(devices: devices)
                }
            }
        case .restricted:
            return captureSession
        case .denied:
            return captureSession
        @unknown default:
            return captureSession
        }
        
        return captureSession
    }
    
    func setupCaptureSession(devices: [AVCaptureDevice]! = nil) -> AVCaptureSession!
    {
        let captureSession = AVCaptureSession()
        
        captureSession.beginConfiguration()
        
        for device in devices {
            let deviceInput = try? AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(deviceInput!) {
                captureSession.addInput(deviceInput!)
            }
        }
        
        let deviceOutput = AVCaptureVideoDataOutput()
        guard captureSession.canAddOutput(deviceOutput) else { return nil }
        captureSession.sessionPreset = .high
        captureSession.addOutput(deviceOutput)
        
        captureSession.commitConfiguration()
        
        captureSession.startRunning()
        
        return captureSession
    }
    
    internal static func getCaptureDevices(mediaType: AVMediaType = .video) -> [AVCaptureDevice]
    {
        var discoverySession: AVCaptureDevice.DiscoverySession
        
        switch mediaType
        {
        case .audio:
            discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [
                .builtInMicrophone
            ], mediaType: .audio, position: .unspecified)
            
        case .video:
            discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [
                .builtInWideAngleCamera, .builtInMicrophone, .externalUnknown
            ], mediaType: mediaType, position: .unspecified)
            
        default:
            return [AVCaptureDevice]()
        }
        
        if (discoverySession.devices.isEmpty)
        { return [AVCaptureDevice]() }
        
        return discoverySession.devices
    }
}
