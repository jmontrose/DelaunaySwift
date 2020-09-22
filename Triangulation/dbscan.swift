//
//  File.swift
//  Triangulation
//
//  Created by Jesse Montrose on 9/22/20.
//  Copyright © 2020 zero. All rights reserved.
//

import MapKit

class DBScan {
    var clusters = [DBCluster]()
    let eps:Double
    let min:Int
    var vertices = Set<DBVertex>()
    let triangles:[Triangle]
    
    init(_ triangles:[Triangle], eps:Double, min:Int) {
        self.triangles = triangles
        self.eps = eps
        self.min = min
    }
    
    func run() {
        var vertexMap = [MKMapPoint:DBVertex]()
        
        for triangle in triangles {
            let triVertices:[DBVertex] = triangle.points.map { point in
                if vertexMap[point] == nil {
                    vertexMap[point] = DBVertex(point)
                }
                return vertexMap[point]!
            }
            for v in triVertices {
                v.addNeighbors(triVertices)
            }
        }
        
        for v in vertexMap.values {
            vertices.update(with: v)
        }
        
        print("run vertices:\(vertices.count)")
        let ns = vertices.map { $0.neighbors.count }
        var hist = [Int:Int]()
        for n in ns {
            hist[n, default:0] += 1
        }
        print("hist \(hist)")
        
        var todo = Array(vertices)
        while !todo.isEmpty {
            if let vertex = todo.popLast() {
                process(vertex)
            }
        }
    }
    
    func process(_ vertex:DBVertex) {
        print("proc \(vertex)")
        for v in neighborhoodFor(vertex) {
            let distance = vertex.point.distance(to: v.point)
            print("   neighbor \(v) distance \(distance)")
        }
    }
    
    func neighborhoodFor(_ vertex:DBVertex) -> Set<DBVertex> {
        var extendedHood = Set<DBVertex>()
        func neighborCheck(_ candidate:DBVertex) -> Bool {
            if candidate == vertex {
                //print("     skip center")
                return false
            }
            let d = vertex.point.distance(to: candidate.point)
            //print("     distance \(d)")
            return vertex.point.distance(to: candidate.point) < 100.0
        }
        extendedHood = buildNeighborhood(extendedHood, center:vertex, next: vertex.neighbors, check:neighborCheck, depth: 1)
        return extendedHood
    }
    
    func buildNeighborhood(_ hood:Set<DBVertex>, center:DBVertex, next:Set<DBVertex>, check:(DBVertex)->Bool, depth:Int) -> Set<DBVertex> {
        var result = Set(hood)
        let keep = next.filter(check)
        //print("keep \(keep.count) of \(next.count)")
        result.formUnion(keep)
        if depth > 0 {
            keep.forEach { vertex in
                result.formUnion(buildNeighborhood(result, center: center, next: vertex.neighbors, check:check, depth: depth-1))
            }
        }
        return result
    }
}

class DBCluster {
    var vertices = [DBVertex]()
}

enum VertexState: String {
    case pending
    case core
    case border
    case noise
}

class DBVertex: CustomStringConvertible, Hashable {
    static func == (lhs: DBVertex, rhs: DBVertex) -> Bool {
        return lhs.point == rhs.point
    }
    
    let point:MKMapPoint
    var neighbors = Set<DBVertex>()
    let cluster:DBCluster? = nil
    let state:VertexState = .pending
    
    init(_ point:MKMapPoint) {
        self.point = point
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(point)
    }
    
    func addNeighbors(_ vertices:[DBVertex]) {
        for v in vertices {
            if v != self {
                neighbors.update(with: v)
            }
        }
    }
    
    var color:CGColor {
        switch state {
        case .pending:
            return UIColor.orange.cgColor
        case .core:
            return UIColor.orange.cgColor
        case .border:
            return UIColor.orange.cgColor
        case .noise:
            return UIColor.orange.cgColor
        }
    }
    
    var description: String {
        return "Vertex \(state) \(neighbors.count)"
    }
}
