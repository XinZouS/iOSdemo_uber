/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse // User: username, password, isDriver

class ViewController: UIViewController {
    
    var isLoginMode = true;

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var isDriverSwitch: UISwitch!
    @IBOutlet weak var labelRider: UILabel!
    @IBOutlet weak var labelDriver: UILabel!
    
    
    @IBOutlet weak var loginOrsignupButton: UIButton!
    @IBAction func loginOrSignupButtonTapped(_ sender: AnyObject) {
        
        var getUsername : String
        var getPassword : String
        
        if usernameTextField.text == "" || passwordTextField.text == "" {
            alertPopOneReply(title: "d(o_O)b  Oops!", msg: "Please use correct username and password. Try again please.", reply: "OK!")
            return
        } else {
            getUsername = usernameTextField.text! as String
            getPassword = passwordTextField.text! as String
        }
        
        if isLoginMode { // make user login in.=================================================
            
            PFUser.logInWithUsername(inBackground: getUsername, password: getPassword, block: { (user, error) in
                if let error = error as? NSError {
                    if let errInfo = error.userInfo["error"] as? String {
                        self.alertPopOneReply(title: "Login in fail", msg: " \(errInfo)", reply: "Try again")
                    }
                } else { // user login in success! do sth.
                    if let isDriver = PFUser.current()?["isDriver"] as? Bool {
                        if isDriver {
                            self.performSegue(withIdentifier: "showDriverViewController", sender: self)
                        } else { // is rider login in
                            self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                        }
                    }
                }
            })
            
        }else{ // make user sign up in server.=================================================
            let user = PFUser() // make a current user.
            
            user.username = usernameTextField.text
            user.password = passwordTextField.text
            user["isDriver"] = self.isDriverSwitch.isOn
            
            user.signUpInBackground(block: { (success, error) in
                if let error = error as? NSError {
                    if let errInfo = error.userInfo["error"] as? String {
                        self.alertPopOneReply(title: "_(:3)<)_", msg: "Sign up failed: \(errInfo) Please try later.", reply: "OK!")
                    }
                } else { //sign up successful
                    // self.alertPopOneReply(title: "Success!", msg: "Sign up success! Enjoy your ride.", reply: "OK")
                    if let isDriver = PFUser.current()?["isDriver"] as? Bool {
                        if isDriver {
                            self.performSegue(withIdentifier: "showDriverViewController", sender: self)
                        } else { // is rider login in
                            self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                        }
                    }
                }
                
            })
            
            // end of user.signUpInBackground(){}
        }
    }

    @IBOutlet weak var changeLoginModelBtn: UIButton!
    @IBAction func changeLoginModelBtnTapped(_ sender: AnyObject) {
        if isLoginMode { // change to Sign up:
            loginOrsignupButton.setTitle("Sign Up", for: [])
            changeLoginModelBtn.setTitle("Or switch to Login In", for: [])
            labelRider.isHidden = false
            labelDriver.isHidden = false
            isDriverSwitch.isHidden = false
            isLoginMode = false // sign up go
        } else { // change to LoginIn: 
            loginOrsignupButton.setTitle("Login In", for: [])
            changeLoginModelBtn.setTitle("Or switch to Sign Up", for: [])
            labelRider.isHidden = true
            labelDriver.isHidden = true
            isDriverSwitch.isHidden = true
            isLoginMode = true // login go
        }
    }
    
    
    func alertPopOneReply(title: String, msg: String, reply: String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: reply, style: UIAlertActionStyle.default, handler: {(action) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
            isDriverSwitch.isHidden = isLoginMode
            labelRider.isHidden =     isLoginMode
            labelDriver.isHidden =    isLoginMode
        

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if let isDriver = PFUser.current()?["isDriver"] as? Bool {
            if isDriver {
                self.performSegue(withIdentifier: "showDriverViewController", sender: self)
            } else { // is rider login in
                self.performSegue(withIdentifier: "showRiderViewController", sender: self)
            }
        }

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
