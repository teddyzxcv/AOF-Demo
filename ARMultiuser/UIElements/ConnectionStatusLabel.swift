//
//  ConnectionStatusLabel.swift
//  ARMultiuser
//
//  Created by ZhengWu Pan on 14.03.2022.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

@IBDesignable
class ConnectionStatusLabel: UILabel {
    
    override init(frame: CGRect) {
        self.connectStatus = .notConnected
        super.init(frame: frame)
        self.text = "Not connected"
        setup()
    }
    
    required init?(coder: NSCoder) {
        self.connectStatus = .notConnected
        super.init(coder: coder)
        self.text = "Not connected"
        setup()
        
    }
    
    func setup() {
        backgroundColor = .systemGray
        layer.masksToBounds = true
        layer.cornerRadius = 5
        clipsToBounds = true
        lineBreakMode = NSLineBreakMode.byWordWrapping
        numberOfLines = 0
    }
    
    override var text: String?{
        didSet{
            let c = self.center
            self.sizeToFit()
            self.center = c
        }
    }
    
    var peerID: MCPeerID!
    
    var connectStatus: MCSessionState{
        didSet {
            switch connectStatus {
            case .notConnected:
                print("Not connected")
                self.text =  "Not connected"
                self.backgroundColor = UIColor.systemGray
            case .connecting:
                print("Connecting: \(peerID.displayName)")
                self.text =  "Connecting: \(peerID.displayName)"
                self.backgroundColor = UIColor.systemBlue
            case .connected:
                print("Connected: \(peerID.displayName)")
                self.text =  "Connected: \(peerID.displayName)"
                self.backgroundColor = UIColor.systemGreen
            @unknown default:
                print("Unknown state received: \(peerID.displayName)")
            }
        }
    }
}
