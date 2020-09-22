//
//  TriangleView.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//

import UIKit
import GameplayKit
import MapKit
import DelaunaySwift
//
//struct Circumcircle: Hashable {
//    let point1: MKMapPoint
//    let point2: MKMapPoint
//    let point3: MKMapPoint
//    let x: Double
//    let y: Double
//    let rsqr: Double
//}
//
//func circumcircle(_ triangle:Triangle) -> Circumcircle {
//    return circumcircle(triangle.point1, j: triangle.point2, k: triangle.point3)
//}
//
///// Calculate the intersecting circumcircle for a set of 3 points
//func circumcircle(_ i: MKMapPoint, j: MKMapPoint, k: MKMapPoint) -> Circumcircle {
//    let x1 = i.x
//    let y1 = i.y
//    let x2 = j.x
//    let y2 = j.y
//    let x3 = k.x
//    let y3 = k.y
//    let xc: Double
//    let yc: Double
//
//    let fabsy1y2 = abs(y1 - y2)
//    let fabsy2y3 = abs(y2 - y3)
//
//    if fabsy1y2 < Double.ulpOfOne {
//        let m2 = -((x3 - x2) / (y3 - y2))
//        let mx2 = (x2 + x3) / 2
//        let my2 = (y2 + y3) / 2
//        xc = (x2 + x1) / 2
//        yc = m2 * (xc - mx2) + my2
//    } else if fabsy2y3 < Double.ulpOfOne {
//        let m1 = -((x2 - x1) / (y2 - y1))
//        let mx1 = (x1 + x2) / 2
//        let my1 = (y1 + y2) / 2
//        xc = (x3 + x2) / 2
//        yc = m1 * (xc - mx1) + my1
//    } else {
//        let m1 = -((x2 - x1) / (y2 - y1))
//        let m2 = -((x3 - x2) / (y3 - y2))
//        let mx1 = (x1 + x2) / 2
//        let mx2 = (x2 + x3) / 2
//        let my1 = (y1 + y2) / 2
//        let my2 = (y2 + y3) / 2
//        xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2)
//
//        if fabsy1y2 > fabsy2y3 {
//            yc = m1 * (xc - mx1) + my1
//        } else {
//            yc = m2 * (xc - mx2) + my2
//        }
//    }
//
//    let dx = x2 - xc
//    let dy = y2 - yc
//    let rsqr = dx * dx + dy * dy
//
//    return Circumcircle(point1: i, point2: j, point3: k, x: xc, y: yc, rsqr: rsqr)
//}

extension MKMapPoint {
    static func random(size:CGSize) -> MKMapPoint {
        return MKMapPoint(x: Double.random(in: Double(0)...Double(size.width)), y: Double.random(in: Double(0)...Double(size.height)))
    }
}

func generateNorms(_ points:[MKMapPoint], _ size:CGSize) -> [MKMapPoint] {
    return points.map { p in
        let yfactor = Double(size.width)
        let yoffset = (Double(size.height) / Double(4))
        let my = (p.y * yfactor + yoffset)

        
        //let y = p.y * Double(size.width) + (Double(size.height) / Double(4))
        return MKMapPoint(x: p.x * Double(size.width), y: my)
    }
}

func generateVerticesRandom(_ size: CGSize, count:Int, seed: UInt64 = UInt64.random(in: 0..<UInt64.max)) -> [MKMapPoint] {
    var points = [MKMapPoint]()
    for _ in 0...100 {
        points.append(MKMapPoint.random(size: size))
    }
    return points
}

/// Generate set of points for our triangulation to use
func generateVertices(_ size: CGSize, cellSize: CGFloat, variance: CGFloat = 0.75, seed: UInt64 = UInt64.random(in: 0..<UInt64.max)) -> [MKMapPoint] {
    
    // How many cells we're going to have on each axis (pad by 2 cells on each edge)
    let cellsX = (size.width + 4 * cellSize) / cellSize
    let cellsY = (size.height + 4 * cellSize) / cellSize
    
    // figure out the bleed widths to center the grid
    let bleedX = ((cellsX * cellSize) - size.width)/2
    let bleedY = ((cellsY * cellSize) - size.height)/2
    
    let _variance = cellSize * variance / 4
    
    var points = [MKMapPoint]()
    let minX = -bleedX
    let maxX = size.width + bleedX
    let minY = -bleedY
    let maxY = size.height + bleedY
    
    let generator = GKLinearCongruentialRandomSource(seed: seed)
    
    for i in stride(from: minX, to: maxX, by: cellSize) {
        for j in stride(from: minY, to: maxY, by: cellSize) {
            
            let x = i + cellSize/2 + CGFloat(generator.nextUniform()) + CGFloat.random(in: -_variance..._variance)
            let y = j + cellSize/2 + CGFloat(generator.nextUniform()) + CGFloat.random(in: -_variance..._variance)
            
            points.append(MKMapPoint(x: Double(x), y: Double(y)))
        }
    }
    
    return points
}


struct SimplePoints: Decodable {
    let points:[[Double]]
}

typealias ArrayOfArrays = [[Double]]

class TriangleView: UIView {
    var triangles: [(Triangle, CAShapeLayer)] = []
    var delaunayTriangles = [Triangle]()
    var mkTriangles = [Triangle]()
    var allPoints = [MKMapPoint]()
    //var pointsToTri = [MKMapPoint:[Triangle]]()
    var normConverter:PointConverter? = nil
    
    func loadText(name:String) -> String {
        let url = Bundle(for: type(of: self)).url(forResource: name, withExtension: "")
        guard let dataURL = url else {
            fatalError("Empty \(String(describing: url))")
        }
        guard let data = try? Data(contentsOf: dataURL) else {
            fatalError("Couldn't read \(String(describing: url))")
        }
        let string = String(data:data, encoding: .utf8)!
        return string
    }
    
    func load(_ name:String) -> [MKMapPoint] {
        let raw = loadText(name: name)
        do {
            let simplePoints = try JSONDecoder().decode(ArrayOfArrays.self, from: Data(raw.utf8))
            let p = makePoints(simplePoints)
            return p
        } catch {
            fatalError("err: \(error)")
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func didMoveToSuperview() {
        initTriangles()

    }
    
    func initTriangles() {
        for (_, triangleLayer) in triangles {
            triangleLayer.removeFromSuperlayer()
        }
        
        var p = load("points10000.json")
        print("len raw \(p.count)")
        //        print(" POINTS \(points1)")
        //let points = generateVertices(bounds.size, cellSize: 80)
        //let points = generateVerticesRandom(bounds.size, count:100)
        
        let bounding = box(from: p)
        let bounding1000 = CGRect(x: 42869063.32687465, y: 103726748.26747078, width: 95355.88277196884, height: 90267.3662738651)
        let boundingq1 = bounding1000
            .cornerNe
            .cornerNe
        print("bounding \(bounding)")
        print("bounding \(bounding1000)")
        p = p.filter { point in
            let cgpoint = CGPoint(x: point.x, y: point.y)
            let inside = boundingq1.contains(cgpoint)
            //print("test \(cgpoint) \(box) \(inside)")
            return inside
        }
        print("points after filter \(p.count) ")
        if p.count == 0 {
            fatalError()
        }
        
        let mapPoints = p.map { MKMapPoint(x: $0.x, y: $0.y) }
        mkTriangles = triangulate(mapPoints)

        let vertices = mapPoints.map { DBVertex($0) }
        normConverter = makeNorm(mapPoints)
        
        //p = normalize(p)
        p = normalizeWithFunc(p)
        allPoints = generateNorms(p, bounds.size)
        delaunayTriangles = triangulate(allPoints)
        
        for triangle in delaunayTriangles {
            for point in triangle.points {
                //pointsToTri[point, default: []].append(triangle)
            }
        }
        
        
        triangles = []
        for (i, triangle) in delaunayTriangles.enumerated() {
            let mkTriangle = mkTriangles[i]
            let triangleLayer = CAShapeLayer()
            let normTriangle = Triangle(
                mkTriangle.points.map {
                    let normPoint = normConverter!($0)
                    let screenPoint = normPoint.screen(by: bounds.size)
                    return screenPoint
                })
            //print("convert \(triangle) to \(normTriangle)")
            let oldPath = triangle.toPath()
            let newPath = normTriangle.toPath()
            ///print("old path \(oldPath)")
            //print("new path \(newPath)")
            //let eq = oldPath == newPath
            //print("eq \(eq)")
            triangleLayer.path = newPath
            //print("    path \(triangleLayer.path!)")
            //print("path \(triangle) \(normTriangle) \(triangleLayer.path)")
            triangleLayer.fillColor = UIColor().randomColor().cgColor
            //triangleLayer.strokeColor = UIColor.black.cgColor
            triangleLayer.backgroundColor = UIColor.clear.cgColor
            layer.addSublayer(triangleLayer)
            
            triangles.append((triangle, triangleLayer))
        }
        
        print("have \(delaunayTriangles.count) triangles")
        
        let circles = delaunayTriangles.map { circumcircle($0) }
        let rsqrs = circles.map { $0.rsqr }.sorted()
        let med = rsqrs[rsqrs.count/2]
        print("rsqrs \(rsqrs.count) min:\(rsqrs.min()!) max:\(rsqrs.max()!) med:\(med)")
        
        for (triangle, layer) in triangles {
            let c = circumcircle(triangle)
            //print ("Triangle \(c)")
            if c.rsqr > 340 {
                layer.fillColor = UIColor.white.cgColor
            }
            
            
            layer.strokeColor = UIColor.black.cgColor
        }
    }
    
    func neighbors(for triangle:Triangle) -> [Triangle] {
        
//        let tries = triangle.points.flatMap {
//            //pointsToTri[$0]!
//        }
//        let uniques = Set(tries)
//        return Array(uniques)
        return []
    }
    
    @IBAction func singleTap(recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            let tapLocation = recognizer.location(in: self)
            let vertex = MKMapPoint(point: tapLocation)
            for (triangle, triangleLayer) in triangles {
                if vertex.inside(triangle) {
                    triangleLayer.fillColor = UIColor.black.cgColor
                }
            }
        }
    }
    
    @IBAction func doubleTap(recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            initTriangles()
        }
    }
}

