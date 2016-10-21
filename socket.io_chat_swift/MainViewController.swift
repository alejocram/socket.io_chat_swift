//
//  ViewController.swift
//  socket.io_chat_swift
//
//  Created by Nguyen Bon on 12/24/15.
//  Copyright © 2015 SmartDev LLC. All rights reserved.
//

import UIKit
import SocketIO

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var tblMessage: UITableView!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var tfMessage: UITextField!
    
    private var usernameColors:[UIColor] = [
        UIColor(hexString: "#e21400"),
        UIColor(hexString: "#91580f"),
        UIColor(hexString: "#f8a700"),
        UIColor(hexString: "#f78b00"),
        UIColor(hexString: "#58dc00"),
        UIColor(hexString: "#287b00"),
        UIColor(hexString: "#a8f07a"),
        UIColor(hexString: "#4ae8c4"),
        UIColor(hexString: "#3b88eb"),
        UIColor(hexString: "#3824aa"),
        UIColor(hexString: "#a700ff"),
        UIColor(hexString: "#d300e7")]
    
    private var socket:SocketIOClient!
    private var messages:NSMutableArray? = NSMutableArray()
    private var typing:Bool! = false
    private var timer: Timer?
    private var delaySeconds:TimeInterval! = 0.6
    
    var userName:String!
    var numUsers:NSNumber! = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tfMessage.delegate = self
        
        tblMessage.dataSource = self
        tblMessage.delegate = self
        
        tblMessage.estimatedRowHeight = 44.0
        tblMessage.rowHeight = UITableViewAutomaticDimension
        
        addLog("Welcome to Socket.IO Chat –")
        addParticipantsLog(numUsers)
        
        // try connect to char server
        socket = SocketIOClientSingleton.instance.socket
        
        socket?.on("new message") {data, ack in
            if let json = data[0] as? NSDictionary {
                let userName = json["username"] as! String
                let message = json["message"] as! String
                
                self.removeTyping(userName)
                self.addMessage(userName, message: message)
            }
        }
        
        socket?.on("user joined") {data, ack in
            if let json = data[0] as? NSDictionary {
                let userName = json["username"] as! String
                let numUsers = json["numUsers"]! as! NSNumber
                
                self.addLog(userName + " joined")
                self.addParticipantsLog(numUsers)
            }
        }
        
        socket?.on("user left") {data, ack in
            if let json = data[0] as? NSDictionary {
                let userName = json["username"] as! String
                let numUsers = json["numUsers"]! as! NSNumber
                
                self.addLog(userName + " left")
                self.addParticipantsLog(numUsers)
                self.removeTyping(userName)
            }
        }
        
        socket?.on("typing") {data, ack in
            if let json = data[0] as? NSDictionary {
                let userName = json["username"] as! String
                
                self.addTyping(userName)
            }
        }
        
        socket?.on("stop typing") {data, ack in
            if let json = data[0] as? NSDictionary {
                let userName = json["username"] as! String
                
                self.removeTyping(userName)
            }
        }
        
        socket?.connect()
    }
    
    @IBAction func sendMessage(_ sender: AnyObject) {
        attemptSend()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        socket?.disconnect()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return (messages?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row:Int? = (indexPath as NSIndexPath).row
        if let message = messages?.object(at: row!) as? Message {
            if message.type == MessageType.log {
                let cell:ChatItemLog? = tblMessage.dequeueReusableCell(withIdentifier: "cellIdentifierChatItemLog", for: indexPath) as? ChatItemLog
                cell?.lblLog.text = message.message
                
                return cell!
            } else if message.type == MessageType.typeAction {
                let cell:ChatItemIsTyping? = tblMessage.dequeueReusableCell(withIdentifier: "cellIdentifierChatItemIsTyping", for: indexPath) as? ChatItemIsTyping
                cell?.lblTyping.text = message.message
                cell?.lblUserName.text = message.userName
                cell?.lblUserName.textColor = getUsernameColor(message.userName)
                
                return cell!
            } else {
                let cell:ChatItemMessage? = tblMessage.dequeueReusableCell(withIdentifier: "cellIdentifierChatItemMessage", for: indexPath) as? ChatItemMessage
                cell?.lblMessage.text = message.message
                cell?.lblUserName.text = message.userName
                cell?.lblUserName.textColor = getUsernameColor(message.userName)
                
                return cell!
            }
            
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row:Int? = (indexPath as NSIndexPath).row
        if let message = messages?.object(at: row!) as? Message {
            if message.type == MessageType.message {
                return  UITableViewAutomaticDimension
            }
        }
        return 26.0
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tfMessage.resignFirstResponder()
        attemptSend()
        return true
    }
    
    @IBAction func editingChanged(_ sender: AnyObject) {
        if !typing {
            typing = true
            socket.emit("typing")
        }
        
        self.timer?.invalidate()
        self.timer = nil
        self.timer = Timer.scheduledTimer(timeInterval: delaySeconds,
            target: self, selector: #selector(MainViewController.typingTimeout), userInfo: nil, repeats: false)
    }
    
    func typingTimeout() {
        if !typing {
            return
        }
        
        self.typing = false;
        socket.emit("stop typing")
    }
    
    private func addLog(_ message:String?) {
        let msg = Message()
        msg.userName = self.userName
        msg.message = message
        msg.type = MessageType.log
        
        self.messages?.add(msg)
        scrollToBottom()
    }
    
    private func addParticipantsLog(_ numUsers:NSNumber?) {
        var log:String? = ""
        if numUsers?.int32Value == 1 {
            log = "there\'s " + String(numUsers!.int32Value) + " participant"
        } else {
            log = "there are " + String(numUsers!.int32Value) + " participants"
        }
        
        addLog(log)
    }
    
    private func addMessage(_ username:String?, message:String?) {
        let msg = Message()
        msg.userName = username
        msg.message = message
        msg.type = MessageType.message
        
        self.messages?.add(msg)
        scrollToBottom()
    }
    
    private func addTyping(_ username:String?) {
        let msg = Message()
        msg.userName = username
        msg.message = "is typing"
        msg.type = MessageType.typeAction
        
        self.messages?.add(msg)
        scrollToBottom()
    }
    
    private func removeTyping(_ username:String?) {
        var index = self.messages!.count - 1
        while (index >= 0) {
        //for var index = self.messages!.count - 1; index >= 0; index -= 1 {
            if let message = messages?.object(at: index) as? Message {
                if ((message.type == MessageType.typeAction) && (message.userName == username)) {
                    self.messages?.removeObject(at: index)
                    
                    let indexPath = IndexPath(row: index, section: 0)
                    self.tblMessage.beginUpdates()
                    self.tblMessage.deleteRows(at: [indexPath], with: UITableViewRowAnimation.none)
                    self.tblMessage.endUpdates()
                }
            }
            index -= 1
        }
    }
    
    private func attemptSend() {
        let message = tfMessage.text
        
        if !message!.isEmpty {
            self.tfMessage.text = ""
            addMessage(userName, message: message!)
            socket.emit("new message", message!)
        }
        
        self.tfMessage.becomeFirstResponder()
    }
    
    private func scrollToBottom() {
        let indexPath = IndexPath(row: self.messages!.count - 1, section: 0)
        tblMessage.beginUpdates()
        tblMessage.insertRows(at: [indexPath], with: UITableViewRowAnimation.none)
        tblMessage.endUpdates()
        tblMessage.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
    }
    
    private func getUsernameColor(_ username:String?) -> UIColor {
        var hash:Int! = 7
        
        var index = 0, len = username!.length
        while index < len {
            let indexOfCharacter = username?.characters.index((username?.characters.startIndex)!, offsetBy: index);
            hash = (username?.characters[indexOfCharacter!].unicodeScalarCodePoint())! + (hash << 5) - hash
            index += 1
        }
        
        // Calculate color
        let indexAbs = abs(hash % usernameColors.count);
        return usernameColors[indexAbs]
    }
    
}

