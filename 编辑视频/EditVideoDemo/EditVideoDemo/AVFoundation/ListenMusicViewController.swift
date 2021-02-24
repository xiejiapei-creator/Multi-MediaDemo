//
//  ListenMusicViewController.swift
//  EditVideoDemo
//
//  Created by 谢佳培 on 2021/2/23.
//

import UIKit
import AVKit
import MediaPlayer

class ListenMusicViewController: UIViewController
{
    let fileUrl = Bundle.main.url(forResource: "bossSound.mp3", withExtension: nil)
    var playerItem:AVPlayerItem?
    var player:AVPlayer?
    
    var pregressSlider: UISlider! = UISlider(frame: CGRect(x: 100, y: 100, width: 200, height: 100))
    var playerButton: UIButton! = UIButton(frame: CGRect(x: 150, y: 320, width: 100, height: 50))
    var timeLabel: UILabel! = UILabel(frame: CGRect(x: 170, y: 220, width: 50, height: 50))

    override func viewDidLoad()
    {
        super.viewDidLoad()

        createSubview()
        setupPlayer()
    }
    
    // MARK: 设置界面和初始化播放器
    
    func createSubview()
    {
        playerButton.setTitle("播放", for: .normal)
        playerButton.backgroundColor = .black
        playerButton.addTarget(self, action: #selector(didClickPlayButton), for: .touchUpInside)
        
        self.pregressSlider.addTarget(self, action: #selector(playbackSliderValueChanged), for: .valueChanged)
        
        view.addSubview(pregressSlider)
        view.addSubview(playerButton)
        view.addSubview(timeLabel)
    }
    
    fileprivate func setupPlayer()
    {
        // 初始化播放器
        playerItem = AVPlayerItem(url: fileUrl!)
        player = AVPlayer(playerItem: playerItem!)
        
        // 设置进度条相关属性
        let duration: CMTime = playerItem!.asset.duration
        let seconds: Float64 = CMTimeGetSeconds(duration)
        pregressSlider!.minimumValue = 0
        pregressSlider!.maximumValue = Float(seconds)
        pregressSlider!.isContinuous = false
        
        // 播放过程中动态改变进度条值和时间标签
        player!.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main)
        { (CMTime) -> Void in
            if self.player!.currentItem?.status == .readyToPlay && self.player?.rate != 0
            {
                // 更新进度条进度值
                let currentTime = CMTimeGetSeconds(self.player!.currentTime())
                self.pregressSlider!.value = Float(currentTime)
                
                // 一个小算法：用来实现00：00这种格式的播放时间
                let all:Int = Int(currentTime)
                let m:Int = all % 60
                let f:Int = Int(all/60)
                
                var time: String = ""
                if f < 10
                {
                    time = "0\(f):"
                }
                else
                {
                    time = "\(f)"
                }
                
                if m < 10
                {
                    time += "0\(m)"
                }
                else
                {
                    time += "\(m)"
                }
                // 更新播放时间
                self.timeLabel!.text=time
                
                // 设置后台播放显示信息为正在播放
                self.setInfoCenterCredentials(playbackState: 1)
            }
        }
    }
    
    // MARK: 控制播放
    
    @objc func didClickPlayButton()
    {
        // 根据rate属性判断当前是否在播放
        if player?.rate == 0
        {
            player!.play()
            playerButton.setTitle("暂停", for: .normal)
        }
        else
        {
            player!.pause()
            playerButton.setTitle("播放", for: .normal)
            
            // 设置后台播放显示信息为停止
            setInfoCenterCredentials(playbackState: 0)
        }
    }
    
    // 用户通过拖动进度条控制播放器进度
    @objc func playbackSliderValueChanged()
    {
        let seconds: Int64 = Int64(pregressSlider.value)
        let targetTime: CMTime = CMTimeMake(value: seconds, timescale: 1)
        
        // 播放器定位到对应的位置
        player!.seek(to: targetTime)
        
        // 如果当前时暂停状态，则自动播放
        if player!.rate == 0
        {
            player?.play()
            playerButton.setTitle("暂停", for: .normal)
        }
    }

    // MARK: 播放完成
    
    // 页面显示时添加相关通知监听
    override func viewWillAppear(_ animated: Bool)
    {
        // 播放完毕
        NotificationCenter.default.addObserver(self, selector: #selector(finishedPlaying),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        // 告诉系统接受远程响应事件，并注册成为第一响应者
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()
    }
    
    // 页面消失时取消歌曲播放结束通知监听
    override func viewWillDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self)
        
        // 停止接受远程响应事件
        UIApplication.shared.endReceivingRemoteControlEvents()
        self.resignFirstResponder()
    }
    
    // 是否能成为第一响应对象
    override var canBecomeFirstResponder: Bool
    {
        return true
    }
    
    // 歌曲播放完毕
    @objc func finishedPlaying(myNotification:NSNotification)
    {
        print("播放完毕!")
        
        let stopedPlayerItem: AVPlayerItem = myNotification.object as! AVPlayerItem
        stopedPlayerItem.seek(to: CMTime.zero)
        { (status) in
            print("当前的音频文件是否播放完毕：\(status)")
        }
    }
    
    // MARK: 耳机操作
    
    // 设置后台播放显示信息
    func setInfoCenterCredentials(playbackState: Int)
    {
        let mpic = MPNowPlayingInfoCenter.default()
        
        // 专辑封面
        let mySize = CGSize(width: 400, height: 400)
        let albumArt = MPMediaItemArtwork(boundsSize:mySize)
        { sz in
            return UIImage(named: "luckcoffee")!
        }
        
        // 获取进度
        let postion = Double(pregressSlider!.value)
        let duration = Double(pregressSlider!.maximumValue)
        
        mpic.nowPlayingInfo = [MPMediaItemPropertyTitle: "播放音频",
                               MPMediaItemPropertyArtist: "谢佳培",
                               MPMediaItemPropertyArtwork: albumArt,
                               MPNowPlayingInfoPropertyElapsedPlaybackTime: postion,
                               MPMediaItemPropertyPlaybackDuration: duration,
                               MPNowPlayingInfoPropertyPlaybackRate: playbackState]
    }
    
    // 耳机控制
    override func remoteControlReceived(with event: UIEvent?)
    {
        guard let event = event else
        {
            print("没有远程控制事件\n")
            return
        }
        
        if event.type == UIEvent.EventType.remoteControl
        {
            switch event.subtype
            {
            case .remoteControlTogglePlayPause:
                print("暂停/播放")
            case .remoteControlPreviousTrack:
                print("上一首")
            case .remoteControlNextTrack:
                print("下一首")
            case .remoteControlPlay:
                print("播放")
                player!.play()
            case .remoteControlPause:
                print("暂停")
                player!.pause()
                // 后台播放显示信息进度停止
                setInfoCenterCredentials(playbackState: 0)
            default:
                break
            }
        }
    }
}


 


 
