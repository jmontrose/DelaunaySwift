//
//  Triangle.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//

import MapKit

func sorted(_ points:[MKMapPoint]) -> [MKMapPoint] {
    return points.sorted { (a, b) -> Bool in
        (a.x, a.y) > (b.x, b.y)
    }
}

public struct Edge: Hashable, Equatable {
    let a:MKMapPoint
    let b:MKMapPoint
    let distance:CLLocationDistance
    
    var points:[MKMapPoint] {
        return [a, b]
    }
    
    init(_ a:MKMapPoint, _ b:MKMapPoint) {
        let p = sorted([a, b])
        self.a = p[0]
        self.b = p[1]
        self.distance = self.a.distance(to: self.b)
    }
    
    func contains(_ point:MKMapPoint) -> Bool {
        return points.contains(point)
    }

    func contains(_ query:[MKMapPoint]) -> Bool {
        let missing = query.filter { p in
            !points.contains(p)
        }
        return missing.isEmpty
    }
}

/// A simple struct representing 3 points
public struct Triangle: Hashable, Equatable {

    public init(_ points: [MKMapPoint]) {
        let p = sorted(points)
        self.point1 = p[0]
        self.point2 = p[1]
        self.point3 = p[2]
        self.edges = [
            (self.point1, self.point2),
            (self.point2, self.point3),
            (self.point3, self.point1),
        ].map {
            a, b in
            Edge(a, b)
        }
    }

    public init(point1: MKMapPoint, point2: MKMapPoint, point3: MKMapPoint) {
        self.init([point1, point2, point3])
    }
    
    public let point1: MKMapPoint
    public let point2: MKMapPoint
    public let point3: MKMapPoint
    
    public let edges: [Edge]
    
    public var points:[MKMapPoint] {
        return [point1, point2, point3]
    }
    
    public func edges(for point:MKMapPoint) -> Set<Edge> {
        return Set(edges.filter { edge in
            edge.contains(point)
        })
    }

    public func edges(for query:[MKMapPoint]) -> Set<Edge> {
        assert(query.count == 1 || query.count == 2)
        return Set(edges.filter { edge in
            edge.contains(query)
        })
    }


}
