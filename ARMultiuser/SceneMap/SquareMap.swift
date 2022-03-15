//
//  SquareMap.swift
//  ARMultiuser
//
//  Created by ZhengWu Pan on 14.03.2022.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import DequeModule
import ARKit

class Square: Codable {
    // Скорость "роста высоты" клетки
    var speed = 0
    // Высота клетки в каком-то определённом чанке
    var main = 0
    // Количество "посещений" клетки
    var count = 0
    // Тип поверхнсти, которая будет располагаться на клетке
    var id = 0
    // Итоговая (средняя) высота клетки по всем чанкам, с учётом близости от центров генераций
    var height = 0
    // Лопнула ли ещё эта клетка при генерации конкретного чанка?
    var turn = 0
    // "Вес", на который нужно делить self.heigth, для получения средней высоты
    var delta = 0
    // Является ли генерируемый чанк - чанком суши?
    var type = 0
    // Тип "биома", по которому бедет генерироваться чанк
    var typeres = 0
    
    var x = 0
    var y = 0
}

class Map: Codable {
    var size : Int
    // Карта высот.
    var heights: [[Int]] = [[Int]]()
    // Карта ресурсов.
    var resources: [[Int]] = [[Int]]()
    // Координаты первого игрока
    var first_x: Int = 0
    var first_y: Int = 0
    // Координаты второго игрока.
    var second_x: Int = 0
    var second_y: Int = 0
    
    init(size: Int) {
        self.size = size
        for indexX in 0..<size{
            var x  = [Int]()
            var resource = [Int]()
            for indexY in 0..<size {
                x.append(Int.random(in: 1...5))
                resource.append(Int.random(in: 0...4))
            }
            heights.append(x)
            resources.append(resource)
        }
        first_y = Int.random(in: 0..<size)
        first_x = Int.random(in: 0..<size)
        second_y = Int.random(in: 0..<size)
        second_x = Int.random(in: 0..<size)
    }
    // ---------------------------------------Вспомонательные массивы---------------------------------------
    var stock: [[Square]] = [[Square]]()
    //var under_development: Deque<(Int, Int)> = []
    var turn_cleaning: [Square] = [Square]()
    var interpolated_map: [[Int]] = [[Int]]()
    var resources_map: [[Int]] = [[Int]]()
    //var resources_lists: [(Int, Int)] = [(Int, Int)]()
}
