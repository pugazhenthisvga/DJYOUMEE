//
//  OTPViewController.swift
//  jukeBox1.4
//
//  Created by PUGAZHENTHI VENKATACHALAM on 15/06/18.
//  Copyright © 2018 PUGAZHENTHI VENKATACHALAM. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging

class OTPViewController: UIViewController,UITextFieldDelegate {

     let ref = Database.database().reference(fromURL: "https://djyoumee-e37cc.firebaseio.com/")// DJyouMEE https://djyoumee-e37cc.firebaseio.com/
    
    @IBOutlet weak var textOTP1: UITextField!
    @IBOutlet weak var textOTP2: UITextField!
    @IBOutlet weak var textOTP3: UITextField!
    @IBOutlet weak var textOTP4: UITextField!
    @IBOutlet weak var textOTP5: UITextField!
    @IBOutlet weak var textOTP6: UITextField!
    @IBOutlet weak var OTPbackView: UIView!
    @IBOutlet weak var submitButton: UIButton!
    var signInMode : String  = ""
    var verificationID : String = ""
    var verificationCode : String = ""
    var name : String = ""
    var email : String = ""
    var phone : String = ""
    var mobileNumber : String = ""
    func viewDidAppear() {
        
        self.textOTP1.becomeFirstResponder()
    }
    @IBAction func handlePhoneLogin(_ sender: Any) {
        print("the opted Sign in Methods : \(self.signInMode)")
        if (self.signInMode == "register"){
            self.handleRegister()
        }else{
            self.handleLogin()
        }
    }

    
    func handleLogin(){
        let defaults = UserDefaults.standard
        verificationID = defaults.string(forKey: "phoneAuthVerificationID")!
        verificationCode = textOTP1.text! + textOTP2.text! + textOTP3.text! + textOTP4.text! + textOTP5.text! + textOTP6.text!
        let credential : PhoneAuthCredential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        submitButton.isUserInteractionEnabled = false
        Auth.auth().signInAndRetrieveData(with: credential) { (authDataResult: AuthDataResult?, error) in
            if let error = error{
                self.handleClearOTP()
                self.sendVerificationNumberErrorAlert(error: error.localizedDescription   )
                self.submitButton.isUserInteractionEnabled = true
                return
                
            }else{
                guard  let UID  = authDataResult?.user.uid else  {
                    self.submitButton.isUserInteractionEnabled = true
                    return
                }
                print("UID : \(UID,authDataResult?.user.uid)")
                print("Messaging.messaging().fcmToken : \(Messaging.messaging().fcmToken!)")
                let refCurrentUser = self.ref.child("users").child(UID).child("fcmToken")
                refCurrentUser.setValue(Messaging.messaging().fcmToken!)
                
                let viewController =    self.storyboard?.instantiateViewController(withIdentifier:"ViewController")
                let navController = UINavigationController(rootViewController: viewController!)
                self.submitButton.isUserInteractionEnabled = true
                self.present(navController, animated:true, completion: nil)
            }
        }
    }
 
    func handleRegister(){
        let defaults = UserDefaults.standard
        verificationID = defaults.string(forKey: "phoneAuthVerificationID")!
        verificationCode = textOTP1.text! + textOTP2.text! + textOTP3.text! + textOTP4.text! + textOTP5.text! + textOTP6.text!
        let credential : PhoneAuthCredential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        submitButton.isUserInteractionEnabled = false
        Auth.auth().signInAndRetrieveData(with: credential) { (authDataResult: AuthDataResult?, error) in
            if let error = error{
                print("verification failed : \(error.localizedDescription  )")
                self.sendPhoneNumberErrorAlert(error: error.localizedDescription   )
                self.submitButton.isUserInteractionEnabled = true
                return
            }else{
                guard  let UID  = authDataResult?.user.uid else{
                    return
                }
                let userInfo = authDataResult?.user.providerData[0]
                print("Phone number : \(String(describing: userInfo?.phoneNumber))")
                print("Provider Id : \(String(describing: userInfo?.providerID))")
                print("UID : \(UID,authDataResult?.user.uid)")
                
                let usersReference = self.ref.child("users").child(UID)
                let values = ["name":self.name,"email":self.email,"phoneNumber" : self.phone,"fcmToken": Messaging.messaging().fcmToken! ] as [String : Any]
                usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
                    if(err != nil){
                        print(err as Any)
                        return
                    }
                    let viewController =    self.storyboard?.instantiateViewController(withIdentifier:"ViewController")
                    let navController = UINavigationController(rootViewController: viewController!)
                    self.submitButton.isUserInteractionEnabled = true
                    self.present(navController, animated:true, completion: nil)
                    
                })
                // self.postToken(Token: token)
            }
        }
    }
    
    func postToken(Token :[String : AnyObject]){
        print("fcm Token : \(Token)")
        let ref = Database.database().reference()
        ref.child("fcmToken").child(Messaging.messaging().fcmToken!).setValue(Token)
        
        
    }
    @IBOutlet weak var resendOTPButton: UIButton!
   
    override func viewDidLoad(){
        super.viewDidLoad()
        submitButton.layer.cornerRadius = 5.0
        textOTP1.delegate = self
        textOTP2.delegate = self
        textOTP3.delegate = self
        textOTP4.delegate = self
        textOTP5.delegate = self
        textOTP6.delegate = self
        
        textOTP1.backgroundColor = UIColor.clear
        textOTP2.backgroundColor = UIColor.clear
        textOTP3.backgroundColor = UIColor.clear
        textOTP4.backgroundColor = UIColor.clear
        textOTP5.backgroundColor = UIColor.clear
        textOTP6.backgroundColor = UIColor.clear
        
        addBottomBorder(textField: textOTP1)
        addBottomBorder(textField: textOTP2)
        addBottomBorder(textField: textOTP3)
        addBottomBorder(textField: textOTP4)
        addBottomBorder(textField: textOTP5)
        addBottomBorder(textField: textOTP6)
        OTPbackView.backgroundColor = UIColor.clear
        self.textOTP1.becomeFirstResponder()
        resendOTPButton.addTarget(self, action: #selector(handleResendOTP), for: .touchUpInside)
        
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if ((textField.text?.count)!  < 1) && (string.count > 0){
            if textField == textOTP1 {
                textOTP2.becomeFirstResponder()
                addBottomBorderBlack(textField: textOTP1)
            }
            if textField == textOTP2 {
                textOTP3.becomeFirstResponder()
                addBottomBorderBlack(textField: textOTP2)
            }
            if textField == textOTP3 {
                textOTP4.becomeFirstResponder()
                addBottomBorderBlack(textField: textOTP3)
            }
            if textField == textOTP4 {
                textOTP5.becomeFirstResponder()
                addBottomBorderBlack(textField: textOTP4)
            }
            if textField == textOTP5 {
                textOTP6.becomeFirstResponder()
                addBottomBorderBlack(textField: textOTP5)
            }
            if textField == textOTP6 {
                textOTP6.resignFirstResponder()
                addBottomBorderBlack(textField: textOTP6)
            }
            print("false : \(string)")
            textField.text = string
            return false
            
        }else  if ((textField.text?.count)!  >= 1) && (string.count == 0){
            if textField == textOTP2 {
                textOTP1.becomeFirstResponder()
                addBottomBorder(textField: textOTP2)
            }
            if textField == textOTP3 {
                textOTP2.becomeFirstResponder()
                addBottomBorder(textField: textOTP3)
            }
            if textField == textOTP4 {
                textOTP3.becomeFirstResponder()
                addBottomBorder(textField: textOTP4)
            }
            if textField == textOTP5 {
                textOTP4.becomeFirstResponder()
                addBottomBorder(textField: textOTP5)
            }
            if textField == textOTP6 {
                textOTP5.becomeFirstResponder()
                addBottomBorder(textField: textOTP6)
            }
            if textField == textOTP1 {
                textOTP1.resignFirstResponder()
                addBottomBorder(textField: textOTP1)
            }
            textField.text = ""
            return false
        } else if (textField.text?.count)! >= 1{
            textField.text = string
            print("true : \(string)")
            return false
        }
        print("true 3: \(string)")
        return true
    }
    @objc func handleResendOTP(){
        PhoneAuthProvider.provider().verifyPhoneNumber(self.phone ,uiDelegate : nil) { (verificationID, error) in
            if let error = error {
                print("The error in getting verification ID : \(error.localizedDescription  )")
                self.sendPhoneNumberErrorAlert(error: error.localizedDescription   )
                return
                
            }else{
                print("The verification ID from firebase : \(String(describing: verificationID))")
                UserDefaults.standard.set(verificationID, forKey: "phoneAuthVerificationID")
                
            }
        }
        textOTP2.text = ""
        textOTP3.text = ""
        textOTP4.text = ""
        textOTP5.text = ""
        textOTP6.text = ""
        textOTP1.text = ""
        textOTP1.becomeFirstResponder()
    }
    
     func handleClearOTP(){
        textOTP2.text = ""
        textOTP3.text = ""
        textOTP4.text = ""
        textOTP5.text = ""
        textOTP6.text = ""
        textOTP1.text = ""
        textOTP1.becomeFirstResponder()
    }
    func sendPhoneNumberErrorAlert(error:String) {
        
        let alertController = UIAlertController(title: "Oops", message: error, preferredStyle: .alert)
        let action2 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }
        alertController.addAction(action2)
        self.present(alertController, animated: true, completion: nil)
    }
    func sendVerificationNumberErrorAlert(error:String) {
        
        let alertController = UIAlertController(title: "Oops", message: "verification code you entered is incorrect", preferredStyle: .alert)
        let action2 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }
        alertController.addAction(action2)
        self.present(alertController, animated: true, completion: nil)
    }
    func addBottomBorder(textField:UITextField){
        let layer = CALayer()
        layer.backgroundColor = UIColor.lightGray.cgColor
        layer.frame = CGRect(x: 2.0, y: textField.frame.size.height - 5, width:textField.frame.size.width - 2, height: 2.0)
        textField.layer.addSublayer(layer)
        
    }
    func addBottomBorderBlack(textField:UITextField){
        let layer = CALayer()
        layer.backgroundColor = UIColor.darkGray.cgColor
        layer.frame = CGRect(x: 2.0, y: textField.frame.size.height - 5, width:textField.frame.size.width - 2, height: 2.0)
        textField.layer.addSublayer(layer)
        
    }
    func removeBottomBorder(textField:UITextField){
        let layer = CALayer()
        layer.backgroundColor =  view.backgroundColor?.cgColor
        layer.frame = CGRect(x: 2.0, y: textField.frame.size.height - 5, width:textField.frame.size.width - 2, height: 2.0)
        textField.layer.addSublayer(layer)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
