//
//  File.swift
//  Triangulation
//
//  Created by Jesse Montrose on 9/22/20.
//  Copyright © 2020 zero. All rights reserved.
//

import MapKit

enum CounterType {
    case distanceEval
}

class DBScan {
    var clusters = [DBCluster]()
    let radius:Double
    let min:Int
    let depth = 6
    var vertices = Set<DBVertex>()
    var vertexMap = [MKMapPoint:DBVertex]()
    let triangles:[Triangle]
    var triangleToVertices = [Triangle:[DBVertex]]()
    
    var counters = [CounterType:Int]()
    
    init(_ triangles:[Triangle], radius:Double, min:Int) {
        self.triangles = triangles
        self.radius = radius
        self.min = min
        
        var s = Set<Triangle>()
        for t in self.triangles {
            s.insert(t)
        }
        if triangles.count != s.count {
            var a = Set(triangles)
            let off = a.symmetricDifference(s)
            print("INIT \(triangles.count) \(s.count) \(off)")
            
        }
    }
    
    func run() {
        for triangle in triangles {
            let triVertices:[DBVertex] = triangle.points.map { point in
                if vertexMap[point] == nil {
                    vertexMap[point] = DBVertex(point)
                }
                return vertexMap[point]!
            }
            for v in triVertices {
                v.addNeighbors(triVertices)
                v.add(triangle)
            }
            triangleToVertices[triangle] = triVertices
        }
        
        for v in vertexMap.values {
            vertices.update(with: v)
        }
        
        // compute neighbor proximity lists
        var phist = [Int:Int]()
        for vertex in vertices {
            let extendedHood = neighborhoodFor(vertex)
            let hoodEdges = extendedHood.map {
                return VertexEdge(vertex, $0)
            }
            vertex.proximity = hoodEdges.filter { candidate in
                candidate.edge.distance < radius
            }.sorted { $0.edge.distance < $1.edge.distance }
            phist[vertex.proximity.count, default: 0] += 1
        }
        print("made proximities \(phist)")
        print("run vertices:\(vertices.count)")
        
        var todo = Array(vertices)
        var loopRadius = 10.0
        while !todo.isEmpty {
            todo.sort {
                $0.vertexEdgesWithin(loopRadius).count < $1.vertexEdgesWithin(loopRadius).count
            }
            let vertex = todo.removeFirst()
            process(vertex)
        }
        
        let states = vertices.map { $0.state }
        var hist = [VertexState:Int]()
        for s in states {
            hist[s, default:0] += 1
        }
        for cluster in clusters {
            print("    \(cluster)")
        }
        print("hist \(hist) clusters:\(clusters.count)")
        print("counters \(counters)")
    }
    
    func increment(_ counter:CounterType, by value:Int=1) {
        counters[counter, default:0] += 1
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
            guard let vertexCluster = vertex.cluster else {
                fatalError()
            }

            print("proc \(vertex) hood:\(hood.count)")
            for neighbor in hood {
                neighbor.ratchet(state: .border)
                vertexCluster.add(neighbor)
            }
        } else {
            vertex.ratchet(state: .noise)
        }
    }
    
    func neighborhoodFor(_ vertex:DBVertex) -> Set<DBVertex> {
        var extendedHood = buildNeighborhood([], center:vertex, depth: self.depth)
        extendedHood.remove(vertex) // ignore seed
        
        // filter on direct distance, instead of hop
        let nearby = extendedHood.filter { candidate in
            let distance = vertex.point.distance(to: candidate.point)
            return distance < radius
        }
        //print("range check: \(extendedHood.count) down to \(nearby.count)")
        return nearby
    }
    
    func buildNeighborhood(_ hood:Set<DBVertex>, center:DBVertex, depth:Int) -> Set<DBVertex> {
        var result = Set(hood)
        let keep = center.computedNeighborsWithin(radius)
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
    var edges = Set<Edge>()
    
    /// Sorted list of neighbors within `radius`
    var proximity = [VertexEdge]()
    var triangles = Set<Triangle>()
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
    
    func edge(for neighbor:DBVertex) -> Edge? {
        let found = edges.filter {
            $0.contains([point, neighbor.point])
        }
        assert(found.count == 1)
        //print("found \(found.count) edges")
        return found.first!
    }
    
    func addNeighbors(_ vertices:[DBVertex]) {
        for v in vertices {
            if v != self {
                neighbors.insert(v)
            }
        }
    }
    
    func vertexEdgesWithin(_ radius:CLLocationDistance) -> [VertexEdge] {
        return proximity.prefix(while: {
            $0.edge.distance < radius
        })
    }
    
    func neighborsWithin(_ radius:CLLocationDistance) -> [DBVertex] {
        return vertexEdgesWithin(radius).map {
                $0.other(from: self)
        }
//        return neighbors.filter { candidate in
//            guard let edge = self.edge(for: candidate) else {
//                print("missing edge \(self.point) \(candidate.point)")
//                fatalError()
//            }
//            return edge.distance < radius
//        }
    }
    
    func computedNeighborsWithin(_ radius:CLLocationDistance) -> [DBVertex] {
        return neighbors.filter { candidate in
            guard let edge = self.edge(for: candidate) else {
                print("missing edge \(self.point) \(candidate.point)")
                fatalError()
            }
            return edge.distance < radius
        }
    }
    
    func add(_ triangle:Triangle) {
        //print("Add \(triangle) to \(triangles.count)")
        for t in triangles {
            let eq = triangle == t
            //print("   existing: \(t) \(eq)")
        }
        triangles.update(with: triangle)
        let newEdges = triangle.edges(for: self.point)
        assert(newEdges.count == 2)
        edges.formUnion(newEdges)
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

/// Struct for all pairs, not just delaunay
struct VertexEdge: Hashable {
    let edge:Edge
    let a:DBVertex
    let b:DBVertex
    
    init(_ a:DBVertex, _ b:DBVertex) {
        let e = Edge(a.point, b.point)
        // edge points are sorted, match them back up
        if a.point == e.a && b.point == e.b {
            self.a = a
            self.b = b
            self.edge = e
            return
        }
        // reverse sort
        if a.point == e.b && b.point == e.a {
            self.a = b
            self.b = a
            self.edge = e
            return
        }
        fatalError()
    }

    func other(from vertex:DBVertex) -> DBVertex {
        if vertex == a {
            return b
        }
        if vertex == b {
            return a
        }
        fatalError()
    }
}


