//
//  ViewController.swift


import UIKit
import MessageUI
import Firebase
import UserNotifications

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    // outlets
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = orangeColor
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        return refreshControl
    }()
    
    @IBOutlet weak var myEventsLabel: UILabel!
    @IBOutlet weak var peopleTableView: UITableView!
    @IBOutlet weak var restoreButton: UIBarButtonItem!
    @IBOutlet weak var createPartyButton: UIButton!
    var loginControllerNew : UIViewController = LoginControllerNew()
    var currentUser :  User?
    var currentUserId :  String?
    var refEvent: DatabaseReference!
    var refUser : DatabaseReference!
    var eventHandle : UInt!
    var userHandle : UInt!
    var selectedEvent: Event?
    var events = [Event]()
    var eventOwner : Bool = false
    var connectionStatus : Bool = false
    var fcmTokenRefreshed : Bool?
    let party = partyDate()
    
    @objc func handleRefresh( refreshControl : UIRefreshControl){
            checkIfUserIsLoggedin()
            print("iam refreshed ... ")
            refreshControl.endRefreshing()
    }
  
    
    
    func showAlertAuthTokenFail(){
        let alertControllerInternetFail = UIAlertController(title: "Oops", message: "Your Session was expired... Login now ", preferredStyle: .alert)
        let action  = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            self.handleLogOut()
        }
        alertControllerInternetFail.addAction(action )
        self.present(alertControllerInternetFail, animated: false, completion: nil)
        
    }
    @objc func fetchParty(){
        if self.currentUser!.eventIds.count == 0{
        return
        }else{
          
            let sv  = LoginControllerNew.displaySpinner(onView: self.view)
            self.events.removeAll()
            var newEvents = [Event]()
            let formatter = DateFormatter()
            formatter.timeStyle = .none
            formatter.dateFormat = "MM/dd/yyyy" //Your date format
            let eventRef  = Database.database().reference().child("event")
            for key in self.currentUser!.eventIds.keys{
                eventHandle =    eventRef.queryOrderedByKey().queryEqual(toValue: key).observe  (.childAdded, with: { (snapshot) -> Void in
                    if let dictionaryEvent = snapshot.value  as? [String : AnyObject] {
                        let event = Event()
                        event.setValuesForKeys(dictionaryEvent)
                        event.uid = snapshot.key
                        var eventDate = formatter.date(from: event.partyDateEnd) ??  formatter.date(from: event.partyDate)
                        print("event date : \(String(describing: eventDate))")
                        eventDate = eventDate?.addingTimeInterval(24 * 60 * 60)
                        let earlydate : Double =   (eventDate?.timeIntervalSince(NSDate() as Date))!
                        print("early date : \(event.eventName)  ||  \(earlydate)")
                        if (earlydate > 0) {
                            newEvents.append(event)
                        }
                        self.checkIfEventOwnerIsGuest()
                        DispatchQueue.main.async {
                            //newEvents.sort(by: {$0.partyDate < $1.partyDate})
                            newEvents.sort(by: {formatter.date(from: $0.partyDate)! < formatter.date(from: $1.partyDate)!})
                            self.events = newEvents
                            LoginControllerNew.removeSpinner(spinner: sv)
                            self.peopleTableView.reloadData()
                            
                        }
                    }
                }, withCancel: nil)
            }

        }
        
    }
    
    
    
    func checkIfEventOwnerIsGuest(){
        if Auth.auth().currentUser?.uid != nil{
            for event in self.events {
                let currentUserId  = Auth.auth().currentUser!.uid
                if(event.owner == currentUserId  ){
                    self.eventOwner = true
                }else{
                    
                }
            }
        }
    }
    
    @IBAction func unwindHome(segue:UIStoryboardSegue){
        
    }
    
    func checkEventDate(){
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "MM/dd/yyyy" //Your date format
        for event in self.events{
            var eventDate = formatter.date(from: event.partyDateEnd)
            eventDate = eventDate?.addingTimeInterval(12 * 60 * 60)
            let earlydate : Double =   (eventDate?.timeIntervalSinceNow)!
            if (earlydate < 0) {
                if  let currentEventIndex =     self.events.index(of:event){
                    self.events.remove(at: currentEventIndex)
                }
            }else {
                
            }
        }
    }

    func checkIfUserIsLoggedin(){
        if Auth.auth().currentUser?.uid == nil{
            perform(#selector(handleLogOut), with: nil, afterDelay: 0)
        }else{
            let currentUser1 = User()
            let uid = Auth.auth().currentUser?.uid
            self.currentUserId = Auth.auth().currentUser?.uid
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionaryUser = snapshot.value as? [String : AnyObject]{
                    currentUser1.uid = snapshot.key
                    currentUser1.setValuesForKeys(dictionaryUser)
                    self.currentUser = currentUser1
                    if self.currentUser?.eventIds.count != 0{
                        self.fetchParty()
                    }
                    
                }
            }, withCancel: nil)
            
        }
        
    }
    @objc func handleLogOut(){
        do {
            try Auth.auth().signOut()
        }
        catch let logoutError  {
            print(logoutError)
        }
        let loginController =    self.storyboard?.instantiateViewController(withIdentifier:"loginViewNew")
        let navController = UINavigationController(rootViewController: loginController!)
        self.present(navController, animated: true, completion: nil)
        refUser.removeAllObservers()
        refEvent.removeAllObservers()
    }
    
    
    @objc func checkAuthenticationStatus(){
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connectionStatus = true
                print("connection : true")
                print(NSDate().timeIntervalSinceNow)
                
            } else {
                print("connection : fails fails")
                self.connectionStatus = false
                print(NSDate().timeIntervalSinceNow)
                
                
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       Auth.auth().addStateDidChangeListener { (auth, user) in
        if Auth.auth().currentUser != nil {
            print("fctTokenStatus : \(String(describing: self.fcmTokenRefreshed))")
            if self.fcmTokenRefreshed == true{
                InstanceID.instanceID().instanceID(handler: { (result, error) in
                    if let error = error {
                        print("Error fetching remote instange ID: \(error)")
                    } else if let result = result {
                        let refUser = Database.database().reference().child("users")
                        let currentUserUId = Auth.auth().currentUser?.uid
                        let refCurrentUser = refUser.child(currentUserUId!).child("fcmToken")
                        refCurrentUser.setValue(result.token)
                    }
                })
            }
            Auth.auth().currentUser?.getIDToken(completion: { (token, error) in
                if error != nil {
                    print("error to refresh")
                    print(error ?? "error")
                }
                else {
                    print("Access token refreshed")
                }
            })
            self.checkIfUserIsLoggedin()
            print("user logged in")
        } else {
             print("user logged out")
            self.handleLogOut()
        }
        }
        refUser = Database.database().reference().child("user")
        refEvent     = Database.database().reference().child("event")
        self.createPartyButton.layer.cornerRadius = 5.0
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "LogOut", style: .plain, target: self, action: #selector(handleLogOut))
        peopleTableView.register(UINib(nibName: "PartyTableViewCell", bundle: nil), forCellReuseIdentifier: "PartyTableViewCell")
        self.peopleTableView.refreshControl = refreshControl
        self.checkIfUserIsLoggedin()
        let eventRef  = Database.database().reference().child("event")
        eventHandle =  eventRef.observe(.childChanged) { (snapshot) in
            self.checkIfUserIsLoggedin()
        }
        
        guard (self.currentUserId != nil) else {
            return
        }
        self.currentUserId = Auth.auth().currentUser?.uid
        let userRef  = Database.database().reference().child("users").child(self.currentUserId!)
        userRef.observe(.childChanged) { (snapshot) in
            self.checkIfUserIsLoggedin()
        }
        
      // Timer.scheduledTimer(timeInterval: 0, target: self, selector:#selector(self.checkAuthenticationStatus), userInfo: nil, repeats: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard (userHandle != nil) else {
            return
        }
       //refUser.removeObserver(withHandle: userHandle)
       //refEvent.removeObserver(withHandle: eventHandle)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if Auth.auth().currentUser?.uid != nil{
            let TITLELABEL : UILabel = UILabel(frame: CGRect.zero)
            TITLELABEL.frame = CGRect(x: 15, y: 0, width: 300, height: 40) as CGRect
            TITLELABEL.backgroundColor = UIColor.clear
            TITLELABEL.textColor = titleColor
            TITLELABEL.numberOfLines = 2  //  Helvetica Bold 14.0
            TITLELABEL.font = UIFont (name: "Arial Rounded MT Bold", size: 16)
            TITLELABEL.adjustsFontSizeToFitWidth     = true
            TITLELABEL.textAlignment = NSTextAlignment.right
            self.navigationItem.titleView = TITLELABEL
            let uid = Auth.auth().currentUser?.uid
            
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionaryUser = snapshot.value as? [String : AnyObject]{
                    TITLELABEL.text = dictionaryUser["name"] as? String
                    
                }
                
            }, withCancel: nil)
            
        }
        
    }

   
    @IBAction func createPartyButton(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "createParty", sender: nil)
    }

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        navigationItem.backBarButtonItem = backItem
        
        if segue.identifier == "createParty"{
            
            
        }else if segue.identifier   == "viewGuest"{
                let viewGuestController = segue.destination  as! ViewGuestController
                viewGuestController.selectedEvent = self.selectedEvent
        }
        
    }
    // MARK: - UITableViewDelegate/DataSource methods
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PartyTableViewCell", for: indexPath) as! PartyTableViewCell
        
        let event = self.events[indexPath.row]
        let uid = Auth.auth().currentUser?.uid
        cell.configureWithEvent(user: uid!, event: event)
        //cell.layoutSubviews()
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        selectedEvent = self.events[indexPath.row]
                    if self.eventOwner == true {
                        performSegue(withIdentifier: "viewGuest", sender: nil)
                    }else{
                        performSegue(withIdentifier: "viewGuest", sender: nil)
                    }
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    
    
}
 
