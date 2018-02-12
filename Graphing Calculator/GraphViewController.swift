//
//  ViewController.swift
//  Graphing MVC
//
//  Created by ASM on 10/3/17.
//  Copyright © 2017 ASM. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphDataSource, GraphViewDelegate {
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
            
            let pinchHandler = #selector(GraphView.changeScale(byReactingTo:))
            let pinchRecognizer = UIPinchGestureRecognizer(target: graphView, action: pinchHandler)
            graphView.addGestureRecognizer(pinchRecognizer)
            
            let panHandler = #selector(GraphView.moveGraph(byReactingTo:))
            let panRecognizer = UIPanGestureRecognizer(target: graphView, action: panHandler)
            graphView.addGestureRecognizer(panRecognizer)
            
            let tapHandler = #selector(GraphView.moveOrigin(byReactingTo:))
            let tapRecognizer = UITapGestureRecognizer(target: graphView, action: tapHandler)
            tapRecognizer.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(tapRecognizer)
            
            updateUI()
            
//            if let scale = UserDefaults.value(forKey: Keys.Scale) as? CGFloat {
//                graphView.pointsPerUnit = scale
//                graphView.scale = graphView.pointsPerUnit
//            }
//
//            if let origin = UserDefaults.value(forKey: Keys.Origin) as? String {
//                graphView.newAxesOrigin = CGPointFromString(origin)
//                graphView.origin = graphView.newAxesOrigin ?? graphView.center
//            }
        }
    }
    

    
    func scale(_ scale: CGFloat, sender: GraphView) {
        UserDefaults.standard.set(scale, forKey: Keys.Scale)
    }
    
    func origin(_ origin: CGPoint, sender: GraphView) {
        UserDefaults.standard.set(NSStringFromCGPoint(origin), forKey: Keys.Origin)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func updateUI() {
        graphView.draw(graphView.bounds)
    }
    
    private struct Keys {
        static let Scale = "GraphViewController.Scale"
        static let Origin = "GraphViewController.Origin"
    }
    
    //MARK: Model
    var function: ((CGFloat) -> Double)?
    
    func y(x: CGFloat) -> CGFloat? {
        if let function = self.function {
            return CGFloat(function(x))
        } else { return nil }
    }
    
}

