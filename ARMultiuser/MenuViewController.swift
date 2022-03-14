//
//  MenuViewController.swift
//  ARMultiuser
//
//  Created by ZhengWu Pan on 14.03.2022.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

class MenuViewController: UIViewController {
    
    @IBOutlet weak var menuView: UIView!
    
    var sessionPassingDelegate : SessionPassDelegate?
    
    @IBOutlet weak var hostButton: RoundedButton!
    @IBOutlet weak var joinButton: RoundedButton!
    @IBOutlet weak var startButton: RoundedButton!
    @IBOutlet weak var connectStatusLabel: ConnectionStatusLabel!

    var multipeerSession: MultipeerSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.isHidden = true
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        multipeerSession.serviceAdvertiser.delegate = self
        multipeerSession.session.delegate = self
    }
    
    @IBAction func startTheGame(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AR") as! ARViewController
        present(vc, animated: true)
        sessionPassingDelegate = vc
        sessionPassingDelegate?.passingSession(session: multipeerSession)
    }
    override func viewDidAppear(_ animated: Bool) {
        
    }
    @IBAction func joinTheSession(_ sender: RoundedButton) {
        let browser = multipeerSession.browseTheSession()
        browser.modalPresentationStyle = .pageSheet
        present(browser,animated: true)
    }
    
    @IBAction func hostTheSession(_ sender: Any) {
        multipeerSession.hostTheSession()
    }
    func receivedData(_ data: Data, from peer: MCPeerID){
        print("received")
    }
    

}
extension MenuViewController: MCNearbyServiceAdvertiserDelegate {
    /// - Tag: AcceptInvite
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Call handler to accept invitation and join the session.
        print("Connect invite appears from \(peerID)")
            let ac = UIAlertController(title: "Invitation of new game", message: "'\(peerID.displayName)' wants to connect", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Accept", style: .default, handler: { [weak multipeerSession] _ in
                invitationHandler(true, multipeerSession?.session)
            }))
            ac.addAction(UIAlertAction(title: "Decline", style: .cancel, handler: { _ in
                invitationHandler(false, nil)
            }))
            present(ac, animated: true)
    }
}

extension MenuViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        connectStatusLabel.peerID = peerID
        connectStatusLabel.connectStatus = state
        if(state == .connected){
            startButton.isHidden = false
        } else if(state == .notConnected){
            startButton.isHidden = true
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        fatalError("This service does not send/receive streams.")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        fatalError("This service does not send/receive resources.")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This service does not send/receive resources.")
    }
    
}
