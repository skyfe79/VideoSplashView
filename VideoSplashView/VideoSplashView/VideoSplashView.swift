//
//  VideoSplashView.swift
//  VideoSplashView
//
//  Created by burt on 2016. 10. 6..
//  Copyright © 2016년 burt. All rights reserved.
//

import UIKit
import AVFoundation

@IBDesignable
public class VideoSplashView: UIView {
    
    override public class var layerClass: AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }
    
    public var mute : Bool {
        get {
            return player?.isMuted ?? true
        }
        
        set {
            player?.isMuted = newValue
        }
    }
    
    public var volume : Float {
        get {
            return player?.volume ?? 0.0
        }
        
        set {
            player?.volume = volume
        }
    }
    
    public var loop : Bool = true
    
    
    var url : URL? = nil
    var player : AVPlayer? = nil
    var playerLayer : AVPlayerLayer? {
        return self.layer as? AVPlayerLayer
    }
    
    var currentTime : CMTime = kCMTimeZero
    var imageGenerator : AVAssetImageGenerator? = nil
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setupView()
    }
    
    deinit {
        clear()
        NotificationCenter.default.removeObserver(self)
    }
}


extension VideoSplashView {
    
    fileprivate func setupView() {
        initPlayer()
        initPlayerLayer()
    }
    
    fileprivate func initPlayer() {
        guard let vlayer = self.playerLayer else { return }
        
        if let vp = player {
            vlayer.player = vp
        } else {
            player = AVPlayer()
            vlayer.player = player
        }
        
        // setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryAmbient, with: .mixWithOthers)
        } catch {
        }
    }
    
    fileprivate func initPlayerLayer() {
        guard let vlayer = self.playerLayer else { return }
        vlayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        vlayer.contentsGravity = kCAGravityResizeAspectFill
    }
    
    fileprivate func clear() {
        
        guard let vlayer = self.playerLayer else { return }
        
        if let vp = player {
            vp.pause()
            vp.replaceCurrentItem(with: nil)
            player = nil
            vlayer.player = nil
        }
    }

    public func prepareVideo(url: URL) {
        if player == nil {
            initPlayer()
        }
        guard let vp = player else { return }
        self.url = url
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        vp.replaceCurrentItem(with: playerItem)
        imageGenerator = AVAssetImageGenerator(asset: asset)
        
        if let cgImage = thumbnail(at: CMTimeMake(0, 1)) {
            self.playerLayer?.contents = cgImage
        }
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: vp.currentItem, queue: nil) { [weak self] (noti) in
            
            if self?.loop == true {
                vp.seek(to: kCMTimeZero)
                vp.play()
            }
        }
        
        NotificationCenter.default.addObserver(
                                        forName: Notification.Name.UIApplicationDidEnterBackground,
                                        object: nil,
                                        queue: nil) { [weak self] (noti) in
            self?.clear()
        }
        
        NotificationCenter.default.addObserver(
                                        forName: Notification.Name.UIApplicationWillEnterForeground,
                                        object: nil,
                                        queue: nil) { [weak self] (noti) in
            guard let vurl = self?.url else { return }
            self?.prepareVideo(url: vurl)
            self?.play()
        }
    }
    
    public func play() {
        self.player?.play()
    }
    
    public func pause() {
        self.player?.pause()
    }
    
    public func stop() {
        clear()
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func play(at: CMTime) {
        guard let vp = player else { return }
        guard let currentItem = vp.currentItem else { return }
        if vp.status == .readyToPlay && currentItem.status == .readyToPlay {
            
            vp.seek(to: at, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { [weak self] (finished) in
                self?.play()
            })
        } else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: { [weak self] in
                self?.play(at: at)
            })
        }
    }
    
    fileprivate func thumbnail(at: CMTime) -> CGImage? {
        do {
            return try imageGenerator?.copyCGImage(at: at, actualTime: nil)
        } catch {
            return nil
        }
    }
}
