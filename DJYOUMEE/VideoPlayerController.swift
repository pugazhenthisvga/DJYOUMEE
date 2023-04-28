//
//  ViewController.swift
 
//
//  
//  
//

import UIKit
import StoreKit
import MessageUI
import Firebase
import YouTubePlayer_Swift

class VideoPlayerController: UIViewController,UIWebViewDelegate {

    // outlets
    @IBOutlet weak var videoPlayer: YouTubePlayerView!
    @IBOutlet weak var videoTitleLabel: UILabel!
    var events = [Event]()
    var eventOwner : Bool = false
    var selectedEvent: Event?
    var shouldPlayVideoWhenQueued : Bool = true
    var addVideo : [Video]?
    var videoId :String =  ""
    var videoTitle :String =  ""
    var queuedVideo : Video?
    var videos = [Video]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoPlayer.delegate = self
        let slideDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissView(gesture:)))
        slideDown.direction = .down
        view.addGestureRecognizer(slideDown)
        fetchVideo()
    }
    @IBAction func handleDoneButton(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    @objc func dismissView(gesture: UISwipeGestureRecognizer) {
        UIView.animate(withDuration: 0.5) {
        if let keyWindow = UIApplication.shared.keyWindow {
        gesture.view?.frame = CGRect(x:keyWindow.frame.width - 15 , y: keyWindow.frame.height - 15, width: keyWindow.frame.width , height: keyWindow.frame.height)
        }
        }
        self.dismiss(animated: true, completion: nil)
    }
    @objc  func fetchVideo(){
        
        var newVideos = [Video]()
        let videoRef  = Database.database().reference().child("playlistCollection").child((selectedEvent?.uid)!).child("youtubeIds")
        videoRef.queryOrdered (byChild: "likeCount").observe(.childAdded, with: { (snapshot) in
            if let dictionaryVideo = snapshot.value  as? [String : AnyObject]
            {
                let video = Video()
                video.setValuesForKeys(dictionaryVideo)
                video.uid = snapshot.key
                newVideos.append(video)
                newVideos.sort(by: {$0.likedUserIds.count > $1.likedUserIds.count})
                self.videos = newVideos
                DispatchQueue.main.async {
                    if let vid  = self.videos.first {
                        self.videoTitleLabel.text = vid.videoTitle
                        if  let currentUser  = Auth.auth().currentUser{
                            if currentUser.uid == (self.selectedEvent?.owner)!{
                                self.queuedVideo = vid
                                if(self.videoPlayer.playerState == .Playing){
                                    
                                }else if(self.videoPlayer.playerState == .Queued){
                                    
                                }
                                else if(self.videoPlayer.playerState == .Unstarted){
                                    self.videoPlayer.loadVideoID((self.queuedVideo?.videoId)!)
                                }
                                else if(self.videoPlayer.playerState == .Ended){
                                    if self.queuedVideo?.likedUserIds.count != 0{
                                        self.videoPlayer.loadVideoID(self.queuedVideo!.videoId)
                                        
                                    }else{
                                        self.shouldPlayVideoWhenQueued = false
                                    }
                                }else if (self.videoPlayer.playerState  == .Buffering){
                                    
                                }
                            }
                        }
                    }
                }  // DispatchQueue.main.async ends
            }
            
        },withCancel: nil)
        if newVideos.count == 0{
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationItem.title = self.selectedEvent?.eventName
    }
 
    func disableVoting(playedVideo : Video) {
        if  let currentUser  = Auth.auth().currentUser{
            if currentUser.uid == (selectedEvent?.owner)!{
                let playedYoutubeVideo = playedVideo
                let dbRef = Database.database().reference()
                let playedVideoRef = dbRef.child("playlistCollection").child((selectedEvent?.uid)!).child("youtubeIds").child((playedYoutubeVideo.uid)).child("likedUserIds")
                playedVideoRef.removeValue()
            }
        }
    }
}

extension VideoPlayerController: YouTubePlayerDelegate {
    func playerQualityChanged(_ videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality) {
        print("video player is ready 3: \(videoPlayer.playbackQuality)")
        
    }

    // MARK: YTPlayerViewDelegate
    
       
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {
        switch videoPlayer.playerState {
        case .Unstarted:
            // code
            // MARK: "player state Unstarted"
            break
        case .Ended:
            // code
            self.fetchVideo()
            print("player state Ended")
            break
        case .Playing:
            // code
            self.disableVoting(playedVideo: self.queuedVideo!)
            // MARK:"player state Playing"
            break
        case .Paused:
            // code
            // MARK:"player state Paused"
            break
        case .Buffering:
            //code
            // MARK:"player state Biffering"
            break
        case .Queued:
            //code
            // MARK:"player state Queued"
            break
        }
    }

    func playerReady(_ videoPlayer: YouTubePlayerView) {
        if self.shouldPlayVideoWhenQueued == true{
        self.videoPlayer.play()
        }
    }
}



