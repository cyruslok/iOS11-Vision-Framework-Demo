//
//  RealtimeViewController.swift
//  vision_sandbox_swift
//
//  Created by Cyrus Yeung on 6/8/17.
//  Copyright © 2017 Cyrus Yeung. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class RealtimeViewController: UIViewController {
    
    //UI
    @IBOutlet weak var CameraOverlayView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCaptureSession()
        self.view.bringSubview(toFront: self.CameraOverlayView)
    }
    
    fileprivate func setLayerAsBackground(layer: CALayer) {
        view.layer.addSublayer(layer)
        layer.frame = view.bounds
    }
    
    fileprivate func prepareCaptureSession() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
        let input = try! AVCaptureDeviceInput(device: backCamera)
        
        captureSession.addInput(input)
        
        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        setLayerAsBackground(layer: cameraPreviewLayer)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate"))
        videoOutput.recommendedVideoSettings(forVideoCodecType: .jpeg, assetWriterOutputFileType: .mp4)
        
        captureSession.addOutput(videoOutput)
        captureSession.sessionPreset = .high
        captureSession.startRunning()
    }
    
}

extension RealtimeViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { fatalError("pixel buffer is nil") }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { fatalError("cg image") }
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .leftMirrored)
        let overlay_image:UIImage = self.textDetect(dectect_image: uiImage, display_image_view: self.CameraOverlayView)
        DispatchQueue.main.sync {
            self.CameraOverlayView.image = overlay_image//self.textDetect(dectect_image: uiImage, display_image_view: self.CameraOverlayView)
        }
    }
    
// Text Detect
    func textDetect(dectect_image:UIImage, display_image_view:UIImageView)->UIImage{
        let handler:VNImageRequestHandler = VNImageRequestHandler.init(cgImage: (dectect_image.cgImage)!)
        var result_img:UIImage = UIImage.init();
        
        let request:VNDetectTextRectanglesRequest = VNDetectTextRectanglesRequest.init(completionHandler: { (request, error) in
            if( (error) != nil){
                print("Got Error In Run Text Dectect Request");
                
            }else{
                result_img = self.drawRectangleForTextDectect(image: dectect_image,results: request.results as! Array<VNTextObservation>)
            }
        })
        request.reportCharacterBoxes = true
        do {
            try handler.perform([request])
            return result_img;
        } catch {
            return result_img;
        }
    }
    
    func drawRectangleForTextDectect(image: UIImage, results:Array<VNTextObservation>) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        var t:CGAffineTransform = CGAffineTransform.identity;
        t = t.scaledBy( x: image.size.width, y: -image.size.height);
        t = t.translatedBy(x: 0, y: -1 );
        
        let img = renderer.image { ctx in
            for item in results {
                let TextObservation:VNTextObservation = item
                ctx.cgContext.setFillColor(UIColor.clear.cgColor)
                ctx.cgContext.setStrokeColor(UIColor.green.cgColor)
                ctx.cgContext.setLineWidth(1)
                ctx.cgContext.addRect(item.boundingBox.applying(t))
                ctx.cgContext.drawPath(using: .fillStroke)
                
                for item_2 in TextObservation.characterBoxes!{
                    let RectangleObservation:VNRectangleObservation = item_2
                    ctx.cgContext.setFillColor(UIColor.clear.cgColor)
                    ctx.cgContext.setStrokeColor(UIColor.red.cgColor)
                    ctx.cgContext.setLineWidth(1)
                    ctx.cgContext.addRect(RectangleObservation.boundingBox.applying(t))
                    ctx.cgContext.drawPath(using: .fillStroke)
                }
            }
            
        }
        return img
    }
    
    
    
}

