//
//  AppDelegate.swift
//  Cappie
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
        
        audioMenu.items.append(.separator())
        recordMenu.items.append(NSMenuItem(title: "Start", action: #selector(toggleRecoding(_:)), keyEquivalent: ""))
        
        audioMenu.items.append(.separator())
        audioMenu.items.append(NSMenuItem(title: "Mute", action: #selector(toggleAudio(_:)), keyEquivalent: ""))
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
    
    func setPreviewLayer(session: AVCaptureSession)
    {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.backgroundColor = CGColor.black
        self.view.layer = layer
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
    
    @objc func toggleAudio(_ sender: NSMenuItem)
    {
        if deviceManager.getVolume() > 0 {
            sender.state = .on
            deviceManager.mute()
        } else {
            sender.state = .off
            deviceManager.unmute()
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
