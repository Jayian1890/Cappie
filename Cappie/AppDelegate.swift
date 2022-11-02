//
//  AppDelegate.swift
//  Cappie.v1
//
//  Created by Jared Terrance on 8/30/22.
//

import Cocoa
import AVFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate, AVCaptureFileOutputRecordingDelegate
{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?)
    {
    }
    
    @IBOutlet var view: NSView!
    @IBOutlet var mainMenu: NSMenu!
    @IBOutlet var videoMenu: NSMenu!
    @IBOutlet var audioMenu: NSMenu!
    @IBOutlet var recordMenu: NSMenu!
    
    var currentVideoDevice: DeviceInterface!
    var currentAudioDevice: DeviceInterface!
    
    let deviceManager: DeviceManager = DeviceManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        generateMenuItems(menu: videoMenu, mediaType: .video)
        generateMenuItems(menu: audioMenu, mediaType: .audio)
        
        recordMenu.items.append(NSMenuItem(title: "Start", action: #selector(toggleRecoding(_:)), keyEquivalent: ""))
    }
    
    func generateMenuItems(menu: NSMenu, mediaType: AVMediaType)
    {
        let videoDevices = DeviceManager.getAllDevices(mediaType: mediaType)
        
        videoDevices.forEach() { device in
            let menuItem = NSMenuItem(title: device.deviceName, action: #selector(updateInputMenuItem(_:)), keyEquivalent: "")
            menuItem.representedObject = device
            
            menu.items.append(menuItem)
        }
    }
    
    func updatePreview()
    {
        deviceManager.resetInputs()
        deviceManager.resetOutputs()
        
        if currentVideoDevice != nil {
            deviceManager.configure(interface: currentVideoDevice)
        }
        
        if currentAudioDevice != nil {
            deviceManager.configure(interface: currentAudioDevice)
        }
        
        deviceManager.startRunning()
        setPreviewLayer(session: deviceManager.getSession())
    }
    
    func setPreviewLayer(session: AVCaptureSession)
    {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.backgroundColor = CGColor.black
        self.view.layer = layer
    }
    
    @objc func updateInputMenuItem(_ sender: NSMenuItem)
    {
        let interface: DeviceInterface = sender.representedObject as! DeviceInterface
        
        if interface.mediaType == .video  {
            currentVideoDevice = interface
            videoMenu.items.forEach { item in item.state = .off }
        }
        else if interface.mediaType == .audio {
            currentAudioDevice = interface
            audioMenu.items.forEach { item in item.state = .off }
        }
        
        updatePreview()
        sender.state = .on
    }
    
    func toggleAudio()
    {
        let output = deviceManager.getSession().outputs.first as! AVCaptureAudioPreviewOutput
        if (currentAudioDevice.deviceType.contains(AVCaptureDevice.DeviceType.builtInMicrophone)) {
            output.volume = 0
        } else {
            output.volume = 1
        }
    }
    
    @objc func toggleRecoding(_ sender: NSMenuItem)
    {
        let videoOutput = deviceManager.videoOutput
        
        if (videoOutput.isRecording) {
            videoOutput.stopRecording()
            deviceManager.getSession().removeOutput(videoOutput)
            
            recordMenu.items.first(where: {$0.title == "Stop"})!.title = "Start"
        } else {
            deviceManager.queue.async { [self] in
                deviceManager.getSession().addOutput(videoOutput)
            }
            
            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = generateFileName()
            savePanel.begin { [self] (result) in
                if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                    let connection = videoOutput.connection(with: .video)
                    if (connection == nil) {
                        return
                    }
                    
                    videoOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.h264], for: connection!)
                    videoOutput.startRecording(to: savePanel.url!, recordingDelegate: self)
                    
                    recordMenu.items.first(where: {$0.title == "Start"})!.title = "Stop"
                }
            }
        }
    }
    
    private func generateFileName() -> String
    {
        return "cappie-\(NSDate.timeIntervalSinceReferenceDate).mov"
    }
    
    func applicationWillTerminate(_ aNotification: Notification)
    {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool
    {
        true;
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool
    {
        return true
    }
}
