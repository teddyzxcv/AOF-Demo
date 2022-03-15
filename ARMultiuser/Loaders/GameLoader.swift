//
//  GameLoader.swift
//  ARMultiuser
//
//  Created by ZhengWu Pan on 15.03.2022.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class GameLoader {
    
    let scale: Float = 40
    
    static var players: [SCNNode]!
    
    func loadMap(squareMap: Map) -> [SCNNode] {
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
                node.name = "Terrain"
                squareNodes.append(node)
            }
        }
        return squareNodes
    }
    
    func loadPlayers(squareMap: Map) -> [SCNNode] {
        let pShape = SCNCapsule(capRadius: 0.4 / CGFloat(scale), height: 2.5 / CGFloat(scale))
        let node = SCNNode(geometry: pShape)
        let x = Float(squareMap.first_x) - Float(squareMap.size / 2)
        let y = Float(squareMap.first_y) - Float(squareMap.size / 2)
        let nHeight: CGFloat = CGFloat(Float(squareMap.heights[squareMap.first_x][squareMap.first_y]) / scale)
        node.position = SCNVector3(x: Float(x) / Float(scale) , y: Float(nHeight + (CGFloat(2.5 / scale) / 2)), z: Float(y) / Float(scale) )
        node.name = "First Player"
        return [node]
    }
    
    func getSquareByPos(vector: SCNVector3, squareMapSize: Int) -> Square{
        var square = Square()
        let x = round(vector.x * scale + Float(squareMapSize / 2))
        let y = round(vector.z * scale + Float(squareMapSize / 2))
        let h = round(vector.y * 2 * scale)
        square.x = Int(x)
        square.y = Int(y)
        square.height = Int(h)
        return square
    }
    
    func jumpAction() -> SCNAction{
        var action = SCNAction.moveBy(x: 0, y: 1 / CGFloat(scale), z: 0, duration: 0.1)
        action = SCNAction.sequence([action, SCNAction.moveBy(x: 0, y: -1 / CGFloat(scale), z: 0, duration: 0.2)])
        return action
    }
    
    func moveToAction(dist: SCNVector3) -> SCNAction {
        var targetPosition = dist
        targetPosition.y *= 2
        targetPosition.y += Float(2.5 / CGFloat(scale)) / 2
        let jumpAction = SCNAction.move(to: targetPosition, duration: 0.3)
        let action = SCNAction.group([jumpAction, SCNAction.sequence( [SCNAction.fadeOut(duration: 0.01), SCNAction.wait(duration: 0.19), SCNAction.fadeIn(duration: 0.1)])])
        return action
    }
}
