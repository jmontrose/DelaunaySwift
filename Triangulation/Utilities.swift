//
//  Utilities.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//

import UIKit
import DelaunaySwift
import MapKit

extension Triangle {
    func toPath() -> CGPath {
        
        let path = CGMutablePath()
        let p1 = point1.pointValue()
        let p2 = point2.pointValue()
        let p3 = point3.pointValue()
        
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.addLine(to: p1)

        path.closeSubpath()
        
        return path
    }
}

extension MKMapPoint {
    public init(point: CGPoint) {
        self.init(x: Double(point.x), y: Double(point.y))
    }
    
    public func pointValue() -> CGPoint {
        return CGPoint(x: x, y: y)
    }
    
    public func inside(_ triangle: Triangle) -> Bool {
        func sign(p: MKMapPoint, v0: MKMapPoint, v1: MKMapPoint) -> Double {
            return (p.x - v1.x) * (v0.y - v1.y) - (v0.x - v1.x) * (p.y - v1.y)
        }
        
        let s1 = sign(p: self, v0: triangle.point1, v1: triangle.point2)
        let s2 = sign(p: self, v0: triangle.point2, v1: triangle.point3)
        let s3 = sign(p: self, v0: triangle.point3, v1: triangle.point1)
        return (s1 * s2 >= 0) && (s2 * s3 >= 0)
    }
}

extension UIColor {
    func randomColor() -> UIColor {
        let hue = CGFloat.random(in: 0...1) // 0.0 to 1.0
        let saturation: CGFloat = 0.5  // 0.5 to 1.0, away from white
        let brightness: CGFloat = 1.0  // 0.5 to 1.0, away from black
        let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        return color
    }
}

extension CGRect {
    var quarter:CGSize {
        return CGSize(width: size.width / 2, height: size.height / 2)
    }
    var mid:CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    var cornerNe:CGRect {
        return CGRect(origin: CGPoint(x: midX, y: origin.y), size: quarter)
    }
}

extension MKMapPoint: Equatable { }
extension MKMapSize: Equatable { }
extension MKMapRect: Equatable { }

public func ==(l: MKMapPoint, r: MKMapPoint) -> Bool { return MKMapPointEqualToPoint(l, r) }
public func ==(l: MKMapSize,  r: MKMapSize)  -> Bool { return MKMapSizeEqualToSize(l, r)   }
public func ==(l: MKMapRect,  r: MKMapRect)  -> Bool { return MKMapRectEqualToRect(l, r)   }

extension MKMapPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
