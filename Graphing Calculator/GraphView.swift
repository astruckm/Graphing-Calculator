//
//  GraphView.swift
//  Graphing MVC
//

import UIKit

protocol GraphDataSource: class {
    func y(_ x: CGFloat) -> CGFloat?
}

@IBDesignable class GraphView: UIView {
    weak var dataSource: GraphDataSource?
    var snapshot: UIView? //Make image of previous axis while moving or zooming graph
    
    private var axesDrawer = AxesDrawer()
    private var geometryReady = false
    private var originRelativeToCenter: CGPoint = CGPoint() { didSet { setNeedsDisplay() } }
    
    @IBInspectable var axesColor: UIColor = .darkGray { didSet { setNeedsDisplay() } }
    @IBInspectable var scale: CGFloat = 25.0 { didSet { setNeedsDisplay() } } //i.e. relates to range of graph.
    @IBInspectable var pointsPerUnit: CGFloat = 25 { didSet { setNeedsDisplay() } }
    
    var origin: CGPoint {
        get {
            var origin = originRelativeToCenter
            if geometryReady {
                origin.x += center.x
                origin.y += center.y
            }
            return origin
        }
        set {
            var origin = newValue
            if geometryReady {
                origin.x -= center.x
                origin.y -= center.y
            }
            originRelativeToCenter = origin
        }
    }
            
    func changeScale(byReactingTo pinchRecognizer: UIPinchGestureRecognizer) {
        switch pinchRecognizer.state {
        case .began:
            snapshot = self.snapshotView(afterScreenUpdates: false)
            snapshot!.alpha = 0.8
            self.addSubview(snapshot!)
        case .changed:
            let touch = pinchRecognizer.location(in: self)
            snapshot!.frame.size.height *= pinchRecognizer.scale
            snapshot!.frame.size.width *= pinchRecognizer.scale
            snapshot!.frame.origin.x = snapshot!.frame.origin.x * pinchRecognizer.scale + (1 - pinchRecognizer.scale) * touch.x
            snapshot!.frame.origin.y = snapshot!.frame.origin.y * pinchRecognizer.scale + (1 - pinchRecognizer.scale) * touch.y
            pinchRecognizer.scale = 1.0
        case .ended:
            let changedScale = snapshot!.frame.height / self.frame.height
            scale *= changedScale
            origin.x = origin.x * changedScale + snapshot!.frame.origin.x
            origin.y = origin.y * changedScale + snapshot!.frame.origin.y
            snapshot!.removeFromSuperview()
            snapshot = nil
        default:
            break
        }
    }
    
    func moveGraph(byReactingTo panRecognizer: UIPanGestureRecognizer) {
        switch panRecognizer.state {
        case .began:
            snapshot = self.snapshotView(afterScreenUpdates: false)
            snapshot!.alpha = 0.8
            self.addSubview(snapshot!)
        case .changed:
            let translation = panRecognizer.translation(in: self)
            snapshot!.center.x += translation.x
            snapshot!.center.y += translation.y
            panRecognizer.setTranslation(CGPoint.zero, in: self)
        case .ended:
            origin.x += snapshot!.frame.origin.x
            origin.y += snapshot!.frame.origin.y
            snapshot!.removeFromSuperview()
            snapshot = nil
        default:
            break
        }
    }
    
    func moveOrigin(byReactingTo tapRecognizer: UITapGestureRecognizer) {
        tapRecognizer.numberOfTapsRequired = 2
        switch tapRecognizer.state {
        case .ended:
            origin = tapRecognizer.location(in: self)
        default: break
        }
    }
    
    override func draw(_ rect: CGRect) {
        if !geometryReady && originRelativeToCenter != CGPoint.zero {
            var originHelper = origin
            geometryReady = true
            origin = originHelper
        }
            
        axesDrawer.color = axesColor
        axesDrawer.contentScaleFactor = contentScaleFactor
        axesDrawer.drawAxes(in: bounds, origin: origin, pointsPerUnit: scale)
        
        func drawFunction() -> UIBezierPath {
            geometryReady = true
            
            let path = UIBezierPath()
            let graphUnit: CGFloat = 1 / scale
            var startingPoint = CGPoint()
            
            let startingPointRawX = -((bounds.width/2) + origin.x) / scale
            let startingPointScaledX = (origin.x + (startingPointRawX * scale))
            let startingPointRawY = dataSource?.y(startingPointRawX)
            if startingPointRawY != nil {
                let startingPointScaledY = (origin.y - (startingPointRawY! * scale))
                startingPoint = CGPoint(x: startingPointScaledX, y: startingPointScaledY)
            }
            
            path.lineWidth = 1.5
            path.move(to: startingPoint)
            for x in stride(from: startingPointRawX, to: ((bounds.maxX/2 + origin.x) / scale), by: graphUnit) {
                //Function goes here
                if let y = dataSource?.y(x) {
                    let xScaled = (origin.x + (x * scale))
                    let yScaled = (origin.y - (y * scale))
                    let nextPoint = CGPoint(x: xScaled, y: yScaled)
                    path.addLine(to: nextPoint)
                    path.move(to: nextPoint)
                }
            }
            return path
        }
        UIColor.purple.setStroke()
        drawFunction().stroke()
    }
    
}
