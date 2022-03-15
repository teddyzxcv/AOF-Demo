//
//  PlayerAction.swift
//  ARMultiuser
//
//  Created by ZhengWu Pan on 14.03.2022.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import SceneKit

class PlayerAction: Codable{
    var playerIndex: Int
    var playerDist: [Float]
    
    func getDist() -> SCNVector3{
        return SCNVector3(x: playerDist[0], y: playerDist[1], z: playerDist[2])
    }
    
    init() {
        playerIndex = 0;
        playerDist = [0,0,0]
    }
}
