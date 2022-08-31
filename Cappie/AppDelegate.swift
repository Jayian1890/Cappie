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
        let audioDevice = DeviceManager.getCaptureDevice(deviceName: "USB", mediaType: .audio)
        let videoDevice = DeviceManager.getCaptureDevice(deviceName: "USB", mediaType: .video)
        
        videoManager.setupConfiguration(devices: [ audioDevice!, videoDevice! ])
        
        view.layer = videoManager.getPreviewLayer()
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
