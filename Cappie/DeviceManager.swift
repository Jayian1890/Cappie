//
//  DeviceAccess.swift
//  Cappie
//
//  Created by Jared Terrance on 8/30/22.
//

import Cocoa
import AVFoundation

class DeviceManager
{
    public var MaxFps: Double = 60
    
    internal init() {
        videoOutput = AVCaptureMovieFileOutput()
        
        session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = preset
    }
    
    private var session: AVCaptureSession
    private var volume: Float = 1
    
    public var videoOutput: AVCaptureMovieFileOutput
    public var preset: AVCaptureSession.Preset = .hd1920x1080
    public var queue: DispatchQueue = DispatchQueue(label: "com.cappie.DeviceManager")
    
    func configure(interface: DeviceInterface)
    {
        queue.async {
            let input = try? AVCaptureDeviceInput(device: interface.device)
            
            let mediaType = interface.mediaType
            
            switch AVCaptureDevice.authorizationStatus(for: mediaType)
            {
            case .authorized:
                self.addInput(input: input)
                if (mediaType == .audio) {
                    self.addAudioOutput(deviceUID: interface.device.uniqueID)
                } else {
                    self.setFrameRate(device: interface.device)
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
    
    /// Sets the frame rate(FPS) of the current capture device.
    ///  - parameters:
    ///     - device: The capture device to set the frame rate for.
    ///     - frameRate: The Frame Rate to be set on the current capture device.
    ///  - returns:
    ///     void()
    func setFrameRate(device: AVCaptureDevice, frameRate: Double = 30)
    {
        for vFormat in device.formats {
            do {
                let ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
                let frameRates = ranges[0]
                
                if frameRates.maxFrameRate > frameRate
                {
                    self.MaxFps = frameRates.maxFrameRate
                    
                    try device.lockForConfiguration()
                    device.activeFormat = vFormat
                    device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
                    device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
                    device.unlockForConfiguration()
                }
            } catch {
                let alert = NSAlert()
                alert.messageText = "error setting framerate. unsupported"
                //alert.informativeText = text
                alert.addButton(withTitle: "Error!")
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }
    
    /// Requests access to the system's camera devices
    ///  - returns:
    ///     void()
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
    
    /// Starts the current sessions and begins recording the current assigned preview layer
    ///  - returns:
    ///     void()
    func startRunning()
    {
        session.commitConfiguration()
        session.startRunning()
    }
    
    /// Stops the current session from running.
    /// - returns:
    ///     void()
    func stopRunning()
    {
        resetInputs()
        resetOutputs()
        session.stopRunning()
    }
    
    /// Changes the volume of the curent audio session.
    /// - Parameters:
    ///     - volume: Current float value of AVCaptureAudioPreviewOutput.Volume
    /// - Returns:
    ///     void()
    func setVolume(volume: Float)
    {
        let output = getAudioOutput()
        
        output.volume = self.volume
    }
    
    /// Returns 'volume' for the current audio session
    /// - Returns:
    ///     Float value of AVCaptureAudioPreviewOutput.Volume
    func getVolume() -> Float
    {
        return getAudioOutput().volume
    }
    
    /// Decreases the volume of the current audio session to 0
    ///  - Returns:
    ///     void()
    func mute()
    {
        self.volume = getAudioOutput().volume
        getAudioOutput().volume = 0
    }
    
    /// Restores the last known volume prior to the mute() funcion
    /// - Returns:
    ///     void()
    func unmute()
    {
        getAudioOutput().volume = self.volume
    }
    
    /// Toggles the current volume on & off
    ///  - Returns:
    ///     void()
    func toggleMute() -> Bool
    {
        let output = getAudioOutput()
        
        switch (output.volume) {
        case 0:
            unmute()
        default:
            mute()
        }
        
        return output.volume > 0.0
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
    
    func getAudioOutput() -> AVCaptureAudioPreviewOutput
    {
        if getSession().outputs.count <= 0 {
            return AVCaptureAudioPreviewOutput()
        }
        
        return  getSession().outputs.first as! AVCaptureAudioPreviewOutput
    }
    
    static func getAllDevices(mediaType: AVMediaType) -> [DeviceInterface]
    {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.externalUnknown, .builtInMicrophone],
            mediaType: mediaType,
            position: .unspecified
        )
        
        var deviceInterfaces = [DeviceInterface]()
        
        discoverySession.devices.forEach { device in
            let interface = DeviceInterface(searchName: device.localizedName, mediaType: mediaType)
            deviceInterfaces.append(interface)
        }
        
        return deviceInterfaces.sorted(by: {$0.deviceName > $1.deviceName})
    }
}
