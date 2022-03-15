//
//  MapGenerator.swift
//  ARMultiuser
//
//  Created by ZhengWu Pan on 15.03.2022.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import DequeModule

class MapGenerator {
    func generateMap() -> Map{
        let map = map_generator(sizemap_x: 70, sizemap_y: 70, number_of_continents: 2)
        map.size = map.heights.count
        map.generateRandomPlayersPosition()
        return map
    }
}

//
//  main.swift
//  debug3
//
//  Created by Семён Кондаков on 15.03.2022.
//

func custom_rand(t: Int) -> Int {
    return Int.random(in: 0...(t - 1)) - Int.random(in: 0...(t - 1))
}

func sign(num: Int) -> Int {
    if num < 0 {
        return -1
    }
    else {
        return 1
    }
}

class Square_Map {
    var amount_of_resources = 6
    // Карта высот.
    var interpolated_map = [[Int]]()
    // Карта ресурсов.
    var resources = [[Int]]()
    // Координаты первого игрока
    var first_x = 0
    var first_y = 0
    // Координаты второго игрока.
    var second_x = 0
    var second_y = 0
    // ---------------------------------------Вспомонательные массивы---------------------------------------
    var stock = [[Square]]()
    var under_development: Deque<(Int, Int)> = []
    var turn_cleaning = [Square]()
    var resources_map = [[Int]]()
    var resources_lists = [[(Int, Int)]]()
    
    // ----------------------------------------------Инициализатор----------------------------------------
    init (length: Int, heigth: Int, sizemap_x: Int, sizemap_y: Int) {
        self.stock = [[Square]](repeating: [Square](repeating: Square(), count: heigth + 2), count: length + 2)
        for i in 0...length + 1 {
            for j in 0...heigth + 1 {
                self.stock[i][j] = Square()
            }
        }
        self.resources_lists = [[(Int, Int)]](repeating: [(Int, Int)](), count: self.amount_of_resources)
        self.interpolated_map = [[Int]](repeating: [Int](repeating: 0, count: sizemap_y), count: sizemap_x)
        self.resources_map = [[Int]](repeating: [Int](repeating: 0, count: sizemap_y), count: sizemap_x)
    }
    
    func neighbors(x: Int, y: Int, step_x: Int = 1, step_y: Int = 1) -> [(Int, Int)] {
        var res = [(Int, Int)]()
        if (x - 1) * step_x > 0 {
            // Проверка на диагональных соседей слева
            if (y - 1) * step_y > 0 {
                res.append(((x - 1) * step_x, (y - 1) * step_y))
            }
            if (y + 1) * step_y < self.stock[0].count {
                res.append(((x - 1) * step_x, (y + 1) * step_y))
            }
            // Добавляем соседа слева
            res.append(((x - 1) * step_x, y * step_y))
        }
        // А иначе:
        else {
            // Добавляем соседа слева
            res.append((((self.stock.count - 2) / step_x) * step_x, y * step_y))
            // Проверка на диагональных соседей слева
            if (y - 1) * step_y > 0 {
                res.append((((self.stock.count - 2) / step_x) * step_x, (y - 1) * step_y))
            }
            if (y + 1) * step_y < self.stock[0].count {
                res.append((((self.stock.count - 2) / step_x) * step_x, (y + 1) * step_y))
            }
        }
        // Если сосед по х справа находится не на "противоположной" стороне карты, то:
        if (x + 1) * step_x < self.stock.count {
            // Проверка на диагональных соседей справа
            if (y - 1) * step_y > 0 {
                res.append(((x + 1) * step_x, (y - 1) * step_y))
            }
            if (y + 1) * step_y < self.stock[0].count {
                res.append(((x + 1) * step_x, (y + 1) * step_y))
            }
            // Добавляем соседа справа
            res.append(((x + 1) * step_x, y * step_y))
        }
        // А иначе:
        else  {
            // Добавляем соседа справа
            res.append((step_x, y * step_y))
            // Проверка на диагональных соседей справа
            if (y - 1) * step_y > 0 {
                res.append((step_x, (y - 1) * step_y))
            }
            if (y + 1) * step_y < self.stock[0].count {
                res.append((step_x, (y + 1) * step_y))
            }
        }
        // Если сверху есть сосед, то добавим его
        if (y - 1) * step_y > 0 {
            res.append((x * step_x, (y - 1) * step_y))
        }
        // Если снизу есть сосед, то добавим его
        if (y + 1) * step_y < self.stock[0].count {
            res.append((x * step_x, (y + 1) * step_y))
        }
        return res
    }
    
    // "Лопание" клетки с координатами x, y
    func pop(x: Int, y: Int, mode: Int = 1, delta_x: Int = 1, delta_y: Int = 1) -> [(Int, Int)] {
        // Узнаём наших соседей
        var mates = self.neighbors(x: x, y: y, step_x: delta_x, step_y: delta_y)
        // Увеличиваем кол-во их посещений на 1 у каждого
        for coords in mates {
            if self.stock[coords.0][coords.1].count < 3 {
                self.stock[coords.0][coords.1].count += mode
            }
        }
        return mates
    }
    
    // Очистка клеток от "мусора"
    func clear(step_x: Int = 1, step_y: Int = 1) -> Void {
        for i in 1...((self.stock.count - 1) / step_x) {
            for j in 1...((self.stock[0].count - 1) / step_y) {
                self.stock[step_x * i][step_y * j].type = 0
                self.stock[step_x * i][step_y * j].count = 0
                self.stock[step_x * i][step_y * j].turn = 0
            }
        }
    }
    
    func send_speed(_from: (Int, Int), _to: (Int, Int), t: Int, ground_level: Int, speed_cut: Int) -> Void {
        let to = self.stock[_to.0][_to.1]
        let father = self.stock[_from.0][_from.1]
        // Считаем знак нащей функии
        let value = sign(num: to.speed + father.speed + custom_rand(t: t) + (ground_level - father.main))
        to.speed = ((value * (
            to.speed + father.speed + custom_rand(t: t) + (ground_level - father.main))) % speed_cut) * value
    }
    
    func approximaion() -> Void {
        // Указываем размеры апрроксимируемых областей
        let interpolation_x = self.stock.count / (2 * self.interpolated_map.count)
        let interpolation_y = self.stock[0].count / (2 * self.interpolated_map[0].count)
        for map_x in 1...self.interpolated_map.count {
            for map_y in 1...self.interpolated_map[0].count {
                // Создаём счётчики клеток, встречающихся в каждой "области"
                var counters = [Int](repeating: 0, count: 6)
                for x in ((2 * map_x - 2) * interpolation_x)...((2 * map_x) * interpolation_x - 1) {
                    for y in ((2 * map_y - 2) * interpolation_y)...((2 * map_y) * interpolation_y - 1) {
                        // Считаем, сколько клеток каждого типа встретилось на каждой из областей
                        counters[self.stock[x][y].id] += 1
                    }
                }
                // Пишем id самой часто встречающейся клетки в соотвествующую клетку аппроксимированной карты высот
                let it = counters.firstIndex(of: counters.max() ?? 0)
                if ((it ?? 0) <= 1) {
                    self.interpolated_map[map_x - 1][map_y - 1] = 1
                } else {
                    self.interpolated_map[map_x - 1][map_y - 1] = it ?? 00
                }
                // Добавляем клетку, если она - не в центре карты.
                if (((map_x - 1) < (self.interpolated_map.count / 2) - 2) || ((map_x - 1) > (self.interpolated_map.count / 2) + 2)) && (((map_y - 1) < (self.interpolated_map[0].count / 2) - 2) || ((map_y - 1) > (self.interpolated_map[0].count / 2) + 2)) {
                    self.resources_lists[it ?? 0].append((map_x - 1, map_y - 1))
                }
            }
        }
        // Устанавливаем центр карты высот == холму (на него в дальнейшем ставим крепость)
        for x in 0...4 {
            for y in 0...4 {
                self.interpolated_map[(self.interpolated_map.count / 2) - 2 + x][(self.interpolated_map[0].count / 2) + y] = 3
            }
        }
    }
    
    func heigths_approximation() -> Void {
        let borders = [40, 48, 65, 77, 94]
        // Проходимся по всем клеткам карты
        
        for array in self.stock {
            for item in array {
                // Усредняем высоту по всем принятым значениям
                if item.delta > 0 {
                    item.height = item.height / item.delta
                }
                var counter = 0
                var checker = true
                // В зав-ти от высоты клетки, присваиваем ей свой "биом"
                while (counter < borders.count) && checker {
                    if item.height <= borders[counter] {
                        item.id = counter
                        checker = false
                    }
                    else {
                        counter += 1
                    }
                }
                if counter == 5 {
                    item.id = counter
                }
            }
        }
    }
    
    // Убираем промежуточные значения из карты высот
    func clean_buffer() -> Void {
        for guy in self.turn_cleaning {
            guy.turn = 0
            guy.count = 0
            guy.main = 0
            guy.speed = 0
        }
        while (!self.under_development.isEmpty) {
            self.under_development.popFirst()
        }
        self.turn_cleaning.removeAll()
    }
    
    //----------------------------------------Смысловые функции--------------------------------------------

    func initialize_center(x: Int, y: Int) -> Void {
        self.stock[x][y].count = 3
        self.stock[x][y].type = 1
        self.stock[x][y].typeres = Int.random(in: 1...2)
        self.stock[x][y].turn = 1
    }
    
    func continent_tipisation(x: Int, y: Int) -> Void {
        self.stock[x][y].type = 1
        if self.stock[x][y].typeres == 0 {
            self.stock[x][y].typeres = Int.random(in: 1...2)
        }
        else {
            self.stock[x][y].typeres = 3
        }
    }
    
    func popping_initialisation(coords: (Int, Int), radius: Int, counter: Int) -> Void {
        let cur_stock = self.stock[coords.0][coords.1]
        cur_stock.main = (cur_stock.main + cur_stock.speed) / cur_stock.count
        cur_stock.speed = cur_stock.speed / cur_stock.count
        cur_stock.delta += (radius - counter)
        cur_stock.height += cur_stock.main * (radius - counter)
    }
    
    func biome_initialisation(center_x: Int, center_y: Int, normal: [Int], radius: Int, t: Int) -> Void {
        var center = self.stock[center_x][center_y]
        center.main = normal[center.typeres]
        center.turn = 1
        // Изменение итоговой высоты на значение, пропорциональное близости к центру генерации
        
        center.height = center.main * radius
        center.delta += radius
        let mates = pop(x: center_x, y: center_y, mode: 3)
        
        for mate in mates {
            let square_mate = self.stock[mate.0][mate.1]
            self.send_speed(_from: (center_x, center_y), _to: mate, t: t, ground_level: normal[center.typeres], speed_cut: 20)
            
            square_mate.main = center.main * 3
            square_mate.speed *= 3
            square_mate.turn = 1
            self.under_development.append(mate)
            self.turn_cleaning.append(square_mate)
        }
        center.count = 4
        center.main = 0
        center.speed = 0
    }
    
    func add_to_development(mate: (Int, Int)) -> Void {
        self.stock[mate.0][mate.1].turn = 1
        self.under_development.append(mate)
        self.turn_cleaning.append(self.stock[mate.0][mate.1])
    }
    
    func speed_parameters_choosing(center_x: Int, center_y: Int, coords: (Int, Int), mate: (Int, Int), t: Int, normal: [Int]) -> Void {
        let center = self.stock[center_x][center_y]
        let father = self.stock[coords.0][coords.1]
        let borders = [[40, 48],
                       [49, 66],
                       [54, 86],
                       []]
        let middle_heights = [[normal[0], 45, normal[1]],
                              [43, normal[1], normal[2]],
                              [45, normal[2], normal[3]],
                              [normal[3]]]
        let speed_limit_borders = [[20, 20, 1000],
                                   [20, 20, 20],
                                   [20, 20, 20],
                                   [30]]
        var counter = 0
        var ckecker = true
        // В зав-ти от высоты клетки, присваиваем ей свой "биом"
        while (counter < borders[center.typeres].count) && ckecker {
            if father.main < borders[center.typeres][counter] {
                self.send_speed(_from: coords, _to: mate, t: t, ground_level: middle_heights[center.typeres][counter],
                                speed_cut: speed_limit_borders[center.typeres][counter])
                ckecker = false
            }
            else {
                counter += 1
            }
        }
        if ckecker {
            self.send_speed(_from: coords, _to: mate, t: t, ground_level: middle_heights[center.typeres][counter],
                            speed_cut: speed_limit_borders[center.typeres][counter])
        }
    }
    
    func generate_resources() -> Void {
        var count_amounts = [Int]()
        let dispersion_koef = [10, 10, 15]
        // Заполняем кол-во ресурсов.
        for i in 0...2 {
            count_amounts.append(self.resources_lists[i + 2].count / dispersion_koef[i])
        }
        // Считаем кол-во кустов.
        count_amounts.append((self.resources_lists[3].count + self.resources_lists[2].count) / 10)
        // Генерируем все ресурсы. (кроме кустов)
        for it in 0...(count_amounts.count - 2) {
            //  Выбираем n раз клетки соотв. биомов, на которых генерруем ресурсы.
            for _ in 0...(count_amounts[it] - 1) {
                let pos = Int.random(in: 0...(self.resources_lists[it + 2].count - 1))
                let coords = self.resources_lists[it + 2][pos]
                self.resources_map[coords.0][coords.1] = it + 1
                self.resources_lists[it + 2].remove(at: pos)
            }
        }
        // Генерируем все кусты. (на равниинах + холмах)
        for _ in 0...(count_amounts[3] - 1) {
            let pos = Int.random(in: 0...(self.resources_lists[2].count + self.resources_lists[3].count - 1))
            var coords = (0, 0)
            if (pos >= self.resources_lists[2].count) {
                coords = self.resources_lists[3][pos - self.resources_lists[2].count]
            }
            else {
                coords = self.resources_lists[2][pos]
            }
            self.resources_map[coords.0][coords.1] = 4
            if (pos >= self.resources_lists[2].count) {
                self.resources_lists[3].remove(at: pos - self.resources_lists[2].count)
            }
            else {
                self.resources_lists[2].remove(at: pos)
            }
        }
        // Генерируем замок.
        self.resources_map[self.interpolated_map.count / 2][(self.interpolated_map[0].count / 2) + 2] = 5
    }
    
    func generate_users() -> Void {
        self.first_x = Int.random(in: 0...(self.interpolated_map.count / 3))
        self.first_y = Int.random(in: (self.interpolated_map.count / 3)...((2 * self.interpolated_map.count) / 3))
        self.second_x = Int.random(in: ((2 * self.interpolated_map.count) / 3)...(self.interpolated_map.count - 1))
        self.second_y = Int.random(in: (self.interpolated_map.count / 3)...((2 * self.interpolated_map.count) / 3))
    }
}

// Генерация одного континента
func continent_generate(map: Square_Map, center_x: Int, center_y: Int, size_of_chunks_x: Int, size_of_chunks_y: Int, continent_size: Int) {
    // Инициализация очереди обработки
    var under_development: Deque<(Int, Int)> = []
    under_development.append((size_of_chunks_x * center_x, size_of_chunks_y * center_y))
    // Инициализация счётчиков
    var size_of_generated_continent = 0
    var number_of_targets = 0
    // Генерируем континент
    while size_of_generated_continent < continent_size {
        let size_of_queue = under_development.count
        // Идём по всем обрабатываемым центрам генерации суши
        if size_of_queue > 0 {
            for _ in 0...(size_of_queue - 1) {
                // Инициализация данных, используемых далее, и счётчиков
                number_of_targets += 1
                let rand = Int.random(in: 0...100)
                var counter = 0

                // Работаем с "лопающейся" клеткой
                let coords = under_development.popFirst()
                let mates = map.pop(x: (coords?.0 ?? 0) / size_of_chunks_x, y: (coords?.1 ?? 0) / size_of_chunks_y, mode: 1, delta_x: size_of_chunks_x, delta_y: size_of_chunks_y)

                // Работа с соседями лопающейся клетки
                for mate in mates {
                    let square_mate = map.stock[mate.0][mate.1]
                    if square_mate.type == 1 {
                        counter += 1
                    }
                    if square_mate.turn == 0 && square_mate.count >= 3 {
                        under_development.append(mate)
                        map.stock[mate.0][mate.1].turn = 1
                    }
                }

                // Работа непосредственно с лопающейся клeткой
                if map.stock[coords?.0 ?? 0][coords?.1 ?? 0].type == 0 {
                    if rand < counter * 28 {
                        map.continent_tipisation(x: coords?.0 ?? 0, y: coords?.1 ?? 0)
                    }
                }
            }
        }
        size_of_generated_continent += 1
    }
}

// Генерация всех образов континентов
func generate_map_of_continents(map: Square_Map, size_of_chunks_x: Int, size_of_chunks_y: Int, number_of_chunks_x: Int, number_of_chunks_y: Int, number_of_continents: Int, size: Int) {
    var numof_generated_continents = 0
    while numof_generated_continents < number_of_continents {
        // Ищем центр генерируемого континента
        let rand_x = Int.random(in: 1...number_of_chunks_x)
        let rand_y = Int.random(in: 1...number_of_chunks_y)
        if map.stock[size_of_chunks_x * rand_x][size_of_chunks_y * rand_y].typeres == 0 {
            // Инициализируем центр континента
            map.initialize_center(x: size_of_chunks_x * rand_x, y: size_of_chunks_y * rand_y)
            // Собираем прямых соседей выбранного центра генерации
            let mates = map.pop(x: rand_x, y: rand_y, mode: 2, delta_x: size_of_chunks_x, delta_y: size_of_chunks_y)
            // Работа с прямыми соседями
            for mate in mates {
                let rand = Int.random(in: 1...50) + Int.random(in: 1...50)
                // Заполняем соседей данными о посещаемости и типе биома
                if rand < 85 {
                    map.continent_tipisation(x: mate.0, y: mate.1)
                }
            }

            // Генерируем континент
            continent_generate(map: map, center_x: rand_x, center_y: rand_y, size_of_chunks_x: size_of_chunks_x, size_of_chunks_y: size_of_chunks_y, continent_size: size)

            // Обнуляем все поля генерации для их дальнейшего заполнения
            map.clear(step_x: size_of_chunks_x, step_y: size_of_chunks_y)

            // Увеличиваем количество континентов
            numof_generated_continents += 1
        }

    }
}

// Генерация рельефа в конкретном биоме
func generate_chunk(map: Square_Map, center_x: Int, center_y: Int, radius: Int, normal: [Int], t: Int) {
    var counter = 0
    while counter < radius {
        let size_of_queue = map.under_development.count
        // Идём по "радиусу" лопнутых клеток
        if size_of_queue > 0 {
            for _ in 0...(size_of_queue - 1) {
                // Узнаём, какую клетку сейчас нужно "лопнуть"
                let coords = map.under_development.popFirst()
                let father = map.stock[coords?.0 ?? 0][coords?.1 ?? 0]

                // Заполнение "лопающейся" клетки
                map.popping_initialisation(coords: coords ?? (0, 0), radius: radius, counter: counter)

                // Лопаем клетку
                let mates = map.pop(x: coords?.0 ?? 0, y: coords?.1 ?? 0)
                // Идём по соседям лопающейся клетки
                for mate in mates {
                    let square_mate = map.stock[mate.0][mate.1]

                    // Проверяем, не "лопнул" ли сосед клетки раньше?
                    if square_mate.turn == 0 {
                        // Увеличиваем высоту соседа "лопающейся" клетки
                        square_mate.main += father.main

                        // Если клетка получила данные с как минимум трёх соседей, то на "лопается" (добавляется к обрабатываемым)
                        if square_mate.count >= 3 {
                            map.add_to_development(mate: mate)
                        }
                        // В зависимости от типа местности, передаём сосседям разную скорость изменения высоты
                        map.speed_parameters_choosing(center_x: center_x, center_y: center_y, coords: coords ?? (0, 0), mate: mate, t: t, normal: normal)
                    }
                }
                // Чистим "лопнутого" соседа
                father.main = 0
                father.speed = 0
            }
        }
        counter += 1
    }
    // Чистим все системные значения, для следующих итераций.
    map.clean_buffer()
}

// Генерация рельефа на всей карте
func generate_landscape(map: Square_Map, number_of_chunks_x: Int, number_of_chunks_y: Int, size_of_chunks_x: Int, size_of_chunks_y: Int, normal: [Int], t: Int) {
    // Идём по всем чанкам
    for i in 1...number_of_chunks_x {
        for j in 1...number_of_chunks_y {
            // Считаем расстояние, до которого будут генерироваться очаги генерации
            let radius = max((2 * (map.stock.count / (number_of_chunks_x + 1)) + 8),
                         (2 * (map.stock[0].count / (number_of_chunks_y + 1)) + 8))

            let center_x = i * size_of_chunks_x
            let center_y = j * size_of_chunks_y
            // Инициализируем центр чанка
            map.biome_initialisation(center_x: center_x, center_y: center_y, normal: normal, radius: radius, t: t)
            // Генерируем "чанк"
            generate_chunk(map: map, center_x: center_x, center_y: center_y, radius: radius, normal: normal, t: t)
        }
    }
}

// Генерация карты
func map_generator(sizemap_x: Int, sizemap_y: Int, number_of_continents: Int) -> Map {
    let normal = [15, 59, 71, 96]
    let size = 20
    let t = 11
    // Длина карты до аппроксимации
    let length = sizemap_x * 4
    // Высота карты до аппроксимации
    let heigth = sizemap_y * 4
    let number_of_chunks_x = length / 25
    let number_of_chunks_y = heigth / 25

    // Задаём необходимый размер карты
    let map = Square_Map(length: length, heigth: heigth, sizemap_x: sizemap_x, sizemap_y: sizemap_y)

    let size_of_chunks_x = length / (number_of_chunks_x + 1)
    let size_of_chunks_y = heigth / (number_of_chunks_y + 1)

    // Генерируем карту континентов
    generate_map_of_continents(map: map, size_of_chunks_x: size_of_chunks_x, size_of_chunks_y: size_of_chunks_y, number_of_chunks_x: number_of_chunks_x, number_of_chunks_y: number_of_chunks_y, number_of_continents: number_of_continents, size: size)

    // Уведомляем об успешном размещении материков на образе карты
    print("Generating_started")

    // Генерируем высоты континента
    generate_landscape(map: map, number_of_chunks_x: number_of_chunks_x, number_of_chunks_y: number_of_chunks_y, size_of_chunks_x: size_of_chunks_x, size_of_chunks_y: size_of_chunks_y, normal: normal, t: t)
    
    // Аппроксимация высот карты
    map.heigths_approximation()

    // Аппроксимация клеток карты
    map.approximaion()

    // КАРТА СОБРАНА В map.interpolated_map.
    map.generate_resources()
    let field = Map()
    field.heights = map.interpolated_map
    field.resources = map.resources_map
    field.first_x = map.first_x
    field.second_x = map.second_x
    field.first_y = map.first_y
    field.second_y = map.second_y
    return field
}






