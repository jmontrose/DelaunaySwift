//
//  TriangleView.swift
//  DelaunayTriangulationSwift
//
//  Created by Alex Littlejohn on 2016/01/08.
//  Copyright © 2016 zero. All rights reserved.
//

import UIKit
import GameplayKit
import DelaunaySwift


extension Point {
    static func random(size:CGSize) -> Point {
        return Point(x: Double.random(in: Double(0)...Double(size.width)), y: Double.random(in: Double(0)...Double(size.height)))
    }
}

func generateNorms(_ points:[Point], _ size:CGSize) -> [Point] {
    return points.map { p in
        Point(x: p.x * Double(size.width), y: p.y * Double(size.height))
    }
}

func generateVerticesRandom(_ size: CGSize, count:Int, seed: UInt64 = UInt64.random(in: 0..<UInt64.max)) -> [Point] {
    var points = [Point]()
    for _ in 0...100 {
        points.append(Point.random(size: size))
    }
    return points
}

/// Generate set of points for our triangulation to use
func generateVertices(_ size: CGSize, cellSize: CGFloat, variance: CGFloat = 0.75, seed: UInt64 = UInt64.random(in: 0..<UInt64.max)) -> [Point] {
    
    // How many cells we're going to have on each axis (pad by 2 cells on each edge)
    let cellsX = (size.width + 4 * cellSize) / cellSize
    let cellsY = (size.height + 4 * cellSize) / cellSize
    
    // figure out the bleed widths to center the grid
    let bleedX = ((cellsX * cellSize) - size.width)/2
    let bleedY = ((cellsY * cellSize) - size.height)/2
    
    let _variance = cellSize * variance / 4
    
    var points = [Point]()
    let minX = -bleedX
    let maxX = size.width + bleedX
    let minY = -bleedY
    let maxY = size.height + bleedY
    
    let generator = GKLinearCongruentialRandomSource(seed: seed)
    
    for i in stride(from: minX, to: maxX, by: cellSize) {
        for j in stride(from: minY, to: maxY, by: cellSize) {
            
            let x = i + cellSize/2 + CGFloat(generator.nextUniform()) + CGFloat.random(in: -_variance..._variance)
            let y = j + cellSize/2 + CGFloat(generator.nextUniform()) + CGFloat.random(in: -_variance..._variance)
            
            points.append(Point(x: Double(x), y: Double(y)))
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

    func load(_ name:String) -> [Point] {
        let raw = loadText(name: name)
        do {
            let simplePoints = try JSONDecoder().decode(ArrayOfArrays.self, from: Data(raw.utf8))
            return normalize(simplePoints)
        } catch {
            fatalError("err: \(error)")
        }
        return []
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func didMoveToSuperview() {
        initTriangles()
        print("have \(delaunayTriangles.count) triangles")
    }
    
    func initTriangles() {
        for (_, triangleLayer) in triangles {
            triangleLayer.removeFromSuperlayer()
        }

        let p = load("points1000.json")
        print("len raw \(p.count)")
//        print(" POINTS \(points1)")
        //let points = generateVertices(bounds.size, cellSize: 80)
        //let points = generateVerticesRandom(bounds.size, count:100)
        let points = generateNorms(p, bounds.size)

        delaunayTriangles = triangulate(points)
        
        triangles = []
        for triangle in delaunayTriangles {
            let triangleLayer = CAShapeLayer()
            triangleLayer.path = triangle.toPath()
            triangleLayer.fillColor = UIColor().randomColor().cgColor
            triangleLayer.backgroundColor = UIColor.clear.cgColor
            layer.addSublayer(triangleLayer)
            
            triangles.append((triangle, triangleLayer))
        }
    }
    
    @IBAction func singleTap(recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            let tapLocation = recognizer.location(in: self)
            let vertex = Point(point: tapLocation)
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

