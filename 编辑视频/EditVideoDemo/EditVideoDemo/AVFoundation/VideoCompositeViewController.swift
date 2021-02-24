//
//  VideoCompositeViewController.swift
//  EditVideoDemo
//
//  Created by 谢佳培 on 2021/2/23.
//

import UIKit
import AVKit
import AVFoundation

class VideoCompositeViewController: UIViewController
{
    var videoCompositionButton: UIButton! = UIButton(frame: CGRect(x: 50, y: 100, width: 100, height: 50))
    var playVideoButton: UIButton! = UIButton(frame: CGRect(x: 200, y: 100, width: 120, height: 50))
    var videoBackView: UIView! = UIView(frame: CGRect(x: 100, y: 200, width: 200, height: 200))
    
    let logicVideoFileUrl = Bundle.main.url(forResource: "Logic.mp4", withExtension: nil)!
    let girlVideoFileUrl = Bundle.main.url(forResource: "Girl.mp4", withExtension: nil)!
    
    var playerItem: AVPlayerItem?
    var player: AVPlayer?
    var playerlayer: AVPlayerLayer?
    var composition: AVMutableComposition?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        crateSubview()
    }
    
    func crateSubview()
    {
        videoCompositionButton.setTitle("合成视频", for: .normal)
        videoCompositionButton.backgroundColor = .black
        videoCompositionButton.addTarget(self, action: #selector(didClickVideoCompositeButton), for: .touchUpInside)
        view.addSubview(videoCompositionButton)
        
        playVideoButton.setTitle("播放合成视频", for: .normal)
        playVideoButton.backgroundColor = .black
        playVideoButton.addTarget(self, action: #selector(didClickPlayVideoButton), for: .touchUpInside)
        view.addSubview(playVideoButton)
        
        videoBackView.backgroundColor = .gray
        view.addSubview(videoBackView)
    }
    
    // MARK: 点击按钮
    
    // 播放视频
    @objc func didClickPlayVideoButton()
    {
        guard (composition != nil) else { return }

        playerItem = AVPlayerItem.init(asset: composition!)
        player = AVPlayer.init(playerItem: playerItem)
        
        playerlayer = AVPlayerLayer.init(player: player!)
        playerlayer?.frame = videoBackView.bounds
        videoBackView.layer.addSublayer(playerlayer!)
        
        player?.play()
    }
    
    // 合成视频
    @objc func didClickVideoCompositeButton()
    {
        composition = createVideoComposition()
        outputVideo(composition!)
    }
    
    // MARK: 合成视频
    
    fileprivate func createVideoComposition() -> AVMutableComposition
    {
        let logicAsset: AVAsset = AVAsset(url: logicVideoFileUrl)
        let girlAsset: AVAsset = AVAsset(url: girlVideoFileUrl)
        
        // 用于从AVAsset创建新组合的可变对象
        let composition = AVMutableComposition(urlAssetInitializationOptions: nil)
        
        // 创建一个视频轨道
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // 创建一个音频轨道
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      
        // 第一个视频的时长：0 ~ 3秒
        let logicCursorTime = CMTime.zero
        let logicDuration = logicAsset.duration
        let logicVideoTimeRange = CMTimeRangeMake(start: logicCursorTime, duration: logicDuration)
        
        // 第二个视频的时长：3 ~ 10秒
        let girlCursorTime = CMTimeAdd(logicCursorTime, logicAsset.duration)
        let girlDuration = girlAsset.duration
        let girlVideoTimeRange = CMTimeRangeMake(start: girlCursorTime, duration: girlDuration)

        // 在视频轨道中将视频插入到对应的时间范围
        let logicAssetTrack = logicAsset.tracks(withMediaType: .video).first!
        try! videoTrack?.insertTimeRange(logicVideoTimeRange, of: logicAssetTrack, at: logicCursorTime)
        
        // 提供表示指定媒体类型的媒体的资产的AVAssetTracks数组(第一个)
        let girlAssetTrack = girlAsset.tracks(withMediaType: .video).first!
        try! videoTrack?.insertTimeRange(girlVideoTimeRange, of: girlAssetTrack, at: girlCursorTime)
        
        // 在音频轨道中将音频插入到对应的时间范围
        let logicAudioAssetTrack = logicAsset.tracks(withMediaType: .audio).first!
        try! audioTrack?.insertTimeRange(logicVideoTimeRange, of: logicAudioAssetTrack, at: logicCursorTime)

        let girlAudioAssetTrack = girlAsset.tracks(withMediaType: .audio).first!
        try! audioTrack?.insertTimeRange(girlVideoTimeRange, of: girlAudioAssetTrack, at: girlCursorTime)
        
        print("合成完毕")
    
        return composition
    }
    
    // MARK: 输出视频
    
    fileprivate func outputVideo(_ composition: AVMutableComposition)
    {
        // 视频输出路径
        let cache = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last
        let dateString = getCurrentTime()
        let filePath = cache! + "/\(dateString).mp4"
        print("视频输出路径为：\(filePath)")
        
        // 视频输出格式
        let exporterSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporterSession?.outputFileType = AVFileType.mp4
        exporterSession?.outputURL = NSURL(fileURLWithPath: filePath) as URL
        exporterSession?.shouldOptimizeForNetworkUse = true
        exporterSession?.exportAsynchronously(completionHandler: { () -> Void in
            switch exporterSession!.status
            {
            case .unknown:
                print("unknow")
            case .cancelled:
                print("cancelled")
            case .failed:
                print("failed")
            case .waiting:
                print("waiting")
            case .exporting:
                print("exporting")
            case .completed:
                print("completed")
            @unknown default:
                print("0000000")
            }
        })
    }
    
    // 获取当前时间
    fileprivate func getCurrentTime() -> String
    {
        let date = NSDate.init(timeIntervalSinceNow: 0)
        let timeInterval = date.timeIntervalSince1970;
        let timeIntervalInt = Int(timeInterval)
        let timeIntervalString = "\(timeIntervalInt)"
        return timeIntervalString
    }
}
