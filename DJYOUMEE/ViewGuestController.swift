//
//  ViewController.swift
//

import UIKit
import StoreKit
import MessageUI
import Firebase
import Contacts
import UserNotifications

extension ViewGuestController :UNUserNotificationCenterDelegate{
    func notificationCheck()  {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.alertSetting != UNNotificationSetting.enabled{
                self.showSettingsAlert()
            }
        }
    }
    
    func showSettingsAlert() {
        
        let alertController = UIAlertController(title: "DJyouMEE", message: "Turn on Notifications to receive alerts, when you are invited for an Event", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Settings", style: .default) { (action:UIAlertAction) in
            guard let url = URL(string:  UIApplicationOpenSettingsURLString) else {
                return //be safe
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        let action2 = UIAlertAction(title: "Dismiss", style: .default) { (action:UIAlertAction) in
        }
        alertController.addAction(action2)
        alertController.addAction(action1)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
}
class ViewGuestController: UIViewController,UITableViewDataSource, UITableViewDelegate,SKStoreProductViewControllerDelegate {
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = orangeColor
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refreshControl
    }()
    @objc func handleRefresh( refreshControl : UIRefreshControl){
        self.fetchInvitedUsers()
        refreshControl.endRefreshing()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ViewGuestTableViewCell", for: indexPath) as! ViewGuestTableViewCell
        let user = self.users[indexPath.row]
        if (self.selectedEvent?.owner == Auth.auth().currentUser?.uid) {
            cell.configureWithUser(user: user, event: self.selectedEvent!)
            return cell
        }else{
            cell.configureWithUser(user: user, event: self.selectedEvent!)
            return cell
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return  60
    }
    // outlets
    
    @IBAction func addGuestButtonClicked(_ sender: Any) {
        if Auth.auth().currentUser?.uid != nil{
            let currentUser  = Auth.auth().currentUser!.uid
            if(selectedEvent?.owner == currentUser){
                self.performSegue(withIdentifier: "addGuestView", sender: self)
            }else{
                let alertViewController = UIAlertController.init(title: "", message: "", preferredStyle: .actionSheet)
                let attributedTitle = NSMutableAttributedString(string: "DJyouMEE"    , attributes: [NSAttributedStringKey.font : UIFont(name: "Arial", size: 16.0)!])
                let attributedMessage = NSMutableAttributedString(string: "Create a Party & invite your Friends"    , attributes: [NSAttributedStringKey.font : UIFont(name: "Arial", size: 14.0)!])
                alertViewController.setValue(attributedTitle, forKey: "attributedTitle")
                alertViewController.setValue(attributedMessage, forKey: "attributedMessage")
                let notNowButton = UIAlertAction(title: "OK Got it!", style: .default) { (action) in
                    
                }
                alertViewController.view.backgroundColor = titleColor
                alertViewController.addAction(notNowButton)
                self.navigationController?.present(alertViewController,animated: true,completion:nil)
            }
        }
    }
    @IBOutlet weak var createPartyButton: UIButton!
    @IBOutlet weak var partyNameTextField: UITextField!
    @IBOutlet weak var placeTextField: UITextField!
    @IBOutlet weak var partyStartDateTimeTextField: UITextField!
    @IBOutlet weak var partyEndDateTimeTextField: UITextField!
    @IBOutlet weak var peopleTableView: UITableView!
    @IBOutlet weak var guestListLabel: UILabel!
    @IBOutlet weak var attendeesNumberLabel: UILabel!
    @IBOutlet weak var savePartyButton: UIButton!
    @IBOutlet weak var editPartyButton: UIButton!
    @IBOutlet weak var addGuestButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    var refEvent: DatabaseReference!
    var refUser : DatabaseReference!
    var eventHandle : UInt!
    var userHandle : UInt!
    var acceptedUser : Bool?
    var partyStartTime : Date?
    var partyEndTime : Date?
    let picker = UIDatePicker()
    var events = [Event]()
    var eventOwner : Bool = false
    var users = [User]()
    var contacts = [Contact]()
    var contactsM = [Contact]()
    var selectedEvent: Event?
    var selectedEventKey : String = ""
    let party = partyDate()
    @IBAction func secondButtonClicked(_ sender: Any) { // savePartyButtonClicked
        
        if Auth.auth().currentUser?.uid != nil{
            let currentUser  = Auth.auth().currentUser!.uid
            if(self.selectedEvent?.owner == currentUser  )
            {
                if (self.partyNameTextField.text != "" && self.placeTextField.text != "" && self.partyStartDateTimeTextField.text != "" && self.partyEndDateTimeTextField.text != "")
                {
                    saveParty()
                }
                self.navigationController?.popViewController(animated: true)
            }
            else
            {
                DispatchQueue.main.async {
                    self.acceptInvite()
                }
                self.acceptedUser = true
                self.performSegue(withIdentifier: "showPlaylist", sender: self)
            }
        }
    }
    func acceptInvite(){
        if Auth.auth().currentUser?.uid != nil{
            let currentUser  = Auth.auth().currentUser
            let dbRef =   Database.database().reference()
            let invitedEventRef =   dbRef.child("event").child((self.selectedEvent?.uid)!).child("acceptedUsers").child((currentUser?.uid)!)
            let keyEvent = invitedEventRef.key
            let childUpdates = ["/event/\((self.selectedEvent?.uid)!)/acceptedUsers/\(keyEvent!)/": Bool(true)]
            dbRef.updateChildValues(childUpdates)
            
        }
        setComponentsForUser()
        
    }
    @IBAction func firstButtonClicked(_ sender: Any) {   //  Edit button Clicked
        if Auth.auth().currentUser?.uid != nil{
            let currentUser  = Auth.auth().currentUser!.uid
            if(self.selectedEvent?.owner == currentUser  )
            {
                party.partyStartDate = (self.selectedEvent?.partyDate)!
                setComponentsForOwnerReadyToEdit()
            }
            else
            {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func saveParty(){
        
        let refEvent =  Database.database().reference().child("event/\((selectedEvent?.uid)!)")
        let author = Auth.auth().currentUser?.uid
        let values = ["eventName": partyNameTextField.text!,"eventPlace":placeTextField.text!,"startTimeStamp":partyStartDateTimeTextField.text!,"endTimeStamp":partyEndDateTimeTextField.text!,"owner":author!,"partyDate" : party.partyStartDate ,"partyDateEnd" : party.partyEndDate,"acceptedUsers" : selectedEvent?.acceptedUsers as Any,"invitedUsers" : selectedEvent?.invitedUsers as Any] as [String : Any]
        
        refEvent.setValue(values) { (err, ref) in
            if (err != nil) {
                print("error updating",err?.localizedDescription as Any)
                return
            }else
            {
                self.setComponentsForOwner()
            }
        }
    }
    
    @IBAction func createDatePickerIsEnabled(_ sender: Any) {
        editStartDatePicker()
    }
    @IBAction func removeKeyPad(_ sender: Any) {
        partyNameTextField.resignFirstResponder()
        partyStartDateTimeTextField.resignFirstResponder()
        partyEndDateTimeTextField.resignFirstResponder()
        placeTextField.resignFirstResponder()
    }
    

    
    @IBAction func editStartDatePicker(){
    
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        let partyFormatter = DateFormatter()
        partyFormatter.dateFormat = "MM/dd/yyyy"
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(donePressed))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [space,space,space,space,done]
        toolbar.tintColor = titleColor
        toolbar.backgroundColor = buttonColor
        picker.backgroundColor = UIColor.white
        picker.tintColor = titleColor
        picker.datePickerMode = .dateAndTime
        let secondsInMonth: TimeInterval = 365 * 24 * 60 * 60
        if (partyStartDateTimeTextField.isFirstResponder){
            picker.maximumDate = Date(timeInterval: secondsInMonth, since: NSDate() as Date)
            picker.date = formatter.date(from: String(self.selectedEvent!.startTimeStamp))!
            picker.minimumDate = NSDate() as Date
        }
        
        partyStartDateTimeTextField.inputAccessoryView = toolbar
        partyStartDateTimeTextField.inputView = picker
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0.5
            self.savePartyButton.isUserInteractionEnabled = false
            self.savePartyButton.setTitleColor(buttonColor, for: .normal)
        })
        
    }
    
    @IBAction func editEndDatePicker(){
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        let partyFormatter = DateFormatter()
        partyFormatter.dateFormat = "MM/dd/yyyy"
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(donePressed))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [space,space,space,space,done]
        toolbar.tintColor = titleColor
        toolbar.backgroundColor = buttonColor
        picker.backgroundColor = UIColor.white
        picker.datePickerMode = .dateAndTime
        
        if (partyEndDateTimeTextField.isFirstResponder){
            
            let secondsInMonth: TimeInterval = 365 * 24 * 60 * 60
            let secondsInPartyEndTime: TimeInterval = 1 * 4 * 60 * 60
            picker.maximumDate = Date(timeInterval: secondsInMonth, since: NSDate() as Date)
            if (self.partyStartTime != nil) {
                picker.date = Date(timeInterval: secondsInPartyEndTime, since: self.partyStartTime! )
                picker.minimumDate = self.partyStartTime  }
            else{
                picker.date = formatter.date(from: String(self.selectedEvent!.endTimeStamp))!
                picker.minimumDate = NSDate() as Date
                picker.maximumDate = Date(timeInterval: secondsInMonth, since: NSDate() as Date)
                
            }
        }
        partyEndDateTimeTextField.inputAccessoryView = toolbar
        partyEndDateTimeTextField.inputView = picker
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0.5
            self.savePartyButton.isUserInteractionEnabled = false
            self.savePartyButton.setTitleColor(buttonColor, for: .normal)
        })
        
    }
    
    @objc func donePressed(){
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        let partyFormatter = DateFormatter()
        partyFormatter.dateFormat = "MM/dd/yyyy"
        let dateString = formatter.string(from: picker.date)
        
        if( partyStartDateTimeTextField.isFirstResponder   ) {
            partyStartDateTimeTextField.text = "\(dateString)"
            party.partyStartDate = partyFormatter.string(from: picker.date)
            self.partyStartTime = picker.date
            
            let secondsInPartyEndTime: TimeInterval = 1 * 4 * 60 * 60
            picker.date = Date(timeInterval: secondsInPartyEndTime, since: self.partyStartTime! )
            let endPickerDate = Date(timeInterval: secondsInPartyEndTime, since: self.partyStartTime! )
            partyEndDateTimeTextField.text = formatter.string(from: endPickerDate)
            party.partyEndDate = partyFormatter.string(from: endPickerDate)
           
            
        }
        else if( partyEndDateTimeTextField.isFirstResponder ){
            let partyStartDate = partyFormatter.date(from: party.partyStartDate)
            picker.minimumDate = partyStartDate
            partyEndDateTimeTextField.text = "\(dateString)"
            self.partyEndTime = picker.date
            // MARK: - party date : default changed
            //let secondsInPartyEndTime: TimeInterval = -1 * 4 * 60 * 60
           // picker.date = Date(timeInterval: secondsInPartyEndTime, since: self.partyEndTime! )
           // let startPickerDate = Date(timeInterval: secondsInPartyEndTime, since: self.partyEndTime! )
           // partyStartDateTimeTextField.text = formatter.string(from: startPickerDate)
           // party.partyEndDate = partyFormatter.string(from: picker.date)
            
            party.partyEndDate = partyFormatter.string(from: picker.date)
            
        }
        self.view.endEditing(true)
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 1.0
            self.savePartyButton.isUserInteractionEnabled = true
            self.savePartyButton.setTitleColor(titleColor, for: .normal)
        })
        
    }
    func fetchAttendees(){
        
        if  ((self.selectedEvent?.invitedUsers) != nil){
            self.attendeesNumberLabel.text = "\(String(describing: self.selectedEvent!.acceptedUsers.count)) / \(String(describing: self.selectedEvent!.invitedUsers.count - 1))"
        }
        
    }
 
    
    func fetchParty(){
        let eventRef  = Database.database().reference().child("event")
        eventRef.queryOrdered(byChild: "\(self.selectedEvent!.uid)").observe(.childChanged) { (snapshot) in
            if let eventDictionary  = snapshot.value as? [String : AnyObject]{
                let event = Event()
                event.setValuesForKeys(eventDictionary)
                event.uid = snapshot.key
                if event.uid == self.selectedEvent!.uid {
                   
                    self.selectedEvent = event
                }
            }
        }
    }
    
    @objc func fetchInvitedUsers(){
        self.users.removeAll()
        self.contactsM.removeAll()
        let userDictionary : Dictionary = selectedEvent!.invitedUsers as Dictionary
        let userRef =    Database.database().reference().child("users")
        for key in userDictionary{
            userRef.child(key.key).observeSingleEvent(of: .value) { (snapshot) in
                if let dictionaryUsers = snapshot.value  as? [String : AnyObject] {
                    let user  = User()
                    user .setValuesForKeys(dictionaryUsers)
                    user.uid = snapshot.key
                    if (user.uid != self.selectedEvent?.owner){
                        self.users.append(user)
                        
                    }else{
                        self.navigationItem.rightBarButtonItem?.title =  user.name
                        
                        self.navigationItem.rightBarButtonItem?.width = 90
                        self.navigationItem.rightBarButtonItem?.setTitleTextAttributes( [NSAttributedStringKey.font : UIFont(name: "Arial Rounded MT Bold", size: 16)!], for: .normal)
                        
                    }
                    DispatchQueue.main.async {
                        self.peopleTableView.reloadData()
                        
                    }
                }
            }
        }
        
    }
    func fetchInvitedContacts(){
        self.users.removeAll()
        self.contactsM.removeAll()
        let userDictionary : Dictionary = selectedEvent!.invitedUsers as Dictionary
        let userRef =    Database.database().reference().child("users")
        for key in userDictionary{
            userRef.child(key.key).observeSingleEvent(of: .value) { (snapshot) in
                if let dictionaryUsers = snapshot.value  as? [String : AnyObject] {
                    let user  = User()
                    user .setValuesForKeys(dictionaryUsers)
                    user.uid = snapshot.key
                    if (user.uid != self.selectedEvent?.owner){
                        self.users.append(user)
                        // self.contactsM.append(contact)
                    }
                    DispatchQueue.main.async {
                        self.peopleTableView.reloadData()
                    }
                }
            }
        }
        
    }
    
    
    func setComponentsForUser(){
        editPartyButton.setTitle(NSLocalizedString("Decline", comment: ""), for: .normal)
        savePartyButton.setTitle(NSLocalizedString("Accept", comment: ""), for: .normal)
        
        partyNameTextField . text = self.selectedEvent?.eventName
        partyNameTextField.isUserInteractionEnabled = false
        partyNameTextField.textColor = titleColor
        
        placeTextField.text = selectedEvent?.eventPlace
        placeTextField.isUserInteractionEnabled = false
        placeTextField.textColor = titleColor
        
        partyStartDateTimeTextField.text  = selectedEvent?.startTimeStamp
        partyStartDateTimeTextField.isUserInteractionEnabled = false
        partyStartDateTimeTextField.textColor = titleColor
        
        partyEndDateTimeTextField.text = selectedEvent?.endTimeStamp
        partyEndDateTimeTextField.textColor = titleColor
        partyEndDateTimeTextField.isUserInteractionEnabled = false
        
        if    let currentUser = Auth.auth().currentUser?.uid {
            let userDictionary : Dictionary = selectedEvent!.acceptedUsers as Dictionary
            for key in userDictionary{
                if (key.key == currentUser){
                    self.acceptedUser = true
                    editPartyButton.isUserInteractionEnabled = false
                    savePartyButton.isUserInteractionEnabled = false
                    savePartyButton.setTitleColor(buttonColor, for: .normal)
                    editPartyButton.setTitleColor(buttonColor, for: .normal)
                    editPartyButton.isUserInteractionEnabled = false
                    return
                }else{
                    savePartyButton.isUserInteractionEnabled = true
                    savePartyButton.setTitleColor(titleColor, for: .normal)
                    editPartyButton.isUserInteractionEnabled = true
                    editPartyButton.setTitleColor(titleColor, for: .normal)
                    
                }
            }
        }
    }
    
    func setComponentsEditable(){
        partyNameTextField . text = self.selectedEvent?.eventName
        partyNameTextField.textColor = titleColor
        placeTextField.text = selectedEvent?.eventPlace
        placeTextField.textColor = titleColor
        partyStartDateTimeTextField.text  = selectedEvent?.startTimeStamp
        partyStartDateTimeTextField.textColor = titleColor
        partyEndDateTimeTextField.text = selectedEvent?.endTimeStamp
        partyEndDateTimeTextField.textColor = titleColor
    
        editPartyButton.isUserInteractionEnabled    = true
        savePartyButton.isUserInteractionEnabled = true
        
        savePartyButton.setTitleColor(titleColor, for: .normal)
        partyNameTextField.isUserInteractionEnabled = true
        placeTextField.isUserInteractionEnabled = true
        partyStartDateTimeTextField.isUserInteractionEnabled = true
        partyEndDateTimeTextField.isUserInteractionEnabled = true
        
    }
    func setComponentsForOwner(){
        editPartyButton.setTitle(NSLocalizedString("Edit", comment: ""), for: .normal)
        savePartyButton.setTitle(NSLocalizedString("Save", comment: ""), for: .normal)
        editPartyButton.isUserInteractionEnabled = true
        
        partyNameTextField . text = self.selectedEvent?.eventName
        partyNameTextField.isUserInteractionEnabled = false
        partyNameTextField.textColor = titleColor
        
        placeTextField.text = selectedEvent?.eventPlace
        placeTextField.isUserInteractionEnabled = false
        placeTextField.textColor = titleColor
        
        partyStartDateTimeTextField.text  = selectedEvent?.startTimeStamp
        partyStartDateTimeTextField.isUserInteractionEnabled = false
        partyStartDateTimeTextField.textColor = titleColor
        
        partyEndDateTimeTextField.text = selectedEvent?.endTimeStamp
        partyEndDateTimeTextField.textColor = titleColor
        partyEndDateTimeTextField.isUserInteractionEnabled = false
        
        savePartyButton.isUserInteractionEnabled = false
        savePartyButton.setTitleColor(buttonColor, for: .normal)
        editPartyButton.isUserInteractionEnabled = true
        editPartyButton.setTitleColor(titleColor, for: .normal)
        
    }
    
    func setComponentsForOwnerReadyToEdit(){
        
        editPartyButton.isUserInteractionEnabled = false
        savePartyButton.isUserInteractionEnabled = true
        
        partyNameTextField . text = self.selectedEvent?.eventName
        partyNameTextField.isUserInteractionEnabled = true
        partyNameTextField.textColor = titleColor
        
        placeTextField.text = selectedEvent?.eventPlace
        placeTextField.isUserInteractionEnabled = true
        placeTextField.textColor = titleColor
        
        partyStartDateTimeTextField.text  = selectedEvent?.startTimeStamp
        partyStartDateTimeTextField.isUserInteractionEnabled = true
        partyStartDateTimeTextField.textColor = titleColor
        
        partyEndDateTimeTextField.text = selectedEvent?.endTimeStamp
        partyEndDateTimeTextField.textColor = titleColor
        partyEndDateTimeTextField.isUserInteractionEnabled = true
        
        savePartyButton.setTitleColor(titleColor, for: .normal)
        editPartyButton.setTitleColor(buttonColor, for: .normal)
        partyNameTextField.becomeFirstResponder()
        
    }
    
    @objc func handleLogOut(){
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        refEvent.removeObserver(withHandle: eventHandle)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.fetchParty()
            self.fetchInvitedUsers()
            self.fetchAttendees()
        }
        
        refUser = Database.database().reference().child("user")
        refEvent  = Database.database().reference().child("event/\(selectedEvent!.uid)")
        eventHandle =   refEvent.observe(.childChanged) { (snapshot) in
            self.fetchParty()
            
        }
        self.peopleTableView.refreshControl = refreshControl
        let TITLELABEL : UILabel = UILabel(frame: CGRect.zero)
        TITLELABEL.backgroundColor = UIColor.clear
        TITLELABEL.text =   "\(self.selectedEvent!.eventName)"
        TITLELABEL.textColor = titleColor
        TITLELABEL.font = UIFont (name: "Arial Rounded MT Bold", size: 16)
        TITLELABEL.adjustsFontSizeToFitWidth     = true
        TITLELABEL.textAlignment = NSTextAlignment.left
        TITLELABEL.widthAnchor.constraint(equalToConstant: self.view.frame.width/1.8).isActive = true
        TITLELABEL.contentMode = .scaleAspectFit
        peopleTableView.register(UINib(nibName: "ViewGuestTableViewCell", bundle: nil), forCellReuseIdentifier: "ViewGuestTableViewCell")
        self.navigationItem.titleView = TITLELABEL
        self.nextButton.layer.cornerRadius = 5.0
        self.guestListLabel.layer.cornerRadius = 5.0
        self.guestListLabel.layer.masksToBounds = true
        guestListLabel.text = "   " + "Guests"
        
    }
    override func viewDidAppear(_ animated: Bool) {
        //self.notificationCheck()
        if Auth.auth().currentUser?.uid != nil{
            let currentUser  = Auth.auth().currentUser!.uid
            self.fetchInvitedUsers()
            self.fetchAttendees()
            if(self.selectedEvent?.owner == currentUser  )
            {
                self.addGuestButton.isUserInteractionEnabled = true
                self.addGuestButton.setBackgroundImage(#imageLiteral(resourceName: "addGuestOrangeImage"), for: .normal)
                self.addGuestButton.alpha = 1.0
                setComponentsForOwner()
            }
            else
            {
                self.addGuestButton.isUserInteractionEnabled = false
                self.addGuestButton.setBackgroundImage(#imageLiteral(resourceName: "guestBrownImage"), for: .normal)
                self.addGuestButton.alpha = 1.0
                setComponentsForUser()
            }
            
        }
    }
    
    
    // MARK: - Navigation
    @IBAction func unwindViewGuest(segue:UIStoryboardSegue){
        
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        navigationItem.backBarButtonItem = backItem
        if segue.identifier   == "addGuestView"{
            let  addGuestController = segue.destination as! AddGuestViewController
            addGuestController.selectedEvent  = self.selectedEvent
            
        }
        if segue.identifier   == "showPlaylist"{
            let  viewPlaylistController = segue.destination as! ViewPlaylistController
            viewPlaylistController.selectedEvent  = self.selectedEvent
            viewPlaylistController.acceptedUser = self.acceptedUser
        }
        
    }
    
}



