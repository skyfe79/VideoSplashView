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
    
    public var mute : Bool {
        get {
            return player.isMuted
        }
        
        set {
            player.isMuted = newValue
        }
    }
    
    public var volume : Float {
        get {
            return player.volume
        }
        
        set {
            player.volume = volume
        }
    }
    
    public var loop : Bool = true
    
    lazy var player : AVPlayer = {
        AVPlayer()
    }()
    
    lazy var playerLayer : AVPlayerLayer = {
        AVPlayerLayer()
    }()
    
    var currentTime : CMTime = kCMTimeZero
    var imageGenerator : AVAssetImageGenerator? = nil
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setupView()
    }
}


extension VideoSplashView {
    
    fileprivate func setupView() {
        
        playerLayer.frame = self.frame
        playerLayer.player = player
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerLayer.contentsGravity = kCAGravityResizeAspectFill
        self.playerLayer.removeFromSuperlayer()
        self.layer.addSublayer(playerLayer)
        
    }

    public func prepareVideo(url: URL) {
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        self.player.replaceCurrentItem(with: playerItem)
        imageGenerator = AVAssetImageGenerator(asset: asset)
        
        if let cgImage = thumbnail(at: CMTimeMake(0, 1)) {
            self.playerLayer.contents = cgImage
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil) { [weak self] (noti) in
            
            if self?.loop == true {
                self?.player.seek(to: kCMTimeZero)
                self?.player.play()
            }
        }
        
        NotificationCenter.default.addObserver(
                                        forName: Notification.Name.UIApplicationDidEnterBackground,
                                        object: nil,
                                        queue: nil) { [weak self] (noti) in
                                            
            self?.currentTime = self?.player.currentTime() ?? kCMTimeZero
            self?.pause()
            self?.playerLayer.player = nil
        }
        
        NotificationCenter.default.addObserver(
                                        forName: Notification.Name.UIApplicationWillEnterForeground,
                                        object: nil,
                                        queue: nil) { [weak self] (noti) in
                                            
            self?.playerLayer.player = nil
            self?.playerLayer.player = self?.player
            self?.play(at: self?.currentTime ?? kCMTimeZero)
        }
    }
    
    public func play() {
        self.player.play()
    }
    
    public func pause() {
        self.player.pause()
    }
    
    fileprivate func play(at: CMTime) {
            
        guard let currentItem = player.currentItem else { return }
        if player.status == .readyToPlay && currentItem.status == .readyToPlay {
            
            player.seek(to: at, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { [weak self] (finished) in
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
