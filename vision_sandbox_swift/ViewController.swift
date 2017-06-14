//
//  ViewController.swift
//  vision_sandbox_swift
//
//  Created by Cyrus Yeung on 6/7/17.
//  Copyright © 2017 Cyrus Yeung. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate  {

    @IBOutlet weak var Camera_Image_View: UIImageView!
    @IBOutlet weak var Results_Table_View: UITableView!
    let imagePickerController:UIImagePickerController = UIImagePickerController()
    let imagePicker = UIImagePickerController()
    let textDetector = Text_Detector.init(isDisplayBackground: true)
    let faceDetector = Face_Detector.init(isDisplayBackground: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraInit()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    // Cameara
    func cameraInit(){
        imagePickerController.delegate = self
        imagePickerController.modalTransitionStyle = .flipHorizontal
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .camera
        imagePickerController.allowsEditing = true
        imagePickerController.mediaTypes = ["public.image"]
        imagePickerController.cameraCaptureMode = .photo
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.Camera_Image_View.image = info[UIImagePickerControllerEditedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
    }
    
    // Button Event Linstener
    @IBAction func Take_Photo_OnClick(_ sender: Any) {
        self.present(imagePickerController, animated: true) { () -> Void in}
    }
    @IBAction func Clear_Photo_OnClick(_ sender: Any) {
        self.Camera_Image_View.image = nil
    }
    @IBAction func Photo_By_Lib_OnClick(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    @IBAction func Text_Dectection_OnClick(_ sender: Any) {
        if(self.Camera_Image_View.image != nil){
            self.Camera_Image_View.image =  self.textDetector.textDetect(dectect_image: self.Camera_Image_View.image!, display_image_view: self.Camera_Image_View)
        }
    }
    @IBAction func Face_Dectection_OnClick(_ sender: Any) {
        if(self.Camera_Image_View.image != nil){
            self.Camera_Image_View.image =  self.faceDetector.faceDetect(dectect_image:  self.Camera_Image_View.image!, display_image_view:  self.Camera_Image_View)
        }
    }
}

