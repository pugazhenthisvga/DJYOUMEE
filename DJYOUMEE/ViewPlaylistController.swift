
// ViewController.swift
import UIKit
import StoreKit
import MessageUI
import Firebase
import YouTubePlayer_Swift
class ViewPlaylistController: UIViewController, UITableViewDataSource, UITableViewDelegate,UIWebViewDelegate {
   
    var acceptedUser : Bool?
    lazy var playlistRefresh: UIRefreshControl = {
        let playlistRefresh = UIRefreshControl()
        playlistRefresh.addTarget(self, action: #selector(self.handlePlaylistRefresh), for: .valueChanged)
        playlistRefresh.tintColor = orangeColor
        return playlistRefresh
    }()
    @objc func roundButtonClick() {
        
        if  let currentUser  = Auth.auth().currentUser{
            if currentUser.uid == (selectedEvent?.owner)! && self.videos.count != 0 {
                self.performSegue(withIdentifier: "popVideoPlayer", sender: self)
                
            }else if currentUser.uid != (selectedEvent?.owner)! {
                let alertController = UIAlertController(title: "DJyouMEE", message: "Wait for the Party : Let your host Play", preferredStyle: .alert)
                let action2 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                    print("You've pressed cancel");
                }
                alertController.addAction(action2)
                self.present(alertController, animated: true, completion: nil)
            }else if currentUser.uid == (selectedEvent?.owner)! && self.videos.count == 0{
                let alertController = UIAlertController(title: "DJyouMEE", message: "Add youtube songs to the playlist", preferredStyle: .alert)
                let action2 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                    print("You've pressed cancel");
                }
                alertController.addAction(action2)
                self.present(alertController, animated: true, completion: nil)
                //self.performSegue(withIdentifier: "popVideoPlayer", sender: self)   //  to be removed after testing for playlist ID
            }
        }
    }
    
    @objc func addVideosButtonClick() {
        if  self.acceptedUser == true{
            self.performSegue(withIdentifier: "showSearchVideo", sender: self)
        }else {
            let alertController = UIAlertController(title: "DJyouMEE", message: "Accept the invite before you add and vote songs in the playlist", preferredStyle: .alert)
            let action2 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                self.performSegue(withIdentifier: "unwindToViewGuest", sender: self)
            }
            alertController.addAction(action2)
            self.present(alertController, animated: true, completion: nil)
            //self.performSegue(withIdentifier: "popVideoPlayer", sender: self)   //  to be removed after testing for playlist ID
        }
    }
    
    // outlets
    @IBOutlet weak var baseLabel: UILabel!
    @IBOutlet weak var playAllButton: UIButton!
    @IBOutlet weak var playListTableView: UITableView!
    @IBOutlet weak var videoTitleLabel: UILabel!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var addSongButton: UIButton!
    @IBOutlet weak var addGuestButton: UIButton!
    
    var refPlaylist: DatabaseReference!
    var refPlaylistVote: DatabaseReference!
    var refUser : DatabaseReference!
    var ref : DatabaseReference!
    var playlistHandle : UInt!
    var playlistHandleVote : UInt!
    var eventChildHandle : UInt!
    var userHandle : UInt!
    var events = [Event]()
    var eventOwner : Bool = false
    var users = [User]()
    var selectedEvent: Event?
    var selectedUser: User?
    var addVideo : [Video]?
    var videoId :String =  ""
    var videoTitle :String =  ""
    var roundButton = UIButton()
    @IBOutlet weak var declinePartyButtonClicked: restoreButton!

    var addedVideo : Video?
    var playingVideo : Video?
    var queuedVideo : Video?
    var addedVideoId : String?
    var addedVideoTitle : String?
    var selectedVideo: Video?
    var videos = [Video]()
    var shouldPlayVideoWhenQueued : Bool?
    var unwindSegueToAddGuest : Bool?
    
    @objc func likeButtonPressed(_ sender: likeButton){
        let currentUser  = Auth.auth().currentUser
        let uid = currentUser?.uid
        let dbRef = Database.database().reference()
        if self.acceptedUser == true{
            if sender.liked == true{
                self.selectedVideo   = self.videos[sender.indexPathRow!]
                let dislikedUsersRef  = dbRef.child("playlistCollection").child((selectedEvent?.uid)!).child("youtubeIds").child((selectedVideo?.uid)!).child("likedUserIds").child(uid!)
                dislikedUsersRef.removeValue()
            }else if (sender.liked == false){
                self.selectedVideo   = self.videos[sender.indexPathRow!]
                let likedUsersRef = dbRef.child("playlistCollection").child((selectedEvent?.uid)!).child("youtubeIds").child((selectedVideo?.uid)!).child("likedUserIds").child(uid!)
                let likedUserKey = likedUsersRef.key
                let updateLikedUserValues = ["/playlistCollection/\((selectedEvent?.uid)!)/youtubeIds/\(((selectedVideo?.uid)!))/likedUserIds/\(likedUserKey!)":uid!]
                dbRef.updateChildValues(updateLikedUserValues)
                
            }
            
        }else{
            let alertController = UIAlertController(title: "DJyouMEE", message: "Accept the invite before you add and vote songs in playlist", preferredStyle: .alert)
            let action2 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                self.performSegue(withIdentifier: "unwindToViewGuest", sender: self)
            }
            alertController.addAction(action2)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    @objc func handleUnWindOwner(){
        if self.unwindSegueToAddGuest == true{
            self.performSegue(withIdentifier: "unwindToAddGuest", sender: self)
        }else{
            self.performSegue(withIdentifier: "showAddGuestsPage", sender: self)
        }
    }
    @objc func handleUnWindGuest(){
        self.performSegue(withIdentifier: "unwindToViewGuest", sender: self)
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        playlistHandleVote =  refPlaylistVote.observe(.childAdded) { (snapshot) in
            self.fetchVideo()
        }
        playlistHandle =  refPlaylist.observe(.childChanged) { (snapshot) in
            self.fetchVideo()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        refUser = Database.database().reference().child("users")
        refPlaylist = Database.database().reference().child("playlistCollection/\(selectedEvent!.uid)/youtubeIds")
        refPlaylistVote = Database.database().reference().child("playlistCollection").child((selectedEvent?.uid)!).child("youtubeIds")
        if  let currentUser  = Auth.auth().currentUser{
            self.playAllButton.addTarget(self, action: #selector(self.roundButtonClick), for: .touchUpInside)
            if currentUser.uid == (selectedEvent?.owner)!{
                self.acceptedUser = true
                self.addGuestButton.setBackgroundImage(#imageLiteral(resourceName: "addGuestOrangeImage"), for: .normal   )
                self.addGuestButton.addTarget(self, action: #selector(handleUnWindOwner), for: .touchUpInside)
            }else{
                self.addGuestButton.setBackgroundImage(#imageLiteral(resourceName: "guestOrangeImage"), for: .normal    )
                self.addGuestButton.addTarget(self, action: #selector(handleUnWindGuest), for: .touchUpInside)
            }
            self.addSongButton.addTarget(self, action: #selector(addVideosButtonClick), for: .touchUpInside)
        }
        let TITLELABEL : UILabel = UILabel(frame: CGRect.zero)
        TITLELABEL.frame = CGRect(x: 15, y: 0, width: 300, height: 40) as CGRect
        TITLELABEL.backgroundColor = UIColor.clear
        TITLELABEL.text = "Playlist : \(self.selectedEvent!.eventName)"
        TITLELABEL.textColor = titleColor
        TITLELABEL.numberOfLines = 2
        TITLELABEL.font = UIFont (name: "Arial Rounded MT Bold", size: 16)
        TITLELABEL.adjustsFontSizeToFitWidth     = true
        TITLELABEL.textAlignment = NSTextAlignment.center
        self.navigationItem.titleView = TITLELABEL
        baseLabel.layer.cornerRadius = 5.0
        baseLabel.layer.masksToBounds = true
        self.playAllButton.layer.cornerRadius = 5.0
        self.playListTableView.refreshControl = self.playlistRefresh
        DispatchQueue.main.async {
            // self.fetchVideo()
        }
        
    }
    @objc func handlePlaylistRefresh( playlistRefresh : UIRefreshControl){
        self.fetchVideo()
        playlistRefresh.endRefreshing()
    }
    @objc  func fetchVideo(){
        var newVideos = [Video]()
        playlistHandleVote =  refPlaylistVote.queryOrdered (byChild: "likeCount").observe(.childAdded, with: { (snapshot) in
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
                        if  let currentUser  = Auth.auth().currentUser{
                            if currentUser.uid == (self.selectedEvent?.owner)!{
                                self.queuedVideo = vid
                            }
                        }
                    }
                    
                }  //   DispatchQueue.main.async ends
                
                self.playListTableView.reloadData()
            }
        },withCancel: nil)
        
    }
// MARK: - Tested func for fetching
 /* @objc  func fetchVideo(){
        var newVideos = [Video]()
        let videoRef  = Database.database().reference().child("playlistCollection").child((selectedEvent?.uid)!).child("youtubeIds")
        videoRef.queryOrdered (byChild: "likeCount").observe(.childAdded, with: { (snapshot) in
            print("snap Shot from the fetch videos : \(snapshot)")
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
                        if  let currentUser  = Auth.auth().currentUser{
                            if currentUser.uid == (self.selectedEvent?.owner)!{
                                self.queuedVideo = vid
                            }
                        }
                    }
                    
               }  //   DispatchQueue.main.async ends
                
                
                self.playListTableView.reloadData()
            }
        },withCancel: nil)
    }*/
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        refPlaylistVote.removeObserver(withHandle: playlistHandleVote)
        refPlaylist.removeAllObservers()
  
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

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        navigationItem.backBarButtonItem = backItem
        if (segue.identifier == "showVideoDetalView"){
            let detailViewContoller = segue.destination  as! VideoDetailViewController
            detailViewContoller.selectedVideo = self.selectedVideo
            detailViewContoller.selectedEvent = self.selectedEvent
        }else if (segue.identifier   == "DJsegue"){
            let detailViewContoller = segue.destination  as! VideoDetailViewController
            detailViewContoller.selectedVideo = self.selectedVideo
            detailViewContoller.selectedEvent = self.selectedEvent
        }else if (segue.identifier   == "showSearchVideo"){
            let searchVideosTableView = segue.destination  as! SearchVideosTableView
            searchVideosTableView.selectedVideo = self.selectedVideo
            searchVideosTableView.selectedEvent = self.selectedEvent
            searchVideosTableView.videos = self.videos
        }else if (segue.identifier == "popVideoPlayer")
        {
            let videoPlayerController = segue.destination  as! VideoPlayerController
            videoPlayerController.selectedEvent = self.selectedEvent
            videoPlayerController.shouldPlayVideoWhenQueued = true
            
            
        }
        else if (segue.identifier == "showAddGuestsPage")
        {
            let addGuestViewController = segue.destination  as! AddGuestViewController
            addGuestViewController.selectedEvent = self.selectedEvent
        }
    }
    @IBAction func unwindSeguePlaylist(segue:UIStoryboardSegue){
        
    }
    // MARK: - UITableViewDelegate/DataSource methods
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return  90
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  self.videos.count
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentUser  = Auth.auth().currentUser
        let uid = currentUser?.uid
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        let tittleView = cell.viewWithTag(2) as! UILabel
        let likeCountsLabel = cell.viewWithTag(5) as! likeCountLabel
        let likeButton = cell.viewWithTag(4) as! likeButton
        likeButton.addTarget(self, action: #selector(likeButtonPressed(_:)), for: .touchUpInside)
        likeCountsLabel.text = String(self.videos[indexPath.row].likedUserIds.count)
        DispatchQueue.main.async {
            likeButton.indexPathRow = indexPath.row
            if self.videos[indexPath.row].likedUserIds.count == 0  {
                likeButton.liked = false
                likeButton.alpha = 1.0
                likeButton.tintColor = orangeColor  
                likeButton.setImage(#imageLiteral(resourceName: "orangeLikeImage"), for: .normal)
                
            }else{
                for likedUserUID in self.videos[indexPath.row].likedUserIds{
                    if (likedUserUID.key == uid){
                        likeButton.liked     = true
                        likeButton.alpha  = 1.0
                        likeButton.tintColor = UIColor(r: 0, g: 204, b: 0)  //  green
                        likeButton.setImage(#imageLiteral(resourceName: "greenLikeImage"), for: .normal)
                        return
                    }else{
                        likeButton.liked = false
                        likeButton.alpha = 1.0
                        likeButton.tintColor = orangeColor
                        likeButton.setImage(#imageLiteral(resourceName: "orangeLikeImage"), for: .normal)
                        
                    }
                }
            }
        }
        
        tittleView.text = "  " + self.videos[indexPath.row].videoTitle
        tittleView.textColor = titleColor
        tittleView.adjustsFontSizeToFitWidth   = true
        // let videoThumbnailUrlString =  "https://img.youtube.com/vi/"  +  self.videos[indexPath.row].videoId + "/maxresdefault.jpg"  ///mqdefault.jpg
        let videoThumbnailUrlString =  "https://img.youtube.com/vi/"  +  self.videos[indexPath.row].videoId + "/mqdefault.jpg"  ///mqdefault.jpg
        // create an NSURL object
        let videoThumbnailUrl = URL(string: videoThumbnailUrlString)
        // create a NSURLREQUEST Object
        let request = URLRequest(url: videoThumbnailUrl!)
        // create a NSRUL Session
        let session = URLSession.shared
        // creat a datatask and pass in the request
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                let imageView = cell.viewWithTag(1) as! UIImageView
                imageView.image = UIImage(data: data!)
            }
        }
        dataTask.resume()
        print("The likebutton.liked for row :\(indexPath.row) : \(String(describing: likeButton.liked)) : \(likeButton.alpha) : \(self.videos[indexPath.row].likedUserIds.count)")
        return cell
    }
  
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedVideo = self.videos[indexPath.row]
        self.performSegue(withIdentifier: "DJsegue", sender: self)
        
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
}



