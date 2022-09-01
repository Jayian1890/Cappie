//
//  AppDelegate.swift
//  Cappie.v1
//
//  Created by Jared Terrance on 8/30/22.
//

import Cocoa
import AVFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var view: NSView!
    @IBOutlet var menu: NSMenu!
    @IBOutlet var videoMenu: NSMenu!
    @IBOutlet var audioMenu: NSMenu!
    
    var currentVideoDevice: DeviceInterface!
    var currentAudioDevice: DeviceInterface!
    
    let deviceManager: DeviceManager = DeviceManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        currentVideoDevice = DeviceInterface(searchName: "USB", mediaType: .video)
        currentAudioDevice = DeviceInterface(searchName: "USB", mediaType: .audio)
        
        generateMenuItems(menu: videoMenu, mediaType: .video)
        updatePreview(interface: currentVideoDevice)
        
        generateMenuItems(menu: audioMenu, mediaType: .audio)
        updatePreview(interface: currentAudioDevice)
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
    
    func updatePreview(interface: DeviceInterface)
    {
        if interface.mediaType == .video {
            currentVideoDevice = interface
        }
        
        if interface.mediaType == .audio {
            currentAudioDevice = interface
        }
        
        deviceManager.configure(deviceInterfaces: [currentVideoDevice, currentAudioDevice])
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
        updatePreview(interface: sender.representedObject as! DeviceInterface)
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
