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
 

private let refreshControl = UIRefreshControl()
class AddPlaylistController: UIViewController, UITableViewDataSource, UITableViewDelegate,UITextFieldDelegate {
    // outlets
    @IBOutlet weak var playListTableView: UITableView!
    @IBOutlet weak var partyPlaceLabel: NSLayoutConstraint!
    @IBOutlet weak var inviteesListLabel: UILabel!
    @IBOutlet weak var partyNameLabel: UILabel!
    @IBOutlet weak var partyDateLabel: UILabel!
    @IBOutlet weak var partyTimeLabel: UILabel!
    @IBOutlet weak var guestListButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIButton!
    var newVideoBool : Bool = true
    var events = [Event]()
    var eventOwner : Bool = false
    var users = [User]()
    var selectedEvent: Event?
    var selectedUser: User?
    var videos = [Video]()
    var searchVideos = [Video]()
    
    var addedVideos = [Int : Video]()
    var addedVideosTemp = [Int : Video]()
    var videos1 : [Video] = [Video]()
    let apiKey = "AIzaSyArxT8Itc8_YVT311y7nL9dhw3RN9QhJYI"  // Djyoumee
    var videosArray: Array<Dictionary<NSObject, AnyObject>> = []
    @IBOutlet weak var declinePartyButtonClicked: restoreButton!
    @IBOutlet weak var appNameTitleLabel: UILabel!
    // data
    var selectedIndex: String!
    var selectedVideo : Video?
    var textSearch : String?
    
    func fetchAddedVideos(){
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
            }
        })
    }

    @objc func addToPlaylistClicked(_ sender: playListButton) {
        if  sender.added == true{
            self.selectedVideo   = self.searchVideos[sender.indexPathRow!]
            sender.added = false
            self.addedVideos.removeValue(forKey: sender.indexPathRow!)
            self.addedVideosTemp.removeValue(forKey: sender.indexPathRow!)
        }else{
            self.selectedVideo   = self.searchVideos[sender.indexPathRow!]
            sender.added = true
            self.addedVideosTemp.updateValue(self.selectedVideo!, forKey: sender.indexPathRow!)
            if self.videos.count != 0{
                for video in self.videos
                {
                    if(video.videoId == self.selectedVideo?.videoId){
                        let alertController = UIAlertController(title: "DJyouMEE", message: "This Song is already added to the Playlist", preferredStyle: .alert)
                        let action2 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                        }
                        alertController.addAction(action2)
                        self.present(alertController, animated: true, completion: nil)
                        return
                    }
                }
                self.addedVideos.updateValue(self.selectedVideo!, forKey: sender.indexPathRow!)
            }
            else{
                self.addedVideos.updateValue(self.selectedVideo!, forKey: sender.indexPathRow!)
            }
        }
        self.playListTableView.reloadRows(at: [IndexPath(row: sender.indexPathRow!,section : 0)], with: .automatic)
    }
    
 
    @objc func addVideos() {
        let dbRef = Database.database().reference()
        for key in self.addedVideos{
            let addVideo = key.value
            let values = ["videoId": addVideo.videoId,"videoTitle":addVideo.videoTitle,"videoDescription":"","videoThumbnail":addVideo.videoThumbnail,"likeCount":0 ,"likedUserIds":[String : Any]() ] as [String : Any]
            let refPlaylistCollection =  Database.database().reference().child("playlistCollection").child((selectedEvent!.uid))
            let newYoutubeRef = refPlaylistCollection.child("youtubeIds").childByAutoId()
            let newYoutubeKey = newYoutubeRef.key
            let playlistUpdates = ["/playlistCollection/\((selectedEvent!.uid))/youtubeIds/\(newYoutubeKey!)/": values]
            dbRef.updateChildValues(playlistUpdates)
        }
    }
   
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
        self.doneButton.layer.cornerRadius = 5.0
        self.doneButton.addTarget(self, action: #selector(self.addVideos), for: .touchUpInside)
        self.handleSearchVideos(textSearch: self.textSearch!)
        self.fetchAddedVideos()
       
    }
   
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: (Any)?) {
        let backItem = UIBarButtonItem()
        navigationItem.backBarButtonItem = backItem
        if (segue.identifier == "showVideoDetalView")
        {
            let detailViewContoller = segue.destination  as! VideoDetailViewController
            detailViewContoller.selectedVideo = self.selectedVideo
            detailViewContoller.selectedEvent = self.selectedEvent
            print("the selected video from the Add Play lis View :\(String(describing: self.selectedVideo?.videoTitle))")
        }
    }

    // MARK: - UITableViewDelegate/DataSource methods
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return  100
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return  self.searchVideos.count
        
    }
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addCellId", for: indexPath)
        let tittleView = cell.viewWithTag(2) as! UILabel
        let addToPlaylistButton = cell.viewWithTag(3) as! playListButton
        addToPlaylistButton.selectedVideoId = self.searchVideos[indexPath.row].videoId
        addToPlaylistButton.addTarget(self, action: #selector(addToPlaylistClicked(_:)), for: .touchUpInside)
        DispatchQueue.main.async {
            addToPlaylistButton.indexPathRow = indexPath.row
            if self.addedVideosTemp.count == 0 {
                addToPlaylistButton.added = false
                addToPlaylistButton.alpha = 1.0
                addToPlaylistButton.setImage(#imageLiteral(resourceName: "plusImageOrange"), for: .normal)
                addToPlaylistButton.tintColor = orangeColor
            }else{
                if (self.addedVideosTemp[indexPath.row]?.videoId == self.searchVideos[indexPath.row].videoId){
                    addToPlaylistButton.added = true
                    addToPlaylistButton.alpha = 1.0
                    addToPlaylistButton.setImage(#imageLiteral(resourceName: "tickImageGreen"), for: .normal)
                    addToPlaylistButton.tintColor = UIColor.green
                }else{
                    addToPlaylistButton.added = false
                    addToPlaylistButton.alpha = 1.0
                    addToPlaylistButton.setImage(#imageLiteral(resourceName: "plusImageOrange"), for: .normal)
                    addToPlaylistButton.tintColor = orangeColor
                }
            }
        }
        tittleView.text = searchVideos[indexPath.row].videoTitle
        tittleView.textColor = titleColor
        tittleView.adjustsFontSizeToFitWidth   = true
        let videoThumbnailUrlString =  "https://img.youtube.com/vi/"  +  searchVideos[indexPath.row].videoId + "/mqdefault.jpg"
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
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedVideo = self.searchVideos[indexPath.row]
        self.performSegue(withIdentifier: "showVideoDetalView", sender: self)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
  
    func performGetRequest(_ targetURL: URL, completion: @escaping (_ data: Data?, _ HTTPStatusCode: Int?, _ error: Error?) -> Void) {
        
        var request = URLRequest(url: targetURL)
        request.httpMethod = "GET"
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async(execute: {
                completion(data, (response as? HTTPURLResponse)?.statusCode, error)
            })
        }
        task.resume()
    }
    
    func handleSearchVideos(textSearch:String) {
        
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=25&order=Relevance&q=\(textSearch)&type=video&category=10&videoSyndicated=true&videoEmbeddable=true&videoDefinition=high&videoLicense=youtube&videoType=any&key=\(apiKey)"
        let safeURL = urlString.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
        // Create a NSURL object based on the above string.
        let targetURL = NSURL(string: safeURL)
        
        // Get the results.
        performGetRequest(targetURL! as URL, completion: { (data, HTTPStatusCode, error) -> Void in
            if HTTPStatusCode == 200 && error == nil {
                do {
                    // Convert the JSON data into a dictionary.
                    let resultsDict = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
                    let items:Array<Dictionary<String, AnyObject>> = resultsDict["items"] as! Array
                    print("items : \(items)")
                    // Use a loop to go through all video items.
                    for i in 0 ..< items.count {
                        let snippetDict = items[i]["snippet"] as! Dictionary<String,AnyObject>
                        if (!snippetDict["title"]! .isEqual("Private video") && !snippetDict["title"]! .isEqual("Deleted video") && items[i]["id"]!["videoId"]! != nil){
                            let video = Video()
                            video.videoTitle = (snippetDict["title"] as? String)!
                            video.videoThumbnail = ((snippetDict["thumbnails"] as! Dictionary<String,Any>)["default"] as! Dictionary<String,Any>)["url"] as! String
                            video.videoId = (items[i]["id"] as!  Dictionary<String, Any>)["videoId"] as! String
                            self.searchVideos.append(video)
                            DispatchQueue.main.async {
                                self.playListTableView.reloadData()
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            }
            else {
                print("HTTP Status Code = \(String(describing: HTTPStatusCode))")
                print("Error while loading channel videos: \(String(describing: error))")
            }
            // Hide the activity indicator.
            refreshControl.endRefreshing()
        })
    }
    
}



