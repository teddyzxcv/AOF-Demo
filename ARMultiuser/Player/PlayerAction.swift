//
//  PlayerAction.swift
//  ARMultiuser
//
//  Created by ZhengWu Pan on 14.03.2022.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation

class PlayerAction: Codable{
    var playerIndex: Int
    var playerAction: String
    
    init() {
        playerIndex = 0;
        playerAction = "Go"
    }
}
