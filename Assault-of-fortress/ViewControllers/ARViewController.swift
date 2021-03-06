/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity

class ARViewController: UIViewController, SessionPassDelegate {
    
    func passingSession(session: MultipeerSession) {
        multipeerSession = session
        multipeerSession.receivedDataHandler = receivedData
        multipeerSession.getSessionDelegateBack()
    }
    
    var isPlaced: Bool = false
    
    var squareMap: Map!
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var sendMapButton: UIButton!
    @IBOutlet weak var mappingStatusLabel: UILabel!
    
    // MARK: - View Life Cycle
    
    var multipeerSession: MultipeerSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        // Start the view's AR session.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking(nil)
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Multiuser shared session
    
    var previousSelected: SCNNode!
    
    /// - Tag: PlaceCharacter
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView
            .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
            .first
        else { return }
        if isPlaced {
            guard let nodeHitTestResult = sceneView.hitTest(sender.location(in: sceneView), options: .none).first
            else { return }
            let node = nodeHitTestResult.node
            if node.name != "Terrain" {
                if previousSelected != nil  {
                    if Int(previousSelected.name!) != nil && previousSelected.name != node.name{
                        node.runAction(SCNAction.fadeOut(duration: 0.3))
                        node.isHidden = true
                        previousSelected.runAction(SCNAction.move(to: node.position, duration: 0.2))
                        sendAction(playerIndex: Int(previousSelected.name ?? "1") ?? 0, dist: node.position )
                        return
                    }
                    let action = GameLoader().jumpAction()
                    node.runAction(action)
                } else {
                    let action = GameLoader().jumpAction()
                    node.runAction(action)
                }
            } else if node.name == "Resource" {
                return
            }else if previousSelected != nil && Int(previousSelected.name!) != nil{
                print("Send action move")
                previousSelected.runAction(GameLoader().moveToAction(dist: node.position))
                sendAction(playerIndex: Int(previousSelected.name ?? "1") ?? 0, dist: node.position )
            }
            previousSelected = node
            return
        }
        // Place an anchor for a virtual character. The model appears in renderer(_:didAdd:for:).
        let anchor = ARAnchor(name: "gamePlace", transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: anchor)
        isPlaced = true
        // Send the anchor info to peers, so they can place the same content.
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
        else { fatalError("can't encode anchor") }
        self.multipeerSession.sendToAllPeers(data)
    }
    
    func sendAction(playerIndex: Int, dist: SCNVector3) {
        do{
            let action = PlayerAction()
            action.playerIndex = playerIndex
            action.playerDist = [dist.x, dist.y, dist.z]
            let encoder = JSONEncoder()
            let data = try encoder.encode(action)
            self.multipeerSession.sendToAllPeers(data)}
        catch{
            fatalError()
        }
    }
    
    /// - Tag: GetWorldMap
    @IBAction func shareSession(_ button: UIButton) {
        do{
            print("Share the map")
            let encoder = JSONEncoder()
            squareMap = MapGenerator().generateMap()
            print(squareMap.first_x)
            let data = try encoder.encode(squareMap)
            self.multipeerSession.sendToAllPeers(data)
        } catch {
            print("Can't the map")
        }
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
            else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
            else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
        }
    }
    
    @IBAction func resetTracking(_ sender: UIButton?) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isPlaced = false
    }
    
    var mapProvider: MCPeerID?
    
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        do {
            let action = try JSONDecoder()
                .decode(PlayerAction.self, from: data)
            GameLoader.players[action.playerIndex].runAction(GameLoader().moveToAction(dist: action.getDist()))
            //            sessionInfoLabel.text = "from \(peer.displayName), player index: \(action.playerIndex) do \(action.playerIndex)"
            print("Recieved action")
            return
        } catch {
            // no use
        }
        do {
            if let sMap = try? JSONDecoder().decode(Map.self, from: data) {
                squareMap = sMap
            } else if let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
            }
            else if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                // Add anchor to the session, ARSCNView delegate adds visible content.
                sceneView.session.add(anchor: anchor)
                isPlaced = true
            }
            else {
                print("unknown data recieved from \(peer)")
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
    }
    
    // MARK: - AR session management
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
                .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
}

extension ARViewController: ARSCNViewDelegate{
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix("gamePlace") {
            print("Start rendering")
            let lightNode = SCNNode()
            lightNode.light = SCNLight()
            lightNode.light?.type = .omni
            lightNode.position = SCNVector3(x: 0, y: 20 , z: 20)
            lightNode.castsShadow = true
            lightNode.light?.color = UIColor.white
            lightNode.name = "light"
            node.addChildNode(lightNode)
            let gameLoader = GameLoader()
            let sceneURL = Bundle.main.url(forResource: "terrain", withExtension: "scn", subdirectory: "Assets.scnassets")!
            let referenceNode = SCNReferenceNode(url: sceneURL)!
            referenceNode.load()
            let nodes = gameLoader.loadMap(squareMap: self.squareMap, referenceNode: referenceNode)
            for chnode in nodes{
                node.addChildNode(chnode)
            }
            print(multipeerSession.session.connectedPeers.count)
            GameLoader.players = gameLoader.loadPlayers(squareMap: self.squareMap, playerCount: multipeerSession.session.connectedPeers.count)
            for chnode in GameLoader.players{
                node.addChildNode(chnode)
            }
        }
    }
}

extension ARViewController: ARSessionDelegate {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            sendMapButton.isEnabled = false
        case .extending:
            sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        case .mapped:
            sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        @unknown default:
            sendMapButton.isEnabled = false
        }
        mappingStatusLabel.text = frame.worldMappingStatus.description
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
}

