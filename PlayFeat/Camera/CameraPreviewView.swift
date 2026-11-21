//
//  CameraPreviewView.swift
//  PlayFeat
//
//  Layer 1 (back): the live front-camera feed the player sees themselves in.
//  It shows the game's *existing* CameraSession and its one preview layer
//  rather than making its own: iOS only allows one AVCaptureSession per
//  camera, and one preview layer keeps a screen handover from going blank.
//

import UIKit
import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let camera: CameraSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView(previewLayer: camera.previewLayer)
        camera.previewLayer.videoGravity = camera.previewGravity
        // Rotation is driven by the camera's RotationCoordinator, which needs
        // the layer's new place on screen to compute the preview angle.
        camera.previewDidMove()
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        camera.previewLayer.videoGravity = camera.previewGravity
    }

    /// Hosts the shared preview layer and keeps it the size of the view.
    /// Adding the layer here takes it away from the previous preview, if any.
    final class PreviewView: UIView {
        private let previewLayer: AVCaptureVideoPreviewLayer

        init(previewLayer: AVCaptureVideoPreviewLayer) {
            self.previewLayer = previewLayer
            super.init(frame: .zero)
            layer.addSublayer(previewLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("PreviewView is created in code only")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            // A newer preview may have taken the layer; leave it alone then.
            guard previewLayer.superlayer === layer else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = bounds
            CATransaction.commit()
        }
    }
}
