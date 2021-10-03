//
//  CameraPreview.swift
//  Cappie
//
//  Created by Jay on 10/3/21.
//

import SwiftUI
import AVFoundation

struct CameraPreview: NSViewRepresentable {
    @Binding var captureDevice: AVCaptureDevice?

    func makeNSView(context: Context) -> CameraPreviewInternal {
        return CameraPreviewInternal(frame: .zero, device: captureDevice)
    }

    func updateNSView(_ nsView: CameraPreviewInternal, context: NSViewRepresentableContext<CameraPreview>) {
        nsView.updateCamera(captureDevice)
    }

    static func dismantleNSView(_ nsView: CameraPreviewInternal, coordinator: ()) {
        nsView.stopRunning()
    }
}
