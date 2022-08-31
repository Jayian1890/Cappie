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
    
    var videoManager: DeviceManager = DeviceManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        var interface: DeviceInterface
        
        interface = DeviceInterface(searchName: "USB", mediaType: .video)
        let videoDevice = interface.device
        
        interface = DeviceInterface(searchName: "USB", mediaType: .audio)
        let audioDevice = interface.device
        
        videoManager.setupConfiguration(devices: [ videoDevice, audioDevice ])
        
        view.layer = videoManager.createPreviewLayer()
        videoManager.startRunning()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true;
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
}
