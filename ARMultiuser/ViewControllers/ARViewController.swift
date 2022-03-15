/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity

class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SessionPassDelegate {
    
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
        squareMap = Map(size: 13)
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
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's AR session.
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 20 , z: 20)
        lightNode.castsShadow = true
        lightNode.light?.color = UIColor.white
        lightNode.name = "light"
        node.addChildNode(lightNode)
        if let name = anchor.name, name.hasPrefix("gamePlace") {
            let nodes = loadMap()
            for chnode in nodes{
                node.addChildNode(chnode)
            }
            node.addChildNode(loadPlayers().first!)
        }
    }
    
    // MARK: - ARSessionDelegate
    
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
            print("------>>>>")
            print(nodeHitTestResult.node.debugDescription)
            print(nodeHitTestResult.node.description)
            print(nodeHitTestResult.node.name)
            print(nodeHitTestResult.node.parent?.description)
            print(nodeHitTestResult.node.parent?.childNodes.first?.description)
            print(nodeHitTestResult.node.parent?.childNodes.count)
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
    
    @IBAction func sendAction(_ sender: Any) {
        do{
            let action = PlayerAction()
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
    
    var mapProvider: MCPeerID?
    
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        do {
            let action = try JSONDecoder()
                .decode(PlayerAction.self, from: data)
            print("from \(peer.displayName), player index: \(action.playerIndex) do \(action.playerAction)")
            //            sessionInfoLabel.text = "from \(peer.displayName), player index: \(action.playerIndex) do \(action.playerIndex)"
            return
        } catch {
            // no use
        }
        do {
            if let sMap = try? JSONDecoder().decode(Map.self, from: data) {
                print("Recieve squareMap")
                squareMap = sMap
            } else if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                print("Recieve ARmap")
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
    
    @IBAction func resetTracking(_ sender: UIButton?) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isPlaced = false
    }
    
    let scale : Float = 40
    
    private func loadPlayers() -> [SCNNode] {
        let pShape = SCNCapsule(capRadius: 0.4 / CGFloat(scale), height: 2.5 / CGFloat(scale))
        let node = SCNNode(geometry: pShape)
        let x = Float(squareMap.first_x) - Float(squareMap.size / 2)
        let y = Float(squareMap.first_y) - Float(squareMap.size / 2)
        let nHeight: CGFloat = CGFloat(Float(squareMap.heights[squareMap.first_x][squareMap.first_y]) / scale)
        node.position = SCNVector3(x: Float(x) / Float(scale) , y: Float(nHeight + (CGFloat(2.5 / scale) / 2)), z: Float(y) / Float(scale) )
        node.name = "First player"
        return [node]
    }
    
    // MARK: - AR session management
    private func loadMap() -> [SCNNode] {
        let sceneURL = Bundle.main.url(forResource: "terrain", withExtension: "scn", subdirectory: "Assets.scnassets")!
        let referenceNode = SCNReferenceNode(url: sceneURL)!
        referenceNode.load()
        let terrainNode = referenceNode.childNodes.first!
        var squareNodes = [SCNNode]()
        for indexX in 0..<squareMap.heights.count{
            for indexY in 0..<squareMap.heights.count {
                let height = squareMap.heights[indexX][indexY]
                let nWidth: CGFloat = CGFloat(1 / scale)
                let nLength: CGFloat = CGFloat(1 / scale)
                let nHeight: CGFloat = CGFloat(Float(height) / scale)
                // let square = SCNBox(width: nWidth, height: nHeight, length: nLength, chamferRadius: 0.001)
                var color : UIColor!
                switch height{
                case 1:
                    color = UIColor.blue
                    break
                case 2:
                    color = UIColor.green
                    break
                case 3:
                    color = UIColor.systemGreen
                    break
                case 4:
                    color = UIColor.gray
                    break
                case 5:
                    color = UIColor.white
                    break
                default:
                    color = UIColor.orange
                }
                let node: SCNNode = terrainNode.copy() as! SCNNode
                let geo = node.geometry?.copy() as! SCNBox
                geo.width = nWidth
                geo.height = nHeight
                geo.length = nLength
                geo.chamferRadius = CGFloat(0.02 / scale)
                let material = geo.firstMaterial?.copy() as! SCNMaterial
                material.diffuse.contents = color
                material.lightingModel = SCNMaterial.LightingModel.physicallyBased
                geo.firstMaterial = material
                node.geometry = geo
                let x = Float(indexX) - Float(squareMap.size / 2)
                let y = Float(indexY) - Float(squareMap.size / 2)
                node.position = SCNVector3(x: Float(x) / Float(scale) , y: Float(nHeight / 2), z: Float(y) / Float(scale) )
                node.name = "x:\(indexX), y:\(indexY), height:\(height)"
                squareNodes.append(node)
            }
        }
        return squareNodes
    }
}

