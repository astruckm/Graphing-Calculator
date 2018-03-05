//
//  ViewController.swift
//  Graphing MVC
//

import UIKit

class GraphViewController: UIViewController, GraphDataSource {
    //MARK: Outlets
    @IBOutlet weak var xIntercepts: UILabel!
    @IBOutlet weak var yIntercepts: UILabel!
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
            
            let pinchHandler = #selector(self.changeScale(byReactingTo:))
            let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: pinchHandler)
            graphView.addGestureRecognizer(pinchRecognizer)
            
            let panHandler = #selector(self.moveGraph(byReactingTo:))
            let panRecognizer = UIPanGestureRecognizer(target: self, action: panHandler)
            graphView.addGestureRecognizer(panRecognizer)

            let tapHandler = #selector(self.moveOrigin(byReactingTo:))
            let tapRecognizer = UITapGestureRecognizer(target: self, action: tapHandler)
            tapRecognizer.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(tapRecognizer)
            
            if !resetOrigin {
                graphView.origin = origin
            }
            graphView.scale = scale

            graphView.draw(graphView.bounds)
        }
    }
    
    private var resetOrigin: Bool {
        get {
            if defaults.object(forKey: Keys.origin) is [CGFloat] {
                return false
            }
            return true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayIntercepts()
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
    
    //MARK: Persistence
    private struct Keys {
        static let scale = "GraphViewController.Scale"
        static let origin = "GraphViewController.Origin"
    }
    let defaults = UserDefaults.standard
    
    private var scale: CGFloat {
        get { return defaults.value(forKey: Keys.scale) as? CGFloat ?? 25.0 }
        set { defaults.set(newValue, forKey: Keys.scale) }
    }
    
    private var origin: CGPoint {
        get {
            var origin = CGPoint()
            if let originArray = defaults.value(forKey: Keys.origin) as? [CGFloat] {
                origin.x = originArray.first!
                origin.y = originArray.last!
            }
            return origin
        }
        set {
            defaults.set([newValue.x, newValue.y], forKey: Keys.origin)
        }
    }

    //Call graphView's gesture recognizers to save scale and origin after each user gesture
    func changeScale(byReactingTo pinchRecognizer: UIPinchGestureRecognizer) {
        graphView.changeScale(byReactingTo: pinchRecognizer)
        if pinchRecognizer.state == .ended {
            scale = graphView.scale
            origin = graphView.origin
        }
    }
    
    func moveGraph(byReactingTo panRecognizer: UIPanGestureRecognizer) {
        graphView.moveGraph(byReactingTo: panRecognizer)
        if panRecognizer.state == .ended {
            origin = graphView.origin
        }
    }
    
    func moveOrigin(byReactingTo tapRecognizer: UITapGestureRecognizer) {
        graphView.moveOrigin(byReactingTo: tapRecognizer)
        if tapRecognizer.state == .ended {
            origin = graphView.origin
        }
    }

}

