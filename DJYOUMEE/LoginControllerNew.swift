//
//  LoginViewControllerNew.swift
//  jukeBox1.4
//
//  Created by PUGAZHENTHI VENKATACHALAM on 15/06/18.
//  Copyright © 2018 PUGAZHENTHI VENKATACHALAM. All rights reserved.
//
import UIKit
import Firebase
import FirebaseMessaging
import CountryPicker
let greenColor = UIColor(red:0, green:176, blue:80, alpha:1.0)  //   green
let buttonColor = UIColor(red:239/255, green:237/255, blue:234/255, alpha:1.0)  //   lightGray  // EFEDEA
let titleColor = UIColor(red:90/255, green:82/255, blue:72/255, alpha:1.0)  //   Gray
let orangeColor = UIColor(red:250/255, green:96/255, blue:2/255, alpha:1.0)  //   orange
let refUser = Database.database().reference().child("users")

class LoginControllerNew: UIViewController,CountryPickerDelegate{
   
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var inputsContainerView: UIView!
    @IBOutlet weak var loginRegisterSegmentedControl: UISegmentedControl!
    @IBOutlet weak var inputsContainerViewHeightAnchor: NSLayoutConstraint!
    @IBOutlet weak var emailTextFieldHeightAnchor: NSLayoutConstraint!
    @IBOutlet weak var phoneTextFieldHeightAnchor: NSLayoutConstraint!
    @IBOutlet weak var nameTextFieldHeightAnchor: NSLayoutConstraint!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var loginRegisterButton: UIButton!
    var signInMode : String  = ""
    var ISD : String = ""
    var mobileNumber : String = ""
    var newUser : Bool = false
    @IBAction func mobileNumberCatch(_ sender: Any) {
        self.mobileNumber  =  String(self.phoneTextField.text!.dropFirst(self.ISD.count))
      
    }
    @IBOutlet weak var picker: CountryPicker!
    @IBAction func handleKeyPad(_ sender: Any) {
        self.nameTextField.resignFirstResponder()
        self.emailTextField.resignFirstResponder()
        self.phoneTextField.resignFirstResponder()  
    }
    
    func countryPhoneCodePicker(_ picker: CountryPicker, didSelectCountryWithName name: String, countryCode: String, phoneCode: String, flag: UIImage) {
        phoneTextField.text = phoneCode
        self.ISD = phoneCode
    }
    let nameSeparator : UIView = {
        let separator = UIView()
        separator.backgroundColor = buttonColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()
    let emailSeparator : UIView = {
        let separator = UIView()
        separator.backgroundColor = buttonColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()
    let phoneSeparator : UIView = {
        let separator = UIView()
        separator.backgroundColor = buttonColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()
    func nameTextFieldSetUp(){
        nameTextField.autocapitalizationType = UITextAutocapitalizationType.none
        nameTextField.autocorrectionType = UITextAutocorrectionType.no
        nameTextField.font = UIFont(name: "Arial Rounded MT Bold", size: 16.0)
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.placeholder   = "Name"
        
    }
    func emailTextFieldSetUp(){
        emailTextField.placeholder   = "Email"
        emailTextField.autocapitalizationType = UITextAutocapitalizationType.none
        emailTextField.autocorrectionType = UITextAutocorrectionType.no
        emailTextField.keyboardType = UIKeyboardType.emailAddress
        emailTextField.font = UIFont(name: "Arial Rounded MT Bold", size: 16.0)
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
    }
    func phoneTextFieldSetUp(){
        
        phoneTextField.keyboardType = UIKeyboardType.phonePad
        phoneTextField.autocorrectionType = UITextAutocorrectionType.no
        phoneTextField.translatesAutoresizingMaskIntoConstraints = false
        phoneTextField.font = UIFont(name: "Arial Rounded MT Bold", size: 16.0)
       
    }
    func loginRegisterButtonSetUp(){
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        self.loginRegisterSegmentedControl.addTarget(self, action: #selector(handleLoginRegisterChange), for: .valueChanged)
        loginRegisterButton.titleLabel?.textColor = UIColor.white
        loginRegisterButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        loginRegisterButton.translatesAutoresizingMaskIntoConstraints     = false
        loginRegisterButton.layer.cornerRadius = 5
        loginRegisterButton.layer.masksToBounds = true
        loginRegisterButton.addTarget(self , action: #selector(handleLoginRegister), for: .touchUpInside )
        loginRegisterButton.isUserInteractionEnabled = true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loginRegisterButton.layer.cornerRadius = 5.0
        self.loginRegisterSegmentedControl.selectedSegmentIndex = 0
        handleLoginRegisterChange()
        nameTextFieldSetUp()
        emailTextFieldSetUp()
        phoneTextFieldSetUp()
        loginRegisterButtonSetUp()
      
        let locale = Locale.current
        let code = (locale as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String
        picker.countryPickerDelegate = self
        picker.showPhoneNumbers = true
        let theme = CountryViewTheme(countryCodeTextColor: .white, countryNameTextColor: .white, rowBackgroundColor: titleColor, showFlagsBorder: true)
        picker.theme = theme
        picker.setCountry(code)
        
        inputsContainerView.backgroundColor = UIColor.white
        inputsContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputsContainerView.layer.cornerRadius = 5
        inputsContainerView.layer.masksToBounds = true
        
        inputsContainerView.addSubview(nameSeparator)
        nameSeparator.centerXAnchor.constraint(equalTo: inputsContainerView.centerXAnchor ).isActive = true
        nameSeparator.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        nameSeparator.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameSeparator.heightAnchor.constraint(equalToConstant: 1).isActive = true
       
        inputsContainerView.addSubview(emailSeparator)
        emailSeparator.centerXAnchor.constraint(equalTo: inputsContainerView.centerXAnchor ).isActive = true
        emailSeparator.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        emailSeparator.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailSeparator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        inputsContainerView.addSubview(phoneSeparator)
        phoneSeparator.centerXAnchor.constraint(equalTo: inputsContainerView.centerXAnchor ).isActive = true
        phoneSeparator.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor).isActive = true
        phoneSeparator.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        phoneSeparator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        
    }
    
    @objc func handleLoginRegisterChange(){
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        inputsContainerViewHeightAnchor?.constant = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 40 : 120
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0{
            phoneTextField.becomeFirstResponder()
        }else{
            nameTextField.becomeFirstResponder()
        }

    }
    
    @objc func handleLoginRegister(){
        if(loginRegisterSegmentedControl.selectedSegmentIndex == 0){ // MARK: - // login
            guard let phone = phoneTextField.text else { return }
            if phone.count != 0{
                refUser.queryOrdered(byChild: "phoneNumber").queryEqual(toValue: phone).observeSingleEvent(of:.value, with: { (snapshot) in
                    if snapshot.exists() == false{
                        print("New User")
                        self.newUser = true
                        self.signInMode = "register"
                        self.showPhoneNumberNewAlert()
                        return
                    }else{
                        self.newUser = false
                        self.handleLogin()
                        self.signInMode = "login"
                    }
                }, withCancel: nil)
            }
            
        }else{   //  // MARK: - register
            guard let phone = phoneTextField.text else { return }
            if phone.count != 0{
                refUser.queryOrdered(byChild: "phoneNumber").queryEqual(toValue: phone).observeSingleEvent(of:.value, with: { (snapshot) in
                    if snapshot.exists() == false{
                        print("New User")
                        self.handleRegister()
                        self.signInMode = "register"
                        self.newUser = true
                        // self.showPhoneNumberNewAlert()
                    }else{
                        self.newUser = false
                        self.signInMode = "login"
                        self.showPhoneNumberExistsAlert()
                        return
                    }
                }, withCancel: nil)
            }
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let backItem = UIBarButtonItem()
        navigationItem.backBarButtonItem = backItem
        if segue.identifier   == "showOTPView"{
         let otpViewController =  segue.destination  as! OTPViewController
            otpViewController.name = nameTextField.text!
            otpViewController.email = emailTextField.text!
            otpViewController.phone = phoneTextField.text!
            otpViewController.mobileNumber =   String(self.phoneTextField.text!.dropFirst(self.ISD.count))
            otpViewController.signInMode = self.signInMode
            otpViewController.verificationID = UserDefaults.standard.value(forKey: "phoneAuthVerificationID") as! String
        }
        
    }
   
    @objc func handleLogin(){
        guard let phone = phoneTextField.text else { return }
        if phone.count != 0{
        self.phoneTextField.resignFirstResponder()
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneTextField.text!, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                print("The error in getting verification ID : \(error.localizedDescription  )")
                self.sendPhoneNumberErrorAlert(error: error.localizedDescription   )
                return
            }else{
                print("The verification ID from firebase : \(String(describing: verificationID))")
                UserDefaults.standard.set(verificationID, forKey: "phoneAuthVerificationID")
                self.performSegue(withIdentifier: "showOTPView", sender: self)
            }
        }
        }else{
            self.showPhoneErrorAlert()
        }
    }
    @objc func handleRegister(){
        guard let name = nameTextField.text, let email = emailTextField.text,let phone = phoneTextField.text else {
            return
        }
        if name.count != 0 && phone.count != 0 && email.count != 0{
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneTextField.text!, uiDelegate: nil) { (verificationID, error) in
                if let error = error {
                    self.sendPhoneNumberErrorAlert(error: error.localizedDescription)
                    return
                }else{
                    UserDefaults.standard.set(verificationID, forKey: "phoneAuthVerificationID")
                    self.performSegue(withIdentifier: "showOTPView", sender: self)
                }
            }
        }else{
            self.showErrorAlert()
        }
    }
    
    func showErrorAlert() {
        
        let alertController = UIAlertController(title: "DJyouMEE", message: "Enter Valid credentials for all Fields", preferredStyle: .alert)
        let action6 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }
        alertController.addAction(action6)
        self.present(alertController, animated: true, completion: nil)
    }
    func showPhoneErrorAlert() {
        
        let alertController = UIAlertController(title: "DJyouMEE", message: "Enter Valid Phone Number", preferredStyle: .alert)
        let action5 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }
        alertController.addAction(action5)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showPhoneNumberExistsAlert() {
        
        let alertController = UIAlertController(title: "DJyouMEE", message: "Phone number is registered already", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Login now", style: .default) { (action:UIAlertAction) in
            self.loginRegisterSegmentedControl.selectedSegmentIndex = 0
            self.handleLoginRegisterChange()
        }
        alertController.addAction(action1)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showPhoneNumberNewAlert() {
        
        let alertController = UIAlertController(title: "DJyouMEE", message: "Phone number is not registered", preferredStyle: .alert)
        let action2 = UIAlertAction(title: "Register now", style: .default) { (action:UIAlertAction) in
            self.loginRegisterSegmentedControl.selectedSegmentIndex = 1
            self.handleLoginRegisterChange()
        }
        alertController.addAction(action2)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func sendPhoneNumberErrorAlert(error:String) {
        
        let alertController = UIAlertController(title: "Oops", message: error, preferredStyle: .alert)
        let action3 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }
        alertController.addAction(action3)
        self.present(alertController, animated: true, completion: nil)
    }
    func showSendMailErrorAlert() {
        
        let alertController = UIAlertController(title: "Enter Valid Credentials", message: "Enter Name / Valid Email and try again.", preferredStyle: .alert)
        let action4 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }
        alertController.addAction(action4)
        self.present(alertController, animated: true, completion: nil)
        
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
extension UIColor{
    convenience init(r:CGFloat, g:CGFloat, b:CGFloat){
        self.init(red : r/255,green : g/255, blue:b/255, alpha :1.0)
        
    }
    
}
extension LoginControllerNew{
    
class func displaySpinner(onView : UIView) -> UIView {
    let spinnerView = UIView.init(frame: onView.bounds)
    spinnerView.backgroundColor = orangeColor
    let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
    ai.startAnimating()
    ai.center = spinnerView.center
    
    DispatchQueue.main.async {
        spinnerView.addSubview(ai)
        onView.addSubview(spinnerView)
    }
    
    return spinnerView
}

class func removeSpinner(spinner :UIView) {
    DispatchQueue.main.async {
        spinner.removeFromSuperview()
    }
}
}
