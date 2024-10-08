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
    internal init() {
        videoOutput = AVCaptureMovieFileOutput()
        
        session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = preset
    }
    
    private var frameRate: Double = 60
    
    private var session: AVCaptureSession
    private var volume: Float = 1
    
    public var videoOutput: AVCaptureMovieFileOutput
    public var preset: AVCaptureSession.Preset = .hd1920x1080
    public var queue: DispatchQueue = DispatchQueue(label: "com.cappie.DeviceManager")
    
    func configure(interface: DeviceInterface)
    {
        queue.async
        {
            let mediaType = interface.mediaType
            
            switch AVCaptureDevice.authorizationStatus(for: mediaType)
            {
            case .authorized:
                self.addInput(interface: interface)
                if (mediaType == .video) {
                    interface.device.set(frameRate: self.frameRate)
                } else if (mediaType == .audio) {
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
        print("stopping device manager...")
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


/// Sets the frame rate(FPS) of the current capture device.
///  - parameters:
///     - frameRate: The Frame Rate to be set on the current capture device.
///  - returns:
///     void()
extension AVCaptureDevice {
    func set(frameRate: Double, width: Int = 1920, height: Int = 1080) {
        var foundSupportedFormat: Bool = false
        for format in formats {
            let ranges = format.videoSupportedFrameRateRanges
            if ranges.first(where: { $0.maxFrameRate >= frameRate }) != nil {
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                if dimensions.width == width && dimensions.height == height {
                    do {
                        try lockForConfiguration()
                        activeFormat = format
                        let minRate = ranges.first?.minFrameDuration.timescale
                        let maxRate = ranges.first?.maxFrameDuration.timescale
                        activeVideoMinFrameDuration.timescale = minRate!
                        activeVideoMaxFrameDuration.timescale = maxRate!
                        unlockForConfiguration()
                        foundSupportedFormat = true
                        break
                    } catch {
                        print("Error setting active format: (error.localizedDescription)")
                    }
                }
            }
        }
        if !foundSupportedFormat {
            print("No supported format found for the desired frame rate of (desiredFrameRate) FPS and resolution of (desiredWidth)x(desiredHeight).")
        }
    }
}
