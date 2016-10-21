//
//  SocketIOClientSingleton.swift
//  socket.io_chat_swift
//
//  Created by Nguyen Bon on 12/24/15.
//  Copyright © 2015 SmartDev LLC. All rights reserved.
//

import Foundation
import SocketIO

public class SocketIOClientSingleton {
    
    static let instance = SocketIOClientSingleton()
    
    var socket:SocketIOClient!
    
    private init() {
        self.socket = SocketIOClient(socketURL: URL(string: Constants.CHAT_SERVER_URL)!, config: [.log(false)])
    }
    
}
