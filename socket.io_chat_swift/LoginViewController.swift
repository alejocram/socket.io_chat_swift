//
//  LoginViewController.swift
//  socket.io_chat_swift
//
//  Created by Nguyen Bon on 12/24/15.
//  Copyright © 2015 SmartDev LLC. All rights reserved.
//

import UIKit
import SocketIO

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var tfUserName: CustomUITextField!
    @IBOutlet weak var btnJoin: UIButton!
    
    private var socket:SocketIOClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tfUserName.delegate = self
        tfUserName.attributedPlaceholder = NSAttributedString(string: tfUserName.placeholder!,
            attributes:[NSForegroundColorAttributeName: UIColor.gray])
        
        // try connect to char server
        socket = SocketIOClientSingleton.instance.socket
        
        socket?.on("login") {data, ack in
            if let json = data[0] as? NSDictionary {
                let mainViewControllerIdentifier = self.storyboard?.instantiateViewController(withIdentifier: "MainViewControllerIdentifier") as? MainViewController
                
                mainViewControllerIdentifier!.userName = self.tfUserName.text
                mainViewControllerIdentifier!.numUsers = json["numUsers"]! as! NSNumber
                
                self.present(mainViewControllerIdentifier!, animated: true, completion: nil)
            }
        }
        
        socket!.connect()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        socket?.off("login")
    }
    
    @IBAction func attemptLogin(_ sender: AnyObject) {
        loginWithNickName()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loginWithNickName()
        return true
    }
    
    private func loginWithNickName() {
        let userName = tfUserName.text
        
        if !userName!.isEmpty {
            nextChatRoom(userName: userName)
        } else {
            showAlertErrorMessageIfNickNameIsEmpty()
        }
    }
    
    private func nextChatRoom(userName :String?) {
        socket?.emit("add user", userName!)
    }
    
    private func showAlertErrorMessageIfNickNameIsEmpty() {
        let alert = UIAlertController(title: "Message", message: "Please input your nickname?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
            self.tfUserName.becomeFirstResponder()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}
