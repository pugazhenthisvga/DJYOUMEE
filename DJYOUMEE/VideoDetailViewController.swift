//
//  detailVideoController.swift
//  jukeBox1.4
//
//  Created by PUGAZHENTHI VENKATACHALAM on 24/05/18.
//  Copyright © 2018 PUGAZHENTHI VENKATACHALAM. All rights reserved.
//

import UIKit
import YouTubePlayer_Swift

class VideoDetailViewController: UIViewController ,YouTubePlayerDelegate{
    func playerReady(_ videoPlayer: YouTubePlayerView) {
        videoPlayer.play()
    }
    
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {
        
    }
    
    func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality) {
        
    }
    
    
    @IBOutlet weak var videoPlayer: YouTubePlayerView!
    @IBOutlet weak var descriptionLabel: UILabel!
    var selectedVideo : Video?
    var selectedEvent: Event?
   
    override func viewDidLoad() {
        super.viewDidLoad()
        let TITLELABEL : UILabel = UILabel(frame: CGRect.zero)
        TITLELABEL.frame = CGRect(x: 15, y: 0, width: 300, height: 40) as CGRect
        TITLELABEL.backgroundColor = UIColor.clear
        TITLELABEL.text = self.selectedEvent?.eventName
        TITLELABEL.textColor = titleColor
        TITLELABEL.numberOfLines = 2  //  Helvetica Bold 14.0
        TITLELABEL.font = UIFont (name: "Arial Rounded MT Bold", size: 16)
        TITLELABEL.adjustsFontSizeToFitWidth     = true
        TITLELABEL.textAlignment = NSTextAlignment.center
        self.navigationItem.titleView = TITLELABEL
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationItem.title = self.selectedEvent?.eventName
        if let vid  = self.selectedVideo {
        self.videoPlayer.loadVideoID(vid.videoId)
            self.descriptionLabel.text = vid.videoTitle
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
