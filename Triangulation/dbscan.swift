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
    let vertices:[DBVertex]

    init(_ vertices:[DBVertex], eps:Double, min:Int) {
        self.vertices = vertices
        self.eps = eps
        self.min = min
    }
    
    func run() {
        var todo = vertices
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

class DBVertex: CustomStringConvertible {
    let point:MKMapPoint
    var neighbors = [DBVertex]()
    let cluster:DBCluster? = nil
    let state:VertexState = .pending
    
    init(_ point:MKMapPoint) {
        self.point = point
    }
    
    var description: String {
        return "Vertex \(state)"
    }
}
