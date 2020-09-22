//
//  Circumcircle.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//

import MapKit

/// Represents a circle which intersects a set of 3 points
internal struct Circumcircle: Hashable, Equatable {
    let point1: MKMapPoint
    let point2: MKMapPoint
    let point3: MKMapPoint
    let x: Double
    let y: Double
    let rsqr: Double
}
