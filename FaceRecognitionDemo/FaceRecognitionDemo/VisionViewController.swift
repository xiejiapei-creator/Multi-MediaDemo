//
//  VisionViewController.swift
//  FaceRecognitionDemo
//  
//  Created by 谢佳培 on 2020/8/27.
//  Copyright © 2020 xiejiapei. All rights reserved.
//

import UIKit
import Vision

class VisionViewController: UIViewController
{
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad()
    {
        // 检测人脸
        self.detect()
    }
    
    // 检测人脸
    func detect()
    {
        let handler = VNImageRequestHandler.init(cgImage: (imageView.image?.cgImage!)!, orientation: CGImagePropertyOrientation.up)
        
        // 创建检测人脸边框的请求
        let request = detectRequest()
        
        DispatchQueue.global(qos: .userInteractive).async {
            do
            {
                try handler.perform([request])
            }
            catch
            {
                print("出错了")
            }
        }
    }
    
    // 创建检测人脸边框的请求
    func detectRequest() -> VNDetectFaceRectanglesRequest
    {
        let request = VNDetectFaceRectanglesRequest { (request, error) in
            
            DispatchQueue.main.async {
                if let result = request.results
                {
                    // 旋转变换
                    let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.imageView!.frame.size.height)
                    
                    // 平移变换
                    let translate = CGAffineTransform.identity.scaledBy(x: self.imageView!.frame.size.width, y: self.imageView!.frame.size.height)
                    
                    //遍历所有识别结果
                    for item in result
                    {
                        // 创建人脸边框
                        let faceRect = UIView(frame: CGRect.zero)
                        faceRect.layer.borderWidth = 3
                        faceRect.layer.borderColor = UIColor.red.cgColor
                        faceRect.backgroundColor = UIColor.clear
                        self.imageView!.addSubview(faceRect)
                        
                        // 调整人脸边框位置
                        if let faceObservation = item as? VNFaceObservation
                        {
                            // 移动和选择的将仿射变化运用到边框上
                            let finalRect = faceObservation.boundingBox.applying(translate).applying(transform)
                            
                            // 人脸边框的最终位置
                            faceRect.frame = finalRect
                        }
                    }
                }
            }
        }
        return request
    }
}
