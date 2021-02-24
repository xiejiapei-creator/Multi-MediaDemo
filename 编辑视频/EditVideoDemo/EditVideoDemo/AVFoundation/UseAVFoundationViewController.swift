//
//  UseAVFoundationViewController.swift
//  EditVideoDemo
//
//  Created by 谢佳培 on 2021/2/23.
//

import UIKit
import AVKit
import AVFoundation

class UseAVFoundationViewController: UIViewController
{

    var imageView: UIImageView! = UIImageView(frame: CGRect(x: 100, y: 100, width: 200, height: 200))
    var playVideoButton: UIButton! = UIButton(frame: CGRect(x: 150, y: 320, width: 100, height: 50))
    var playSoundButton: UIButton! = UIButton(frame: CGRect(x: 150, y: 420, width: 100, height: 50))
    var loadAssetButton: UIButton! = UIButton(frame: CGRect(x: 150, y: 520, width: 100, height: 50))
    
    var audioPlayer:AVAudioPlayer?
    
    let ibaotuVideoUrl: URL = URL(string: "https://video-qn.ibaotu.com/00/98/99/98z888piCTeW.mp4")!
    let wwdcVideoUrl: URL = URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2019/244gmopitz5ezs2kkq/244/hls_vod_mvp.m3u8")!
    let soundFileUrl = Bundle.main.url(forResource: "sound.mp3", withExtension: nil)!
    let bossSoundFileUrl = Bundle.main.url(forResource: "bossSound.mp3", withExtension: nil)!
    let videoFileUrl = Bundle.main.url(forResource: "Logic.mp4", withExtension: nil)!

    override func viewDidLoad()
    {
        super.viewDidLoad()

        imageView.image = UIImage(named: "luckcoffee")
        createSubview()
        
        self.audioPlayer = try! AVAudioPlayer.init(contentsOf: soundFileUrl)
        self.audioPlayer?.prepareToPlay()
    }
    
    func createSubview()
    {
        playVideoButton.setTitle("播放视频", for: .normal)
        playSoundButton.setTitle("播放音频", for: .normal)
        loadAssetButton.setTitle("加载资源", for: .normal)
        
        playVideoButton.backgroundColor = .black
        playSoundButton.backgroundColor = .black
        loadAssetButton.backgroundColor = .black
        
        playVideoButton.addTarget(self, action: #selector(didClickPlayButton), for: .touchUpInside)
        playSoundButton.addTarget(self, action: #selector(didClickPlayAudioButton), for: .touchUpInside)
        loadAssetButton.addTarget(self, action: #selector(didClickAssetLoad), for: .touchUpInside)
        
        view.addSubview(imageView)
        view.addSubview(playVideoButton)
        view.addSubview(playSoundButton)
        view.addSubview(loadAssetButton)
    }
    
    // 点击播放视频
    @objc func didClickPlayButton()
    {
        let player = AVPlayer(url: ibaotuVideoUrl);
        
        let controller = AVPlayerViewController();
        controller.player = player;
        present(controller, animated: true)
        {
            player.play();
        }
    }
    
    // 点击播放音频
    @objc func didClickPlayAudioButton()
    {
        if self.audioPlayer?.isPlaying == false
        {
            self.audioPlayer?.play()
        }
        else
        {
            print("正在播放，准备暂停");
            self.audioPlayer?.pause()
        }
    }
    
    // 加载音视频资源
    @objc func didClickAssetLoad()
    {
        // 设置移动蜂窝网络下不会读取资源，只有在WiFi网络下才会加载资源
        let options = [AVURLAssetAllowsCellularAccessKey: false]
        //let asset = AVAsset(url: bossSoundFileUrl)
        let asset = AVURLAsset(url: bossSoundFileUrl, options: options)
        
        // 异步加载资源
        let playableKey = "metadata"
        asset.loadValuesAsynchronously(forKeys: [playableKey])
        {
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: playableKey, error: &error)
            switch status
            {
            case .loading:
                print("正在加载资源...")
            case .loaded:
                print("加载资源成功... \(asset.metadata)")
                
                for format in asset.availableMetadataFormats
                {
                    // 获取到元数据以后，需要读取元数据的值
                    let metadata = asset.metadata(forFormat: format)
                    
                    // 标题ID
                    let titleID = AVMetadataIdentifier.commonIdentifierTitle
                    
                    // 获取标题
                    let titleItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: titleID)
                    
                    if let item = titleItems.first
                    {
                        print("标题：\n",item.commonKey!,item.identifier!,item.stringValue!)
                    }
                    
                    // 封面
                    let artworkItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: AVMetadataIdentifier.commonIdentifierArtwork)
                    
                    DispatchQueue.main.async
                    {
                        if let artworkItem = artworkItems.first
                        {
                            if let imageData = artworkItem.dataValue
                            {
                                let image = UIImage(data: imageData)
                                self.imageView.image = image
                            }
                            else
                            {
                                print("哈哈")
                            }
                        }
                    }
                }
            case .failed:
                print("加载资源失败...")
            case .cancelled:
                print("取消加载资源...")
            default: break
            }
        }
    }
}


 


