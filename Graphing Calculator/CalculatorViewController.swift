//
//  ViewController.swift
//  Graphing Calculator
//
//  Created by ASM on 10/25/17.
//  Copyright © 2017 ASM. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController, UISplitViewControllerDelegate {
    
    //MARK: Outlets
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var memoryLabel: UILabel!
    @IBOutlet weak var graphLabel: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.splitViewController?.delegate = self
    }
    
    //MARK: Properties
    var userIsInTheMiddleOfTyping = false
    var memoryDictionary = [String : Double]()
    
    //Tracks value of display label as a Double.
    var displayValue: Double {
        get {
            return Double(display.text!)!
        }
        set {
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            numberFormatter.roundingMode = NumberFormatter.RoundingMode.halfUp
            numberFormatter.maximumFractionDigits = 6
            let displayValueAsNSNumber = NSNumber(value: newValue)
            if let formattedDecimal = numberFormatter.string(from: displayValueAsNSNumber) {
                display.text = String(describing: formattedDecimal)
            } else {
                display.text = "ERROR"
            }
        }
    }
    
    private func updateDisplay() {
        let evaluated = brain.evaluate(using: memoryDictionary)
        
        if let error = evaluated.error {
            display.text = error
        } else if let result = evaluated.result {
            displayValue = result
        }
        
        if evaluated.description != "" {
            descriptionLabel.text! = evaluated.description.beautifyNumbers() + (evaluated.isPending ? "..." : " =")
        }
        
        if evaluated.isPending {
            graphLabel.titleLabel?.alpha = 0.4
        } else {
            graphLabel.titleLabel?.alpha = 1.0
        }
    }
    
    //MARK: Actions
    
    //Digit buttons.
    @IBAction func touchDigit(_ sender: UIButton) {
        //Stop user from being able to add multiple decimal points.
        if (display.text?.contains("."))! && sender.currentTitle == "." && userIsInTheMiddleOfTyping { return }
        let digit = sender.currentTitle!
        
        //Logic to enable appending digits:
        if userIsInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            display.text = textCurrentlyInDisplay + digit
        } else {
            if display.text == "0" && digit == "0" {
                return
            } else {
                display.text = digit
                userIsInTheMiddleOfTyping = true
            }
        }
    }
    
    //Call the calculations from the model with these operation buttons.
    @IBAction func performOperation(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue)
            userIsInTheMiddleOfTyping = false
        }
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        
        updateDisplay()
    }
    
    //for M button
    @IBAction func memory(_ sender: UIButton) {
        if sender.currentTitle == "M" {
            brain.setOperand(variable: "M")
            userIsInTheMiddleOfTyping = false
            updateDisplay()
        }
    }
    
    //for →M button
    @IBAction func sendToMemory(_ sender: UIButton) {
        memoryDictionary["M"] = displayValue
        userIsInTheMiddleOfTyping = false
        updateDisplay()
        let beautifiedMemoryNumber = String(memoryDictionary["M"]!).beautifyNumbers()
        memoryLabel.text = "M: " + beautifiedMemoryNumber
    }
    
    @IBAction func clearMemory(_ sender: UIButton) {
        memoryDictionary = [String : Double]()
        memoryLabel.text = " "
    }
    
    @IBAction func clearDisplay(_ sender: UIButton) {
        brain = CalculatorBrain()
        memoryDictionary = [String : Double]()
        displayValue = 0
        descriptionLabel.text = "    "
        memoryLabel.text = " "
        userIsInTheMiddleOfTyping = false
    }
    
    @IBAction func undo(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            var displayValueStringChar = String(displayValue).characters
            
            if displayValue == Double(Int(displayValue)) {
                displayValueStringChar.removeFirst()
                display.text = String(displayValueStringChar)
                displayValue = Double(display.text!)!
            } else {
                displayValueStringChar.removeLast()
                display.text = String(displayValueStringChar)
            }
            
            if displayValue == 0.0 {
                userIsInTheMiddleOfTyping = false
            }
        } else {
            brain.undo()
            updateDisplay()
        }
    }
    
    //Using split view controller's delegate to get calculator view to appear first. This is telling our Split View Controller we are collapsing detail VC onto master, but actually we're doing nothing
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if primaryViewController.contents == self {
            if let gvc = secondaryViewController.contents as? GraphViewController {
                //Actually doing nothing here
                return true
            }
        }
        return false
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard !brain.resultIsPending else { return }
        
        var destinationViewController = segue.destination
        if let navigationController = destinationViewController as? UINavigationController {
            destinationViewController = navigationController.visibleViewController ?? destinationViewController
        }
        if let graphViewController = destinationViewController as? GraphViewController {
            graphViewController.title = brain.description == "" ? "Graph" : brain.description.components(separatedBy: ", ").last?.beautifyNumbers()
            
            graphViewController.function = { (x: CGFloat) -> Double in
                self.brain.storedVariable = Double(x)
                if let result = self.brain.result {
                    return result
                } else { return 0.0 }
            }
        }
    }
    
    //MARK: Private variables
    //Create and use an instance of the model.
    private var brain = CalculatorBrain()
    
    //Create and use an instance of this class to limit decimal digits.
    private let numberFormatter = NumberFormatter()
}



extension String {
    static let DecimalDigits = 6
    
    func beautifyNumbers() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = String.DecimalDigits
        
        var text = self as NSString
        var numbers = [String]()
        let regex = try! NSRegularExpression(pattern: "[.0-9]+", options: .caseInsensitive)
        let matches = regex.matches(in: self, options: [], range: NSMakeRange(0, text.length))
        numbers = matches.map { text.substring(with: $0.range) }
        
        for number in numbers {
            text = text.replacingOccurrences(
                of: number,
                with: formatter.string(from: NSNumber(value: Double(number)!))!
                ) as NSString
        }
        return text as String
    }
}


extension UIViewController {
    var contents: UIViewController {
        if let navCon = self as? UINavigationController {
            return navCon.visibleViewController ?? self
        } else {
            return self
        }
    }
}








