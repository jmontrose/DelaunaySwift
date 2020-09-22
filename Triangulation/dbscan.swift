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
    let radius:Double
    let min:Int
    var vertices = Set<DBVertex>()
    let triangles:[Triangle]
    
    init(_ triangles:[Triangle], radius:Double, min:Int) {
        self.triangles = triangles
        self.radius = radius
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
        
        var todo = Array(vertices)
        while !todo.isEmpty {
            if let vertex = todo.popLast() {
                process(vertex)
            }
        }
        
        let states = vertices.map { $0.state }
        var hist = [VertexState:Int]()
        for s in states {
            hist[s, default:0] += 1
        }
        print("hist \(hist)")

    }
    
    func process(_ vertex:DBVertex) {
        let hood = neighborhoodFor(vertex)
        if hood.count >= self.min {
            vertex.ratchet(state: .core)
        } else {
            vertex.ratchet(state: .noise)
        }
        print("proc \(vertex) hood:\(hood.count)")
        for neighbor in hood {
            neighbor.ratchet(state: .border)
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
            return vertex.point.distance(to: candidate.point) < radius
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
    var state:VertexState = .pending
    
    init(_ point:MKMapPoint) {
        self.point = point
    }
    
    func ratchet(state newState:VertexState) {
        switch newState {
        case .pending:
            fatalError()
        case .core:
            state = .core
        case .border:
            if state != .core {
                state = .border
            }
        case .noise:
            if state == .pending {
                state = .noise
            }
        }
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
            return UIColor.blue.cgColor
        case .border:
            return UIColor.green.cgColor
        case .noise:
            return UIColor.red.cgColor
        }
    }
    
    var description: String {
        return "Vertex \(state) \(neighbors.count)"
    }
}
