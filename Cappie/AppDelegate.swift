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
    @IBOutlet var menu: NSMenu!
    @IBOutlet var videoMenu: NSMenu!
    @IBOutlet var audioMenu: NSMenu!
    @IBOutlet var muteMenu: NSMenu!
    @IBOutlet var recordMenu: NSMenuItem!
    
    var title: String! = "Cappie"
    var currentVideoDevice: DeviceInterface!
    var currentAudioDevice: DeviceInterface!
    
    let deviceManager: DeviceManager = DeviceManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        currentVideoDevice = DeviceInterface(searchName: "USB", mediaType: .video)
        currentAudioDevice = DeviceInterface(searchName: "USB", mediaType: .audio)
        
        generateMenuItems(menu: videoMenu, mediaType: .video)
        generateMenuItems(menu: audioMenu, mediaType: .audio)
        
        videoMenu.items.first?.state = .on
        audioMenu.items.first?.state = .on
        
        videoMenu.items.append(.separator())
        videoMenu.items.append(NSMenuItem(title: "Record", action: #selector(startRecording(_:)), keyEquivalent: ""))
        
        audioMenu.items.append(.separator())
        audioMenu.items.append(NSMenuItem(title: "Mute", action: #selector(muteAudio(_:)), keyEquivalent: ""))
        
        updatePreview(videoDevice: currentVideoDevice)
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
    
    func updatePreview(videoDevice: DeviceInterface! = nil, audioDevice: DeviceInterface! = nil)
    {
        if videoDevice != nil {
            currentVideoDevice = videoDevice
        }
        
        if audioDevice != nil {
            currentAudioDevice = audioDevice
        }
        
        deviceManager.configure(deviceInterfaces: [currentVideoDevice, currentAudioDevice])
        deviceManager.startRunning()
        
        setPreviewLayer(session: deviceManager.getSession())
        view.window?.title = title + " - " + currentVideoDevice.deviceName + " - " + currentAudioDevice.deviceName
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
            updatePreview(videoDevice: interface)
            videoMenu.items.forEach { item in item.state = .off }
        }
        else if interface.mediaType == .audio {
            updatePreview(audioDevice: interface)
            audioMenu.items.forEach { item in item.state = .off }
        }
        
        sender.state = .on
    }
    
    @objc func muteAudio(_ sender: NSMenuItem)
    {
        let output = deviceManager.getSession().outputs.first as! AVCaptureAudioPreviewOutput
        
        if sender.state == .on {
            sender.state = .off
            output.volume = 1
        } else {
            sender.state = .on
            output.volume = 0
        }
    }
    
    @objc func startRecording(_ sender: NSMenuItem)
    {
        let videoOutput = AVCaptureMovieFileOutput()
        
        // Use the H.264 codec to encode the video.
        //videoOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.h264], for: connection!)
        
        deviceManager.getSession().addOutput(videoOutput)
        
        let outFileUrl = createTempFileURL()
        videoOutput.startRecording(to: outFileUrl, recordingDelegate: self)
    }
    
    private func createTempFileURL() -> URL
    {
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.downloadsDirectory,
                                                       FileManager.SearchPathDomainMask.userDomainMask, true).last
        let pathURL = NSURL.fileURL(withPath: path!)
        let fileURL = pathURL.appendingPathComponent("movie-\(NSDate.timeIntervalSinceReferenceDate).mov")
        print(" video url:  \(fileURL)")
        return fileURL
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
