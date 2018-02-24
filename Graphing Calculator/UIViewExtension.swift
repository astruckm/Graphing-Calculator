//
//  UIViewExtension.swift
//  Graphing Calculator
//
//  Created by ASM on 2/24/18.
//  Copyright © 2018 ASM. All rights reserved.
//

import UIKit

extension UIView {
    func addGradientBackground(colorOne: UIColor, colorTwo: UIColor) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor]
        gradientLayer.locations = nil
        gradientLayer.startPoint = CGPoint(x: 1.0, y: 1.0) //upper LH corner
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0) //lower RH corner
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
    

}
