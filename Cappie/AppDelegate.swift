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
    @IBOutlet var fileMenu: NSMenu!
    @IBOutlet var videoMenu: NSMenu!
    @IBOutlet var audioMenu: NSMenu!
    @IBOutlet var settingsMenu: NSMenu!
    
    var currentVideoDevice: DeviceInterface!
    var currentAudioDevice: DeviceInterface!
    
    let deviceManager: DeviceManager = DeviceManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        generateMenuItems(menu: videoMenu, mediaType: .video)
        generateMenuItems(menu: audioMenu, mediaType: .audio)
        
        if (videoMenu.items.count > 1) {
            //updateInputMenuItem(videoMenu.items.first!)
            //updateInputMenuItem(audioMenu.items.first!)
        }
        
        fileMenu.items.append(.separator())
        fileMenu.items.append(NSMenuItem(title: "Record to file", action: #selector(toggleRecoding(_:)), keyEquivalent: "r"))
        fileMenu.items.append(NSMenuItem(title: "Stream to Twitch", action: #selector(startStreaming(_:)), keyEquivalent: "t"))
        
        audioMenu.items.append(.separator())
        audioMenu.items.append(NSMenuItem(title: "Mute", action: #selector(toggleAudio(_:)), keyEquivalent: "m"))
    }
    
    @objc func startStreaming(_ sender: NSMenuItem)
    {
        
    }
    
    func generateMenuItems(menu: NSMenu, mediaType: AVMediaType)
    {
        let videoDevices = DeviceManager.getAllDevices(mediaType: mediaType)
        
        for i in (0 ..< videoDevices.count) {
            let keyEquivalent: String = i < 10 ? i.description : ""
            let device = videoDevices[i]
            
            let menuItem = NSMenuItem(title: device.deviceName, action: #selector(updateInputMenuItem(_:)), keyEquivalent: keyEquivalent)
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
        if (!deviceManager.toggleMute())
        {
            sender.state = .on
            setWindowSubTitle(subtitle: "Muted")
        } else {
            sender.state = .off
            setWindowSubTitle(subtitle: "")
        }
    }
    
    @objc func toggleRecoding(_ sender: NSMenuItem)
    {
        let videoOutput = deviceManager.videoOutput
        
        if (videoOutput.isRecording) {
            videoOutput.stopRecording()
            deviceManager.getSession().removeOutput(videoOutput)
            
            setWindowSubTitle(subtitle: "")
            fileMenu.items.first(where: {$0.title == "Stop recording"})!.title = "Record to file"
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
                    
                    //videoOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.h264], for: connection!)
                    videoOutput.startRecording(to: savePanel.url!, recordingDelegate: self)
                    
                    setWindowSubTitle(subtitle: "Recording")
                    fileMenu.items.first(where: {$0.title == "Record to file"})!.title = "Stop recording"
                }
            }
        }
    }
    
    private func generateFileName() -> String
    {
        return "cappie-\(NSDate.timeIntervalSinceReferenceDate).mov"
    }
    
    func setWindowSubTitle(subtitle: String) {
        view.window?.subtitle = subtitle
    }
    
    func applicationWillTerminate(_ aNotification: Notification)
    {
        deviceManager.stopRunning()
        print("Cappie: Application will terminate")
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
