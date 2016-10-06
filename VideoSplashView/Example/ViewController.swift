//
//  ViewController.swift
//  Example
//
//  Created by burt on 2016. 10. 6..
//  Copyright © 2016년 burt. All rights reserved.
//

import UIKit
import VideoSplashView

class ViewController: UIViewController {
    
    @IBOutlet weak var videoSplashView: VideoSplashView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let url = Bundle.main.url(forResource: "splash", withExtension: "mov") else { return }
        videoSplashView.mute = true
        videoSplashView.prepareVideo(url: url)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        videoSplashView.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        videoSplashView.pause()
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

