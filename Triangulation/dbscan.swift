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
        
    }
}

class DBCluster {
    var vertices = [DBVertex]()
}

enum VertexState {
    case pending
    case core
    case border
    case noise
}

class DBVertex {
    let point:MKMapPoint
    var neighbors = [DBVertex]()
    let cluster:DBCluster? = nil
    let state:VertexState = .pending
    
    init(_ point:MKMapPoint) {
        self.point = point
    }
}
