//
//  ContentView.swift
//  Cappie
//
//  Created by Jay on 10/3/21.
//

import SwiftUI
import AVFoundation

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
        return AnyView(CameraPreview(captureDevice: device))
    }
    
    var body: some View {
        VStack {
            /*Picker(selection: $selectedDevice.animation(.linear), label: Text("Camera")) {
                ForEach(manager.devices, id: \.self) { device in
                    Text(device.localizedName).tag(device as AVCaptureDevice?)
                }
            }
            .onAppear {
                DevicesManager.shared.startMonitoring()
            }
            .onDisappear {
                DevicesManager.shared.stopMonitoring()
            }
            .padding(.top, 10.0)
            .padding(.bottom, 5.0)
            .padding(.horizontal, 10.0)
            .foregroundColor(/*@START_MENU_TOKEN@*/Color("AccentColor")/*@END_MENU_TOKEN@*/)*/
            cameraPreview(device: $selectedDevice)
        }
        .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color(hue: 1.0, saturation: 0.0, brightness: 0.0)/*@END_MENU_TOKEN@*/)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
