//
//  ViewController.swift
//  Graphing MVC
//

import UIKit

class GraphViewController: UIViewController, GraphDataSource, GraphViewDelegate {
    //MARK: Outlets
    @IBOutlet weak var xIntercepts: UILabel!
    @IBOutlet weak var yIntercepts: UILabel!
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
            
            //[<NSUserDefaults 0x104c2bbe0> valueForUndefinedKey:]: this class is not key value coding-compliant for the key GraphViewController.Scale.
//            if let scale = UserDefaults.value(forKey: Keys.scale) as? CGFloat {
//                graphView.pointsPerUnit = scale
//                graphView.scale = graphView.pointsPerUnit
//            }
//            
//            if let origin = UserDefaults.value(forKey: Keys.origin) as? String {
//                graphView.newAxesOrigin = CGPointFromString(origin)
//                graphView.origin = graphView.newAxesOrigin ?? graphView.center
//            }

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        displayIntercepts()
    }
    
    private func updateUI() {
        graphView.draw(graphView.bounds)
        scale(graphView.scale, sender: graphView)
        origin(graphView.origin, sender: graphView)
    }
    
    private func displayIntercepts() {
        let yCrossing = calculateYIntercept()
        let xCrossings = calculateXIntercepts()
        
        if let yCrossing = yCrossing {
            yIntercepts?.text? = "Y: \(yCrossing)"
        }
        
        var textToAdd = ""
        for (counter, crossing) in xCrossings.enumerated() {
            textToAdd += " " + String(describing: crossing)
            if xCrossings.count > 1 && xCrossings.count != counter + 1 {
                textToAdd += ","
            }
        }
        xIntercepts.numberOfLines = 0
        xIntercepts?.text? += textToAdd
    }
        
    //MARK: Persistence
    func scale(_ scale: CGFloat, sender: GraphView) {
        UserDefaults.standard.set(scale, forKey: Keys.scale)
//        let scale = UserDefaults.standard.float(forKey: Keys.scale)
    }
    
    func origin(_ origin: CGPoint, sender: GraphView) {
        UserDefaults.standard.set(NSStringFromCGPoint(origin), forKey: Keys.origin)
    }
    
    private struct Keys {
        static let scale = "GraphViewController.Scale"
        static let origin = "GraphViewController.Origin"
    }
    
    //MARK: Model
    var function: ((CGFloat) -> Double)?
    
    func y(_ x: CGFloat) -> CGFloat? {
        if let function = self.function {
            return CGFloat(function(x))
        } else { return nil }
    }
    
    func calculateYIntercept() -> CGFloat? {
        if let yIntercept = function?(0.0) {
            let yInterceptHundredths = (Double(yIntercept) * 100).rounded() / 100
            return CGFloat(yInterceptHundredths)
        } else { return nil }
    }
    
    func calculateXIntercepts() -> [CGFloat] {
        var xIntercepts = [CGFloat]()
        var xValue = -((graphView.bounds.width/2) + graphView.origin.x) / graphView.scale
        let incrementAmount: CGFloat = 0.001
        while (xValue <= (graphView.bounds.maxX/2 + graphView.origin.x) / graphView.scale) {
            if let yValue = function?(xValue), yValue < 0.001, yValue > -0.001 {
                let xValueHundredths = (Double(xValue) * 100).rounded() / 100
                xIntercepts.append(CGFloat(xValueHundredths))
            }
            xValue += incrementAmount
        }
        //Get rid of duplicates and re-sort
        xIntercepts = Array(Set(xIntercepts))
        xIntercepts.sort(by: <)
        
        return xIntercepts
    }
    
}

