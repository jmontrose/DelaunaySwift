//
//  Triangle.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//

import MapKit

/// A simple struct representing 3 points
public struct Triangle: Hashable, Equatable {

    public init(_ points: [MKMapPoint]) {
        self.point1 = points[0]
        self.point2 = points[1]
        self.point3 = points[2]
    }

    public init(point1: MKMapPoint, point2: MKMapPoint, point3: MKMapPoint) {
        self.point1 = point1
        self.point2 = point2
        self.point3 = point3
    }
    
    public let point1: MKMapPoint
    public let point2: MKMapPoint
    public let point3: MKMapPoint
    
    public var points:[MKMapPoint] {
        return [point1, point2, point3]
    }
    
    public static func == (lhs: Triangle, rhs: Triangle) -> Bool {
        return lhs.point1 == rhs.point1 && lhs.point2 == rhs.point2 && lhs.point3 == lhs.point3
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(point1)
        hasher.combine(point2)
        hasher.combine(point3)
    }
}
