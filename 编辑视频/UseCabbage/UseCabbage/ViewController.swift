//
//  ViewController.swift
//  UseCabbage
//
//  Created by 谢佳培 on 2021/2/24.
//

import UIKit
import AVFoundation
import AVKit
import VFCabbage

class ViewController: UIViewController
{
    let titles = ["Simple Demo","Overlay Demo","Transition Demo","Keyframe Demo","Four square Demo","Reverse video Demo","Two video Demo"]

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        createSubview()
    }
    
    func createSubview()
    {
        let table:UITableView = UITableView(frame:view.bounds, style: .plain)
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cellID")
        view.addSubview(table)
    }
    
    // MARK: 仅仅播放视频
    
    @objc func simplePlayerItem() -> AVPlayerItem?
    {
        let girlTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "child", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let timeline = Timeline()
        timeline.videoChannel = [girlTrackItem]
        timeline.audioChannel = [girlTrackItem]
        timeline.renderSize = CGSize(width: 1920, height: 1080)
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    // MARK: 在视频上添加图片
    
    func overlayPlayerItem() -> AVPlayerItem?
    {
        // 创建TrackItem
        let girlTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "girl", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        // 创建Timeline
        let timeline = Timeline()
        timeline.videoChannel = [girlTrackItem]
        timeline.audioChannel = [girlTrackItem]
        timeline.renderSize = CGSize(width: 1920, height: 1080)
        
        timeline.passingThroughVideoCompositionProvider = {
            
            // 创建ImageCompositionGroupProvider
            let imageCompositionGroupProvider = ImageCompositionGroupProvider()
            
            let url = Bundle.main.url(forResource: "overlay", withExtension: "jpg")!
            let image = CIImage(contentsOf: url)!
            let resource = ImageResource(image: image, duration: CMTime.init(seconds: 3, preferredTimescale: 600))
            
            let imageCompositionProvider = ImageOverlayItem(resource: resource)
            imageCompositionProvider.startTime = CMTime(seconds: 1, preferredTimescale: 600)
            let frame = CGRect.init(x: 100, y: 500, width: 400, height: 400)
            imageCompositionProvider.videoConfiguration.contentMode = .custom
            imageCompositionProvider.videoConfiguration.frame = frame;
            imageCompositionProvider.videoConfiguration.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi / 4)
            
            // 创建keyframeConfiguration
            let keyframeConfiguration: KeyframeVideoConfiguration<OpacityKeyframeValue> = {
                let configuration = KeyframeVideoConfiguration<OpacityKeyframeValue>()
                
                let timeValues: [(Double, CGFloat)] = [(0.0, 0), (0.5, 1.0), (2.5, 1.0), (3.0, 0.0)]
                timeValues.forEach({ (time, value) in
                    let opacityKeyframeValue = OpacityKeyframeValue()
                    opacityKeyframeValue.opacity = value
                    let keyframe = KeyframeVideoConfiguration.Keyframe(time: CMTime(seconds: time, preferredTimescale: 600), value: opacityKeyframeValue)
                    configuration.insert(keyframe)
                })
                
                return configuration
            }()
            imageCompositionProvider.videoConfiguration.configurations.append(keyframeConfiguration)

            // 创建transformKeyframeConfiguration
            let transformKeyframeConfiguration: KeyframeVideoConfiguration<TransformKeyframeValue> = {
                let configuration = KeyframeVideoConfiguration<TransformKeyframeValue>()

                let timeValues: [(Double, (CGFloat, CGFloat, CGPoint))] =
                    [(0.0, (1.0, 0, CGPoint.zero)),
                     (1.0, (1.0, CGFloat.pi, CGPoint(x: 100, y: 80))),
                     (2.0, (1.0, CGFloat.pi * 2, CGPoint(x: 300, y: 240))),
                     (3.0, (1.0, 0, CGPoint.zero))]
                timeValues.forEach({ (time, value) in
                    let opacityKeyframeValue = TransformKeyframeValue()
                    opacityKeyframeValue.scale = value.0
                    opacityKeyframeValue.rotation = value.1
                    opacityKeyframeValue.translation = value.2
                    let keyframe = KeyframeVideoConfiguration.Keyframe(time: CMTime(seconds: time, preferredTimescale: 600), value: opacityKeyframeValue)
                    configuration.insert(keyframe)
                })

                return configuration
            }()
            imageCompositionProvider.videoConfiguration.configurations.append(transformKeyframeConfiguration)
            
            imageCompositionGroupProvider.imageCompositionProviders = [imageCompositionProvider]
            return imageCompositionGroupProvider
        }()
        
        // 创建CompositionGenerator
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    // MARK: 实现视频转场效果
    
    func transitionPlayerItem() -> AVPlayerItem?
    {
        // 创建girlTrackItem
        let girlTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "girl", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        // 创建overlayTrackItem
        let overlayTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "overlay", withExtension: "jpg")!
            let image = CIImage(contentsOf: url)!
            let resource = ImageResource(image: image, duration: CMTime.init(seconds: 5, preferredTimescale: 600))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        // 创建childTrackItem
        let childTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "child", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let transitionDuration = CMTime(seconds: 2, preferredTimescale: 600)
        girlTrackItem.videoTransition = PushTransition(duration: transitionDuration)
        girlTrackItem.audioTransition = FadeInOutAudioTransition(duration: transitionDuration)
        
        overlayTrackItem.videoTransition = BoundingUpTransition(duration: transitionDuration)
        
        let timeline = Timeline()
        timeline.videoChannel = [girlTrackItem, overlayTrackItem, childTrackItem]
        timeline.audioChannel = [girlTrackItem, childTrackItem]
        
        do
        {
            try Timeline.reloadVideoStartTime(providers: timeline.videoChannel)
        }
        catch
        {
            assert(false, error.localizedDescription)
        }
        timeline.renderSize = CGSize(width: 1920, height: 1080)
        
        // 创建CompositionGenerator
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    // MARK: 将视频进行缩放
    
    func keyframePlayerItem() -> AVPlayerItem?
    {
        // 创建TrackItem
        let girlTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "girl", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            
            // 创建KeyframeVideoConfiguration
            let transformKeyframeConfiguration: KeyframeVideoConfiguration<TransformKeyframeValue> = {
                let configuration = KeyframeVideoConfiguration<TransformKeyframeValue>()
                
                let timeValues: [(Double, (CGFloat, CGFloat, CGPoint))] =
                    [(0.0, (1.0, 0, CGPoint.zero)),
                     (1.0, (1.2, CGFloat.pi / 20, CGPoint(x: 100, y: 80))),
                     (2.0, (1.5, CGFloat.pi / 15, CGPoint(x: 300, y: 240))),
                     (3.0, (1.0, 0, CGPoint.zero))]
                timeValues.forEach({ (time, value) in
                    let opacityKeyframeValue = TransformKeyframeValue()
                    opacityKeyframeValue.scale = value.0
                    opacityKeyframeValue.rotation = value.1
                    opacityKeyframeValue.translation = value.2
                    let keyframe = KeyframeVideoConfiguration.Keyframe(time: CMTime(seconds: time, preferredTimescale: 600), value: opacityKeyframeValue)
                    configuration.insert(keyframe)
                })
                
                return configuration
            }()
            trackItem.videoConfiguration.configurations.append(transformKeyframeConfiguration)
            
            return trackItem
        }()
        
        // 创建Timeline
        let timeline = Timeline()
        timeline.videoChannel = [girlTrackItem]
        timeline.audioChannel = [girlTrackItem]
        timeline.renderSize = CGSize(width: 1920, height: 1080)
        
        // 创建CompositionGenerator
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    // MARK: 四个视频同屏顺序播放
    
    func fourSquareVideo() -> AVPlayerItem?
    {
        // 创建TrackItem
        let girlTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "girl", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let childTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "child", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        
        let mydogTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "mydog", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let pandaTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "panda", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let trackItems = [girlTrackItem, childTrackItem, mydogTrackItem, pandaTrackItem]
        
        // 创建Timeline
        let timeline = Timeline()
        timeline.videoChannel = trackItems
        timeline.audioChannel = trackItems
        
        try! Timeline.reloadVideoStartTime(providers: timeline.videoChannel)
        
        let renderSize = CGSize(width: 1920, height: 1080)
        
        // Timeline 的 overlays
        timeline.overlays = {
            let foursquareRenderSize = CGSize(width: renderSize.width / 2, height: renderSize.height / 2)
            var overlays: [VideoProvider] = []
            
            let fullTimeRange: CMTimeRange = {
                var duration = CMTime.zero
                trackItems.forEach({ duration = $0.duration + duration })
                return CMTimeRange.init(start: CMTime.zero, duration: duration)
            }()
            
            // 更新 main item's frame
            func frameWithIndex(_ index: Int) -> CGRect
            {
                switch index
                {
                case 0:
                    return CGRect(origin: CGPoint.zero, size: foursquareRenderSize)
                case 1:
                    return CGRect(origin: CGPoint(x: foursquareRenderSize.width, y: 0), size: foursquareRenderSize)
                case 2:
                    return CGRect(origin: CGPoint(x: 0, y:  foursquareRenderSize.height), size: foursquareRenderSize)
                case 3:
                    return CGRect(origin: CGPoint(x: foursquareRenderSize.width, y: foursquareRenderSize.height), size: foursquareRenderSize)
                default:
                    break
                }
                return CGRect(origin: CGPoint.zero, size: foursquareRenderSize)
            }
            
            // 遍历trackItems
            trackItems.enumerated().forEach({ (offset, mainTrackItem) in
                let frame: CGRect = {
                    let index = offset % 4
                    return frameWithIndex(index)
                }()
                mainTrackItem.videoConfiguration.contentMode = .aspectFit
                mainTrackItem.videoConfiguration.frame = frame
                
                let timeRanges = fullTimeRange.substruct(mainTrackItem.timeRange)
                for timeRange in timeRanges {
                    Log.debug("timeRange: {\(String(format: "%.2f", timeRange.start.seconds)) - \(String(format: "%.2f", timeRange.end.seconds))}")
                    if timeRange.duration.seconds > 0 {
                        let staticTrackItem = mainTrackItem.copy() as! TrackItem
                        staticTrackItem.startTime = timeRange.start
                        staticTrackItem.duration = timeRange.duration
                        if timeRange.start <= mainTrackItem.timeRange.start {
                            let start = staticTrackItem.resource.selectedTimeRange.start
                            staticTrackItem.resource.selectedTimeRange = CMTimeRange(start: start, duration: CMTime(value: 1, 30))
                        } else {
                            let start = staticTrackItem.resource.selectedTimeRange.end - CMTime(value: 1, 30)
                            staticTrackItem.resource.selectedTimeRange = CMTimeRange(start: start, duration: CMTime(value: 1, 30))
                        }
                        overlays.append(staticTrackItem)
                    }
                }
            })
            
            return overlays
        }()
        
        // 创建CompositionGenerator
        timeline.renderSize = renderSize;
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    // MARK: 逆向播放视频
    
    func reversePlayerItem() -> AVPlayerItem?
    {
        let childTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "child", withExtension: "mp4")!
            let resource = AVAssetReverseImageResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let timeline = Timeline()
        timeline.videoChannel = [childTrackItem]
        timeline.renderSize = CGSize(width: 1920, height: 1080)
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    // MARK: 两个视频同屏同时播放
    
    func twoVideoPlayerItem() -> AVPlayerItem?
    {
        let renderSize = CGSize(width: 1920, height: 1080)
        // 创建 girlTrackItem
        let girlTrackItem: TrackItem = {
            let width = renderSize.width / 2
            let height = width * (9/16)
            let url = Bundle.main.url(forResource: "girl", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            resource.selectedTimeRange = CMTimeRange.init(start: CMTime.zero, end: CMTime.init(value: 1800, 600))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .custom
            trackItem.videoConfiguration.frame = CGRect(x: 0, y: (renderSize.height - height) / 2, width: width, height: height)
            return trackItem
        }()
        
        // 创建 childTrackItem
        let childTrackItem: TrackItem = {
            let height = renderSize.height
            let width = height * (9/16)
            let url = Bundle.main.url(forResource: "child", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            resource.selectedTimeRange = CMTimeRange.init(start: CMTime.zero, end: CMTime.init(value: 1800, 600))
            let trackItem = TrackItem(resource: resource)
            trackItem.audioConfiguration.volume = 0.3
            trackItem.videoConfiguration.contentMode = .custom
            trackItem.videoConfiguration.frame = CGRect(x: renderSize.width / 2 + (renderSize.width / 2 - width) / 2, y: (renderSize.height - height) / 2, width: width, height: height)
            return trackItem
        }()
        
        let trackItems = [girlTrackItem]
        
        let timeline = Timeline()
        timeline.videoChannel = trackItems
        timeline.audioChannel = trackItems
        
        timeline.overlays = [childTrackItem]
        timeline.audios = [childTrackItem]
        timeline.renderSize = renderSize;
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
}


extension ViewController: UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath)
        cell.textLabel?.text = titles[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let playerItem: AVPlayerItem? = {
            if indexPath.row == 1
            {
                return overlayPlayerItem()
            }
            else if indexPath.row == 2
            {
                return transitionPlayerItem()
            }
            else if indexPath.row == 3
            {
                return keyframePlayerItem()
            }
            else if indexPath.row == 4
            {
                return fourSquareVideo()
            }
            else if indexPath.row == 5
            {
                return reversePlayerItem()
            }
            else if indexPath.row == 6
            {
                return twoVideoPlayerItem()
            }

            return simplePlayerItem()
        }()
        
        if let playerItem = playerItem
        {
            let controller = AVPlayerViewController()
            controller.player = AVPlayer.init(playerItem: playerItem)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}
