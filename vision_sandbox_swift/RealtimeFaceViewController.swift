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

class RealtimeFaceViewController: UIViewController {
    
    //UI
    @IBOutlet weak var CameraOverlayView: UIImageView!
    @IBOutlet weak var btn_switchCamera: UIButton!
    var isBackCamera:Bool = true;
    let faceDetectQueue:DispatchQueue = DispatchQueue.init(label: "face detect queue")
    let captureSession = AVCaptureSession()
    var currentInput:AVCaptureDeviceInput? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCaptureSession()
        self.view.bringSubview(toFront: self.CameraOverlayView)
        view.bringSubview(toFront: self.btn_switchCamera)
    }
    
    @IBAction func btn_switchCamera(_ sender: Any) {
        self.isBackCamera = !self.isBackCamera
        self.captureSession.removeInput(self.currentInput!)
        var Camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
        if isBackCamera==true{
            Camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
        }
        self.currentInput = try! AVCaptureDeviceInput(device: Camera)
        captureSession.addInput(self.currentInput!)
    }
    
    fileprivate func setLayerAsBackground(layer: CALayer) {
        view.layer.addSublayer(layer)
        layer.frame = view.bounds
    }
    
    fileprivate func prepareCaptureSession() {
        //let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        var Camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
        if isBackCamera==true{
            Camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
        }
        //let input = try! AVCaptureDeviceInput(device: Camera)
        self.currentInput = try! AVCaptureDeviceInput(device: Camera)
        captureSession.addInput(self.currentInput!)
        
        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        setLayerAsBackground(layer: cameraPreviewLayer)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate"))
        videoOutput.recommendedVideoSettings(forVideoCodecType: .jpeg, assetWriterOutputFileType: .mp4)
        
        captureSession.addOutput(videoOutput)
        captureSession.sessionPreset = .high
        captureSession.startRunning()
    }
    
    // Face Detect
    func faceDetect(dectect_image:UIImage, display_image_view:UIImageView)-> UIImage{
        let handler = VNImageRequestHandler.init(cgImage: (dectect_image.cgImage)!)
        var result_img:UIImage = UIImage.init();
        let face_rects_array:NSMutableArray = NSMutableArray.init();
        var face_rect:CGRect = CGRect.zero;
        let image_size:CGSize = dectect_image.size
        
        let request = VNDetectFaceRectanglesRequest.init { (request, error) in
            if(error==nil){
                let renderer = UIGraphicsImageRenderer(size: (image_size))
                var t:CGAffineTransform = CGAffineTransform.identity;
                t = t.scaledBy( x: (image_size.width), y: -(image_size.height));
                t = t.translatedBy(x: 0, y: -1 );
                let img = renderer.image { ctx in
                    for item in request.results! {
                        let FaceObservation:VNFaceObservation = item as! VNFaceObservation
                        ctx.cgContext.setFillColor(UIColor.clear.cgColor)
                        ctx.cgContext.setStrokeColor(UIColor.green.cgColor)
                        ctx.cgContext.setLineWidth(2)
                        ctx.cgContext.addRect(FaceObservation.boundingBox.applying(t))
                        ctx.cgContext.drawPath(using: .fillStroke)
                        face_rect = FaceObservation.boundingBox.applying(t)
                        face_rects_array.add(face_rect)
                    }
                }
                result_img = img
            }
        }
        
        let landmark_request = VNDetectFaceLandmarksRequest.init { (request, error) in
            if(error==nil){
                let size:CGSize = result_img.size
                let renderer = UIGraphicsImageRenderer(size:size)
                var t:CGAffineTransform = CGAffineTransform.identity;
                t = t.scaledBy( x: face_rect.width, y: -face_rect.height);
                /*print(face_rect)
                print(face_rect.maxX, face_rect.maxY)
                print(face_rect.midX, face_rect.midY)
                print(face_rect.minX, face_rect.minY)*/
                t = t.translatedBy(x: 0, y: -1 )
                for (index, item) in request.results!.enumerated() {
                    let img = renderer.image { ctx in
                        let FaceObservation:VNFaceObservation = item as! VNFaceObservation
                        let allpoints = FaceObservation.landmarks?.allPoints
                        if let allpoints = allpoints{
                            for i in 0 ..< allpoints.pointCount{
                                let point = allpoints.point(at: i)
                                let cgrect =  CGRect.init(x: CGFloat(point.x), y: CGFloat(point.y), width: CGFloat(0.01), height: CGFloat(0.01))
                                let c:UIBezierPath = UIBezierPath.init(cgPath: CGPath.init(rect: cgrect, transform:&t ))
                                c.close()
                                ctx.cgContext.setFillColor(UIColor.red.cgColor)
                                ctx.cgContext.setStrokeColor(UIColor.red.cgColor)
                                ctx.cgContext.addPath(c.cgPath)
                                ctx.cgContext.drawPath(using: .fillStroke)
                            }
                        }
                    }
                    let face_rect_temp = face_rects_array[index] as! CGRect
                    result_img = self.mixImage(top_image: img, bottom_image: result_img, top_image_point: CGPoint.init(x: face_rect_temp.minX, y: face_rect_temp.minY));
                }
            }
        }
        
        
        do {
            try handler.perform([request])
            try handler.perform([landmark_request])
            return result_img
        } catch {
            return result_img
        }
    }
    
    
    func mixImage(top_image:UIImage, bottom_image:UIImage, top_image_point:CGPoint=CGPoint.zero)-> UIImage{
        let bottomImage = bottom_image//self.Camera_Image_View.image
        let newSize = bottomImage.size // set this to what you need
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        bottomImage.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        top_image.draw(in: CGRect(origin: top_image_point, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        return newImage!
    }
    
}

extension RealtimeFaceViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { fatalError("pixel buffer is nil") }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { fatalError("cg image") }
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .leftMirrored)
        var overlay_img:UIImage = UIImage.init()
        self.faceDetectQueue.sync {
            overlay_img = self.faceDetect(dectect_image: uiImage, display_image_view: self.CameraOverlayView)
        }
        DispatchQueue.main.sync {
            self.CameraOverlayView.image = overlay_img
        }
    }
}


