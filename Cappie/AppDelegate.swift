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
    
    var videoManager: DeviceManager!
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        let videoDevice = DeviceInterface(searchName: "USB", mediaType: .video)
        let audioDevice = DeviceInterface(searchName: "USB", mediaType: .audio)
        
        videoManager = DeviceManager(devices: [ videoDevice, audioDevice ])
        videoManager.startRunning()
        
        setPreviewLayer()
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
    
    func setPreviewLayer()
    {
        let layer = AVCaptureVideoPreviewLayer(session: videoManager.session)
        layer.backgroundColor = CGColor.black
        self.view.layer = layer
    }
}
