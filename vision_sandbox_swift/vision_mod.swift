//
//  vision_mod.swift
//  vision_sandbox_swift
//
//  Created by Cyrus Yeung on 6/8/17.
//  Copyright © 2017 Cyrus Yeung. All rights reserved.
//

import UIKit
import Vision

class vision_mod: NSObject {
    
    override init() {
        
    }
    
    func mixImage(top_image:UIImage, bottom_image:UIImage, top_image_point:CGPoint=CGPoint.zero, isHaveBackground:Bool = true)-> UIImage{
        let bottomImage = bottom_image//self.Camera_Image_View.image
        let newSize = bottomImage.size // set this to what you need
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        if(isHaveBackground==true){
            bottomImage.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        }
        top_image.draw(in: CGRect(origin: top_image_point, size: newSize))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        return newImage!
    }
    
}

class Text_Detector: vision_mod {
    
    var havBackground:Bool = true;
    init(isDisplayBackground:Bool) {
        havBackground = isDisplayBackground
    }
    
    func textDetect(dectect_image:UIImage, display_image_view:UIImageView)->UIImage{
        let handler:VNImageRequestHandler = VNImageRequestHandler.init(cgImage: (dectect_image.cgImage)!)
        var result_img:UIImage = UIImage.init();
        
        let request:VNDetectTextRectanglesRequest = VNDetectTextRectanglesRequest.init(completionHandler: { (request, error) in
            if( (error) != nil){
                print("Got Error In Run Text Dectect Request");
                
            }else{
                result_img = self.mixImage(top_image: self.drawRectangleForTextDectect(image: display_image_view.image!,results: request.results as! Array<VNTextObservation>), bottom_image: dectect_image)
            }
        })
        request.reportCharacterBoxes = true
        do {
            try handler.perform([request])
            return result_img;
            print("Successful Run Text Dectect Request");
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
                ctx.cgContext.setLineWidth(2)
                ctx.cgContext.addRect(item.boundingBox.applying(t))
                ctx.cgContext.drawPath(using: .fillStroke)
                
                for item_2 in TextObservation.characterBoxes!{
                    let RectangleObservation:VNRectangleObservation = item_2
                    ctx.cgContext.setFillColor(UIColor.clear.cgColor)
                    ctx.cgContext.setStrokeColor(UIColor.red.cgColor)
                    ctx.cgContext.setLineWidth(2)
                    ctx.cgContext.addRect(RectangleObservation.boundingBox.applying(t))
                    ctx.cgContext.drawPath(using: .fillStroke)
                }
            }
            
        }
        return img
    }
}

class Face_Detector: vision_mod {
    
    var havBackground:Bool = true;
    init(isDisplayBackground:Bool) {
        havBackground = isDisplayBackground
    }
    
    func faceDetect(dectect_image:UIImage, display_image_view:UIImageView)-> UIImage{
        let handler = VNImageRequestHandler.init(cgImage: (dectect_image.cgImage)!)
        var result_img:UIImage = UIImage.init();
        let request = VNDetectFaceRectanglesRequest.init { (request, error) in
            if(error==nil){
                var face_rect:CGRect = CGRect.zero;
                let renderer = UIGraphicsImageRenderer(size: (display_image_view.image?.size)!)
                var t:CGAffineTransform = CGAffineTransform.identity;
                t = t.scaledBy( x: (display_image_view.image?.size.width)!, y: -((display_image_view.image?.size.height)!));
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
                    }
                }
                result_img = self.faceLandmark(face_rect_image:  self.mixImage(top_image: img, bottom_image: display_image_view.image!), face_rect: face_rect, display_image_view: display_image_view)
            }
        }
        do {
            try handler.perform([request])
            return result_img
        } catch {
            return result_img
        }
    }
    
    func faceLandmark(face_rect_image:UIImage, face_rect:CGRect, display_image_view:UIImageView) -> UIImage{
        let handler = VNImageRequestHandler.init(cgImage: (face_rect_image.cgImage)!)
        var result_img:UIImage = UIImage.init();
        let request = VNDetectFaceLandmarksRequest.init { (request, error) in
            if(error==nil){
                let size:CGSize = face_rect_image.size
                let renderer = UIGraphicsImageRenderer(size:size)
                var t:CGAffineTransform = CGAffineTransform.identity;
                t = t.scaledBy( x: face_rect.width, y: -face_rect.height);
                print(face_rect)
                print(face_rect.maxX, face_rect.maxY)
                print(face_rect.midX, face_rect.midY)
                print(face_rect.minX, face_rect.minY)
                t = t.translatedBy(x: 0, y: -1 )
                
                let img = renderer.image { ctx in
                    for item in request.results! {
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
                }
                //display_image_view.image = self.mixImage(top_image: img, bottom_image: face_rect_image, top_image_point: CGPoint.init(x: face_rect.minX, y: face_rect.minY));
                result_img = self.mixImage(top_image: img, bottom_image: face_rect_image, top_image_point: CGPoint.init(x: face_rect.minX, y: face_rect.minY));
            }
        }
        do {
            try handler.perform([request])
            return result_img
        } catch {
            return result_img
        }
    }
}



