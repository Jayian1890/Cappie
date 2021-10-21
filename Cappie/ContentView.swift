//
//  ContentView.swift
//  Cappie
//
//  Created by Jay on 10/3/21.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State var videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    @State var audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)

    @ObservedObject var videoManager = DevicesManager.init(session: AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown], mediaType: .video, position: .unspecified))
    @ObservedObject var audioManager = DevicesManager.init(session: AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified))
    
    func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else {
                    return
                }
            }
            break
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            break
        @unknown default:
            break
        }
    }
    
    func cameraPreview(device: Binding<AVCaptureDevice?>) -> AnyView {
        checkCameraPermissions()
        return AnyView(CameraPreview(captureDevice: device))
    }
    
    var audioPlayer: AVAudioPlayer?
    
    func audioPreview(input: Binding<AVCaptureDevice?>) -> AnyView {
        audioPlayer?.currentDevice = audioDevice?.uniqueID
        audioPlayer?.play()
        return AnyView(Text(""))
    }
    
    var body: some View {
        VStack {
            cameraPreview(device: $videoDevice)
            //audioPreview(input: $audioDevice)
            
            HStack {
                Picker(selection: $videoDevice.animation(.linear), label: Text("")) {
                    ForEach(videoManager.devices, id: \.self) { device in
                        Text(device.localizedName).tag(device as AVCaptureDevice?)
                    }
                }
                Picker(selection: $audioDevice.animation(.linear), label: Text("")) {
                    ForEach(audioManager.devices, id: \.self) { device in
                        Text(device.localizedName).tag(device as AVCaptureDevice?)
                    }
                }
            }
            .padding(.trailing, 7.0)
        }
        .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color(hue: 1.0, saturation: 0.0, brightness: 0.0)/*@END_MENU_TOKEN@*/)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
