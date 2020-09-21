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

func makePoints(_ nums:[[Double]]) -> [Point] {
    return nums.map { i in
        Point(x: i[0], y: i[1])
    }
}

func normalize(_ points:[Point]) -> [Point] {
    let xs = points.map { $0.x }
    let ys = points.map { $0.y }
    let pmin = CGSize(width: xs.min()!, height: ys.min()!)
    let pmax = CGSize(width: xs.max()!, height: ys.max()!)
    let pspan = CGSize(width: pmax.width - pmin.width, height: pmax.height - pmin.height)
    print ("NORM pspan:\(pspan)")
    return points.map { p in
        let x = (p.x - Double(pmin.width)) / Double(pspan.width)
        let y = (p.y - Double(pmin.height)) / Double(pspan.height)
        return Point(x:x, y:y)
    }

}
