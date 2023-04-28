//
//  ViewController.swift
//

import UIKit
import StoreKit
import MessageUI
import Firebase

class CreatePartyController: UIViewController,SKStoreProductViewControllerDelegate {
    // outlets
   
    @IBOutlet weak var createPartyButton: UIButton!
    @IBOutlet weak var partyNameTextField: UITextField!
    @IBOutlet weak var placeTextField: UITextField!
    @IBOutlet weak var partyStartDateTimeTextField: UITextField!
    @IBOutlet weak var partyEndDateTimeTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    
    let pickerStart = UIDatePicker()
    let pickerEnd = UIDatePicker()
    var events = [Event]()
    var eventOwner : Bool = false
    var users = [User]()
    let party = partyDate()
    var partyStartTime : Date?
    var currentUserId :  String?
    var currentUser :  User?

 
    
    @IBAction func createDatePickerIsEnabled(_ sender: Any) {
        createDatePicker()
    }
    @IBAction func removeKeyPad(_ sender: Any) {
        partyNameTextField.resignFirstResponder()
        partyStartDateTimeTextField.resignFirstResponder()
        partyEndDateTimeTextField.resignFirstResponder()
        placeTextField.resignFirstResponder()
        self.partyStartDateTimeTextField.isUserInteractionEnabled = true
        self.partyEndDateTimeTextField.isUserInteractionEnabled = true
    }
    
    @IBAction func savePartyButtonClicked(_ sender: Any) {
        if (self.partyNameTextField.text != ""  && self.placeTextField.text != "" && self.partyStartDateTimeTextField.text != "" && self.partyEndDateTimeTextField.text != "") {
            DispatchQueue.main.async {
            self.handleCreateParty()
            }
          
        }else{
            let alertControllerFail = UIAlertController(title: "DJyouMEE", message: "Enter values for all Fields ", preferredStyle: .alert)
            let action2 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                print("You've pressed cancel");
            }
            alertControllerFail.addAction(action2)
            self.present(alertControllerFail, animated: true, completion: nil)
        }
        let alertControllerSucces = UIAlertController(title: "Your party is created", message: "Select your party and invite friends", preferredStyle: .alert)
        let action2 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            self.navigationController?.popViewController(animated: true)
        }
            alertControllerSucces.addAction(action2)
            self.present(alertControllerSucces, animated: true, completion: nil)
        }
       
    func createDatePicker()
    {
        
        let partyFormatter = DateFormatter()
        partyFormatter.dateFormat = "MM/dd/yyyy"
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(donePressed))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [space,space,space,space,done]
        toolbar.tintColor = titleColor
        toolbar.backgroundColor = UIColor.white
        pickerStart.backgroundColor = UIColor.white
        pickerStart.datePickerMode = .dateAndTime
        pickerEnd.backgroundColor = UIColor.white
        pickerEnd.datePickerMode = .dateAndTime
        let secondsIn3Month: TimeInterval = 365 * 24 * 60 * 60  // The maximum Party date is changed to 365 days
        pickerStart.maximumDate = Date(timeInterval: secondsIn3Month, since: NSDate() as Date)
        pickerStart.minimumDate = Date()
        let secondsInPartyEndTime: TimeInterval = 1 * 4 * 60 * 60
        pickerEnd.maximumDate = Date(timeInterval: secondsIn3Month, since: NSDate() as Date)
       
        
        if (partyStartDateTimeTextField.isFirstResponder){
            partyEndDateTimeTextField.isUserInteractionEnabled = false
            
            
        }else if (partyEndDateTimeTextField.isFirstResponder){
            partyStartDateTimeTextField.isUserInteractionEnabled = false
            
            if (self.partyStartTime != nil) {
                pickerEnd.date = Date(timeInterval: secondsInPartyEndTime, since: self.partyStartTime!  )
                pickerEnd.minimumDate =  Date(timeInterval: 0, since: self.partyStartTime!  )
            }else{
                
                pickerEnd.minimumDate =  Date()
            }//partyStartDate
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        partyStartDateTimeTextField.inputAccessoryView = toolbar
        partyStartDateTimeTextField.inputView = pickerStart
        partyEndDateTimeTextField.inputAccessoryView = toolbar
        partyEndDateTimeTextField.inputView = pickerEnd
    }
    
    @objc func donePressed(){
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        let partyFormatter = DateFormatter()
        partyFormatter.dateFormat = "MM/dd/yyyy"
        if( partyStartDateTimeTextField.isFirstResponder   ) {
            let dateString = formatter.string(from: pickerStart.date)
            partyStartDateTimeTextField.text = "\(dateString)"
            party.partyStartDate = partyFormatter.string(from: pickerStart.date)
            self.partyStartTime = pickerStart.date
        }
        else if( partyEndDateTimeTextField.isFirstResponder && self.partyStartTime != nil){
            let dateString = formatter.string(from: pickerEnd.date)
            let partyStartDate = partyFormatter.date(from: party.partyStartDate)
            pickerEnd.minimumDate = partyStartDate
            partyEndDateTimeTextField.text = "\(dateString)"
            party.partyEndDate = partyFormatter.string(from: pickerEnd.date)
        }else{
            self.partyEndDateTimeTextField.resignFirstResponder()
            let alertControllerFail = UIAlertController(title: "DJyouMEE", message: "Select a start date & time for your Party/Event", preferredStyle: .alert)
            let action2 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                self.partyStartDateTimeTextField.becomeFirstResponder()
            }
            alertControllerFail.addAction(action2)
            self.present(alertControllerFail, animated: true, completion: nil)
        }
        self.partyStartDateTimeTextField.isUserInteractionEnabled = true
        self.partyEndDateTimeTextField.isUserInteractionEnabled = true
        self.view.alpha = 1.0
        self.view.endEditing(true)
    }
    
  
    @objc func handleLogOut(){
        self.dismiss(animated: true, completion: nil)
        
    }
    // MARK: - New Party created with firebase
    @objc func handleCreateParty(){
        if Auth.auth().currentUser?.uid == nil{
            perform(#selector(handleLogOut), with: nil, afterDelay: 0)
        }else{
            let uid = Auth.auth().currentUser?.uid
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String : AnyObject]{
                    self.navigationItem.title = dictionary["name"] as? String
                }
            }, withCancel: nil)
        }
        let refEvent =  Database.database().reference().child("event")
        let childRef = refEvent.childByAutoId()
        let author = Auth.auth().currentUser?.uid
        let newEventKey = childRef.key
        let values = ["eventName": partyNameTextField.text!,"eventPlace":placeTextField.text!,"startTimeStamp":partyStartDateTimeTextField.text!,"endTimeStamp":partyEndDateTimeTextField.text!,"owner":author! ,"invitedUsers":[String : Any]() ,"acceptedUsers":[String : Any](),"partyDate" : party.partyStartDate ,"partyDateEnd" : party.partyEndDate] as [String : Any]  //  note : // partyDate is changed to partyStartDate
    
        
        childRef.updateChildValues(values) { (error, db) in
            print("Error in create Event : \(String(describing: error?.localizedDescription))")
        }
        let eventUpdates = ["/users/\((author)!)/eventIds/\(newEventKey!)/": Bool(),"/event/\(newEventKey!)/invitedUsers/\((author)!)/": Bool()]
        Database.database().reference().updateChildValues(eventUpdates)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let TITLELABEL : UILabel = UILabel(frame: CGRect.zero)
        TITLELABEL.frame = CGRect(x: 50, y: 0, width: 250, height: 40) as CGRect
        TITLELABEL.backgroundColor = UIColor.clear
        TITLELABEL.text = "Create a New Event"
        TITLELABEL.textColor = titleColor
        TITLELABEL.font = UIFont (name: "Arial Rounded MT Bold", size: 16)
        TITLELABEL.adjustsFontSizeToFitWidth     = true
        TITLELABEL.textAlignment = NSTextAlignment.left
        self.navigationItem.titleView = TITLELABEL
        nextButton.layer.cornerRadius = 5.0
      
    }
    override func viewDidAppear(_ animated: Bool) {
    partyNameTextField.becomeFirstResponder()
      
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        navigationItem.backBarButtonItem = backItem
        //   segue.destination
        
    }
    // MARK: - UITableViewDelegate/DataSource methods
    

    
}



