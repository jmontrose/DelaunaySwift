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
    let depth = 6
    var vertices = Set<DBVertex>()
    let triangles:[Triangle]
    var triangleToVertices = [Triangle:[DBVertex]]()
    
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
            triangleToVertices[triangle] = triVertices
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
        print("hist \(hist) clusters:\(clusters.count)")
        for cluster in clusters {
            print("    \(cluster)")
        }
    }
    
    func makeCluster() -> DBCluster {
        let cluster = DBCluster()
        clusters.append(cluster)
        cluster.number = clusters.count
        return cluster
    }
    
    func process(_ vertex:DBVertex) {
        if vertex.state != .pending && vertex.state != .border {
            return
        }
        let hood = neighborhoodFor(vertex)
        if hood.count >= self.min {
            vertex.ratchet(state: .core)
            if vertex.cluster == nil {
                let cluster = makeCluster()
                cluster.add(vertex)
            }
        } else {
            vertex.ratchet(state: .noise)
        }
        print("proc \(vertex) hood:\(hood.count)")
        for neighbor in hood {
            neighbor.ratchet(state: .border)
            if let cluster = vertex.cluster {
                cluster.add(neighbor)
            } else {
                
            }
        }
    }
    
    func neighborhoodFor(_ vertex:DBVertex) -> Set<DBVertex> {
        var extendedHood = buildNeighborhood([], center:vertex, depth: self.depth)
        extendedHood.remove(vertex) // ignore seed
        return extendedHood
    }
    
    func buildNeighborhood(_ hood:Set<DBVertex>, center:DBVertex, depth:Int) -> Set<DBVertex> {
        var result = Set(hood)
        let keep = center.neighbors.filter { candidate in
            center.point.distance(to: candidate.point) < radius
        }
        //print("keep \(keep.count) of \(next.count)")
        result.formUnion(keep)
        if depth > 0 {
            keep.forEach { vertex in
                result.formUnion(buildNeighborhood(result, center: vertex, depth: depth-1))
            }
        }
        return result
    }
}

class DBCluster: CustomStringConvertible {
    var vertices = Set<DBVertex>()
    var color = UIColor().randomColor().cgColor
    var number = 0
    
    func add(_ vertex:DBVertex) {
        if let oldCluster = vertex.cluster {
            if oldCluster.number == self.number {
                //print("    - skip overwrite \(oldCluster)")
                return
            }
            print("    - overwrite \(oldCluster) with \(self)")
        }
        //assert(vertex.cluster == nil)
        //assert(!vertices.contains(vertex))
        if vertices.contains(vertex) {
            print("    - double-set vertex cluster")
        }

        self.vertices.insert(vertex)
        vertex.cluster = self
    }
    
    var description: String {
        return "<Cluster \(number) count:\(vertices.count)>"
    }
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
    var cluster:DBCluster? = nil
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
        if let cluster = self.cluster {
            return cluster.color
        }
        
        switch state {
        case .pending:
            return UIColor.orange.cgColor
        case .core:
            return UIColor.blue.cgColor
        case .border:
            return UIColor.green.cgColor
        case .noise:
            return UIColor.black.cgColor
        }
    }
    
    var description: String {
        return "Vertex \(state) cluster:\(cluster?.number) \(neighbors.count)"
    }
}
