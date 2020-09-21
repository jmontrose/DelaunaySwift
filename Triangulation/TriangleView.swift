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



class TriangleView: UIView {
    var triangles: [(Triangle, CAShapeLayer)] = []
    
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

        print(" POINTS \(points1)")
        //let points = generateVertices(bounds.size, cellSize: 80)
        //let points = generateVerticesRandom(bounds.size, count:100)
        let points = generateNorms(points1, bounds.size)
        let delaunayTriangles = triangulate(points)
        
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

