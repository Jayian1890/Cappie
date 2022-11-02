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
    
    @IBOutlet var title: String! = "Cappie: ALPHA 1.0"
    var currentVideoDevice: DeviceInterface!
    var currentAudioDevice: DeviceInterface!
    
    let deviceManager: DeviceManager = DeviceManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        view.window?.title = title
        
        generateMenuItems(menu: videoMenu, mediaType: .video)
        generateMenuItems(menu: audioMenu, mediaType: .audio)
        
        recordMenu.items.append(NSMenuItem(title: "Start", action: #selector(toggleRecoding(_:)), keyEquivalent: ""))
    }
    
    @IBAction func updateAudioMenu(_ sender: Any)
    {
        generateMenuItems(menu: audioMenu, mediaType: .audio)
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
        } else {
            //currentVideoDevice = DeviceInterface(searchName: "USB", mediaType: .video)
        }
        
        if currentAudioDevice != nil {
            deviceManager.configure(interface: currentAudioDevice)
        } else {
            //currentAudioDevice = DeviceInterface(searchName: "USB", mediaType: .audio)
        }
        
        //deviceManager.configure(deviceInterfaces: [currentVideoDevice, currentAudioDevice])
        deviceManager.startRunning()
        
        setPreviewLayer(session: deviceManager.getSession())
        //view.window?.title = title + " - " + currentVideoDevice.deviceName + " - " + currentAudioDevice.deviceName
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
            //updatePreview(videoDevice: interface)
            currentVideoDevice = interface
            videoMenu.items.forEach { item in item.state = .off }
        }
        else if interface.mediaType == .audio {
            //updatePreview(audioDevice: interface)
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
    
    private func createTempFileURL() -> URL
    {
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.downloadsDirectory,
                                                       FileManager.SearchPathDomainMask.userDomainMask, true).last
        let pathURL = NSURL.fileURL(withPath: path!)
        let fileURL = pathURL.appendingPathComponent(generateFileName())
        
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
