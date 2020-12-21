//
//  ViewController.swift
//  FaceRecognitionDemo
//
//  Created by 谢佳培 on 2020/8/26.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

import UIKit

class CoreImageViewController: UIViewController
{

    @IBOutlet weak var personPic: UIImageView!
    
    override func viewDidLoad()
    {
        self.detect()
    }
    
    // 检测人脸
    func detect()
    {
        // 人像图片
        guard let personciImage = CIImage(image: personPic.image!) else { return }
        // 精确度
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        // 人脸检测
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        // 在人像图片中锁定人脸，可能有多个人
        let faces = faceDetector?.features(in: personciImage)
        
        // 转换坐标系
        let ciImageSize = personciImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        // 针对每张人脸
        for face in faces as! [CIFaceFeature]
        {
            print("人脸区域为：Found bounds are \(face.bounds)")
            
            // 应用变换转换坐标
            var faceViewBounds = face.bounds.applying(transform)
            
            // 在图像视图中计算矩形的实际位置和大小
            let viewSize = personPic.bounds.size
            let scale = min(viewSize.width / ciImageSize.width, viewSize.height / ciImageSize.height)
            let offsetX = (viewSize.width - ciImageSize.width * scale) / 2
            let offsetY = (viewSize.height - ciImageSize.height * scale) / 2
            
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            
            // 人脸边框
            let faceBox = UIView(frame: faceViewBounds)
            faceBox.layer.borderWidth = 3
            faceBox.layer.borderColor = UIColor.red.cgColor
            faceBox.backgroundColor = UIColor.clear
            personPic.addSubview(faceBox)
            
            
            if face.hasLeftEyePosition
            {
                print("左眼位置： \(face.leftEyePosition)")
            }
            
            if face.hasRightEyePosition
            {
                print("右眼位置： \(face.rightEyePosition)")
            }
        }
    }

}







