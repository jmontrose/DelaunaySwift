//
//  points.swift
//  Triangulation
//
//  Created by Jesse Montrose on 9/21/20.
//  Copyright © 2020 zero. All rights reserved.
//

import Foundation
import UIKit
import GameplayKit
import DelaunaySwift


func normalize(_ points:[[Double]]) -> [Point] {
    return normalize(points.map { i in
        Point(x: i[0], y: i[1])
    })
}

func normalize(_ points:[Point]) -> [Point] {
    let xs = points.map { $0.x }
    let ys = points.map { $0.y }
    let pmin = CGSize(width: xs.min()!, height: ys.min()!)
    let pmax = CGSize(width: xs.max()!, height: ys.max()!)
    let pspan = CGSize(width: pmax.width - pmin.width, height: pmax.height - pmin.height)
    return points.map { p in
        let x = (p.x - Double(pmin.width)) / Double(pspan.width)
        let y = (p.y - Double(pmin.height)) / Double(pspan.height)
        return Point(x:x, y:y)
    }

}

let points1raw = [
    [ 42900533.43769426, 103790390.88064426],
    [ 42930981.22972111, 103752615.76335593],
    [ 42931312.824051395, 103753516.99365321],
    [ 42931197.28171511, 103753946.05928367],
    [ 42931192.84328994, 103753197.39110324],
    [ 42931199.00879751, 103753233.97658393],
    [ 42931160.10274305, 103753742.22557661],
    [ 42936992.23660926, 103785263.038761],
    [ 42931002.41752477, 103752708.06365767],
    [ 42924654.46006752, 103779730.49611463],
]
let points1 = normalize(points1raw)

