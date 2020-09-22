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
import MapKit

func makePoints(_ nums:[[Double]]) -> [Point] {
    return nums.map { i in
        Point(x: i[0], y: i[1])
    }
}

func makeMapPoints(_ nums:[[Double]]) -> [MKMapPoint] {
    return nums.map { i in
        MKMapPoint(x: i[0], y: i[1])
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

typealias PointConverter = (Point) -> (Point)
func makeNorm(_ points:[Point]) -> PointConverter {
    let xs = points.map { $0.x }
    let ys = points.map { $0.y }
    let pmin = CGSize(width: xs.min()!, height: ys.min()!)
    let pmax = CGSize(width: xs.max()!, height: ys.max()!)
    let pspan = CGSize(width: pmax.width - pmin.width, height: pmax.height - pmin.height)
    print ("NORM pspan:\(pspan)")
    return {
        point in
        let x = (point.x - Double(pmin.width)) / Double(pspan.width)
        let y = (point.y - Double(pmin.height)) / Double(pspan.height)
        return Point(x:x, y:y)
    }
}

func box(from points:[Point]) -> CGRect {
    let xs = points.map { $0.x }
    let ys = points.map { $0.y }
    let pmin = CGPoint(x: xs.min()!, y: ys.min()!)
    let pmax = CGPoint(x: xs.max()!, y: ys.max()!)
    let pspan = CGSize(width: pmax.x - pmin.x, height: pmax.y - pmin.y)
    return CGRect(origin: pmin, size: pspan)
}

