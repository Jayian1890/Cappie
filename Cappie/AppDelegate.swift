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
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        let videoDevice = DeviceInterface(searchName: "USB", mediaType: .video)
        let audioDevice = DeviceInterface(searchName: "USB", mediaType: .audio)
        
        let deviceManager: DeviceManager = DeviceManager()
        deviceManager.configure(deviceInterfaces: [videoDevice, audioDevice])
        deviceManager.startRunning()
        
        setPreviewLayer(session: deviceManager.getSession())
        generateMenuItems(menu: videoMenu, mediaType: .video)
        generateMenuItems(menu: audioMenu, mediaType: .audio)
    }
    
    func generateMenuItems(menu: NSMenu, mediaType: AVMediaType)
    {
        let videoDevices = DeviceManager.getAllDevices(mediaType: mediaType)
        
        videoDevices.forEach() { device in
            let menuItem = NSMenuItem(title: device.deviceName, action: #selector(updateInput(_:)), keyEquivalent: "")
            menuItem.representedObject = device
            
            menu.items.append(menuItem)
        }
    }
    
    @objc func updateInput(_ sender: NSMenuItem)
    {
        let devices = sender.representedObject as! DeviceInterface
        
        let deviceManager = DeviceManager()
        deviceManager.configure(deviceInterfaces: [devices])
        deviceManager.startRunning()
        
        setPreviewLayer(session: deviceManager.getSession())
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
    
    func setPreviewLayer(session: AVCaptureSession)
    {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.backgroundColor = CGColor.black
        self.view.layer = layer
    }
}
