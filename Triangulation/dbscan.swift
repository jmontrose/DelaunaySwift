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
