
import UIKit
import StoreKit
import MessageUI
import Firebase
 

class SearchVideosTableView: UIViewController, UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate, UISearchDisplayDelegate,UITextFieldDelegate {
    // outlets
    @IBOutlet weak var tblSearchVideos: UITableView!
    @IBOutlet weak var searchBarVideo: UISearchBar!
    var arrSearch = NSMutableArray()
    var connectionStatus : Bool = false
    var newVideoBool : Bool = false
    var events = [Event]()
    var eventOwner : Bool = false
    var users = [User]()
    var selectedEvent: Event?
    var selectedUser: User?
    var videos = [Video]()
    var searchVideos = [Video]()
    var searchVideosText : String = ""
    var searchBarText : String = ""
    var videos1 : [Video] = [Video]()
   //let apiKey = "AIzaSyCjAaHQyUZ7Oip5fa4VG9oMxMsMLm7JVCM"  // party App
    let apiKey = "AIzaSyArxT8Itc8_YVT311y7nL9dhw3RN9QhJYI"  // Djyoumee  
    
    var videosArray: Array<Dictionary<NSObject, AnyObject>> = []
    var selectedVideo : Video?
    var lastContentOffset: CGFloat = 0
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
        searchBarVideo.placeholder = "search and add youtube songs"
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connectionStatus = true
            } else {
                self.connectionStatus = false
            }
        })
        
    }
    

    override func viewDidAppear(_ animated: Bool) {
        if self.searchVideos.count == 0{
            self.searchBarVideo.becomeFirstResponder()
            searchBarVideo.tintColor = titleColor
        }else{
            searchBarVideo.resignFirstResponder()   
        }
      
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
 
    }
    func showAlertInternetFail(){
        let alertControllerInternetFail = UIAlertController(title: "Oops", message: "Check Internet Connection and try again", preferredStyle: .alert)
        let action  = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            
        }
        alertControllerInternetFail.addAction(action )
        self.present(alertControllerInternetFail, animated: false, completion: nil)
        
    }
    
    // MARK: - Searchbar Delegate -
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        if (self.connectionStatus){
            tblSearchVideos.reloadData()
        }else{
            showAlertInternetFail()
        }
        
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchBarText = searchBar.text!
        if searchBarText == ""{
            self.searchVideos.removeAll()
            self.tblSearchVideos.reloadData()
            return
        }else{
            if searchBarText.count > 1{
                self.searchBarText = searchBarText
                self.performSegue(withIdentifier: "showAddToPlaylistFromSearchBar", sender: self)
                
            }else{
                self.searchVideos.removeAll()
                self.tblSearchVideos.reloadData()
            }
        }
        searchBar.resignFirstResponder()
    }
    func searchBar(_ searchBar: UISearchBar,  searchText: String) {
        if searchBar.text == ""{
            self.searchVideos.removeAll()
            //self.tblSearchVideos.reloadData()
            return
        }else{
            if searchText.count >= 3{
                 self.searchVideos.removeAll()
                self.searchYouttubeVideoData(searchText: searchText)
                
            }else{
                self.searchVideos.removeAll()
                self.tblSearchVideos.reloadData()
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: (Any)?) {
        let backItem = UIBarButtonItem()
        navigationItem.backBarButtonItem = backItem
        if (segue.identifier == "showAddToPlaylist"){
            let addPlaylistController = segue.destination  as! AddPlaylistController
            addPlaylistController.textSearch    = selectedVideo?.videoTitle
            addPlaylistController.selectedEvent = self.selectedEvent
        }else
            if (segue.identifier == "showAddToPlaylistFromSearchBar"){
                let addPlaylistController = segue.destination  as! AddPlaylistController
                addPlaylistController.textSearch    = self.searchBarText
                addPlaylistController.selectedEvent = self.selectedEvent
                //self.videos = addPlaylistController.videos
        }
    }

    // MARK: - UITableViewDelegate/DataSource methods
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return  50
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return searchVideos.count
        
    }
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
        if searchVideos.count != 0{
            cell.textLabel?.text = searchVideos[indexPath.row].videoTitle
            cell.textLabel?.textColor = titleColor
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.adjustsFontSizeToFitWidth   = true
        }
        
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (self.lastContentOffset < scrollView.contentOffset.y) {
            // moved to top
            searchBarVideo.resignFirstResponder()
        } else if (self.lastContentOffset > scrollView.contentOffset.y) {
            // moved to bottom
        } else {
            // didn't move
        }
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedVideo = self.searchVideos[indexPath.row]
        self.performSegue(withIdentifier: "showAddToPlaylist", sender: self)
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
    
   
    
    func searchYouttubeVideoData(searchText:String) -> Void {
        
        // Form the request URL string.
        //&videoCaption=closedCaption
        //&videoDefinition=high
        //&videoEmbeddable=true
        //&videoLicense=youtube
        /*  1 - Film & Animation
         2 - Autos & Vehicles
         10 - Music
         15 - Pets & Animals
         17 - Sports
         18 - Short Movies
         19 - Travel & Events
         20 - Gaming
         21 - Videoblogging
         22 - People & Blogs
         23 - Comedy
         24 - Entertainment
         25 - News & Politics
         26 - Howto & Style
         27 - Education
         28 - Science & Technology
         29 - Nonprofits & Activism
         30 - Movies
         31 - Anime/Animation
         32 - Action/Adventure
         33 - Classics
         34 - Comedy
         35 - Documentary
         36 - Drama
         37 - Family
         38 - Foreign
         39 - Horror
         40 - Sci-Fi/Fantasy
         41 - Thriller
         42 - Shorts
         43 - Shows
         44 - Trailers */
        //&videoSyndicated=true
        //let locale = Locale.current
        // print("The locale value : \(locale)")
        // let regionCode = (locale as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String
        // print("The regionCode value : \(regionCode)")
        
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=50&order=Relevance&q=\(searchBarVideo.text!)&type=video&safeSearch=moderate&category=10&videoEmbeddable=true&videoLicense=youtube&videoSyndicated=true&key=\(apiKey)"
        let safeURL = urlString.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
        // Create a NSURL object based on the above string.
        let targetURL = NSURL(string: safeURL)
        
        // Get the results.
        performGetRequest(targetURL! as URL, completion: { (data, HTTPStatusCode, error) -> Void in
            if HTTPStatusCode == 200 && error == nil {
                // Convert the JSON data to a dictionary object.
                do {
                    // Convert the JSON data into a dictionary.
                    let resultsDict = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
                    let items:Array<Dictionary<String, AnyObject>> = resultsDict["items"] as! Array
                    let arrayViewCount = NSMutableArray()
                    print("items : \(items)")
                    // Use a loop to go through all video items.
                    for i in 0 ..< items.count {
                        let snippetDict = items[i]["snippet"] as! Dictionary<String,AnyObject>
                        if (!snippetDict["title"]! .isEqual("Private video") && !snippetDict["title"]! .isEqual("Deleted video") && items[i]["id"]!["videoId"]! != nil){
                            let video = Video()
                            arrayViewCount.add(items[i]["id"]!["videoId"]! as! String)
                            video.videoTitle = (snippetDict["title"] as? String)!
                            video.videoThumbnail = ((snippetDict["thumbnails"] as! Dictionary<String,Any>)["high"] as! Dictionary<String,Any>)["url"] as! String
                            video.videoId = (items[i]["id"] as!  Dictionary<String, Any>)["videoId"] as! String
                            self.searchVideos.append(video)
                            self.arrSearch.addObjects(from: self.searchVideos)
                            DispatchQueue.main.async {
                                self.tblSearchVideos.reloadData()
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
        })
    }
}



