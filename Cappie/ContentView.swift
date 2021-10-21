//
//  ContentView.swift
//  Cappie
//
//  Created by Jay on 10/3/21.
//

import SwiftUI
import AVFoundation
import SimplyCoreAudio

struct ContentView: View {
    @State var selectedDevice = AVCaptureDevice.default(.externalUnknown, for: AVMediaType.video, position: .unspecified)

    @ObservedObject var manager = DevicesManager.shared
    
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
    
    let simplyCA = SimplyCoreAudio()
    var audioPlayer: AVAudioPlayer?
    @State var selectedAudioDevice = SimplyCoreAudio().defaultInputDevice
    
    func audioPreview(input: Binding<AudioDevice?>) -> AnyView {
        audioPlayer?.currentDevice = selectedAudioDevice?.uid
        audioPlayer?.play()
        return AnyView(Text(""))
    }
    
    var body: some View {
        VStack {
            audioPreview(input: $selectedAudioDevice)
            cameraPreview(device: $selectedDevice)
            
            HStack {
                Picker(selection: $selectedDevice.animation(.linear), label: Text("")) {
                    ForEach(manager.devices, id: \.self) { device in
                        Text(device.localizedName).tag(device as AVCaptureDevice?)
                    }
                }
                Picker(selection: $selectedAudioDevice, label: Text("")) {
                    ForEach(simplyCA.allInputDevices, id: \.self) { device in
                        Text(device.name).tag(device as AudioDevice?)
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
