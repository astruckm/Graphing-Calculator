//
//  CalculatorViewController.swift
//  Graphing Calculator
//

import UIKit

class CalculatorViewController: UIViewController, UISplitViewControllerDelegate {
    
    //MARK: Outlets
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var memoryLabel: UILabel!
    @IBOutlet weak var graphLabel: UIButton!
    @IBOutlet var numbersButtons: [UIButton]!
    @IBOutlet var functionsButtons: [UIButton]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.splitViewController?.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for numberButton in numbersButtons {
            numberButton.layer.cornerRadius = 10
            numberButton.clipsToBounds = true
        }
        for functionButton in functionsButtons {
            functionButton.layer.cornerRadius = 10
            functionButton.clipsToBounds = true
            functionButton.titleLabel?.adjustsFontSizeToFitWidth = true
            functionButton.titleLabel?.minimumScaleFactor = 0.5
        }
        display.layer.borderWidth = 0.5
        display.layer.borderColor = UIColor.lightGray.cgColor
        display.layer.cornerRadius = 10
        display.clipsToBounds = true
    }
    
    
    //MARK: Properties
    var userIsInTheMiddleOfTyping = false
    var memoryDictionary = [String : Double]()
    var memoryHasBeenSet = false
    
    //Tracks value of display label as a Double.
    var displayValue: Double {
        get {
            return Double(display.text!)!
        }
        set {
            display.text = String(newValue).beautifyNumbers()
        }
    }
    
    private func updateDisplay() {
        let evaluated = brain.evaluate(using: memoryDictionary)
        
        if let error = evaluated.error {
            display.text = error
        } else if let result = evaluated.result, (memoryHasBeenSet || !evaluated.description.contains("M"))  {
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
    
    //Digits
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
    
    //M
    @IBAction func memory(_ sender: UIButton) {
        if sender.currentTitle == "M" {
            brain.setOperand(variable: "M")
            userIsInTheMiddleOfTyping = false
            updateDisplay()
        }
    }
    
    //→M
    @IBAction func sendToMemory(_ sender: UIButton) {
        memoryDictionary["M"] = displayValue
        userIsInTheMiddleOfTyping = false
        updateDisplay()
        let beautifiedMemoryNumber = String(memoryDictionary["M"]!).beautifyNumbers()
        memoryLabel.text = "M: " + beautifiedMemoryNumber
        memoryHasBeenSet = true
    }
    
    //MC
    @IBAction func clearMemory(_ sender: UIButton) {
        clearMemory()
    }
    
    func clearMemory() {
        memoryDictionary = [String : Double]()
        memoryLabel.text = " "
        memoryHasBeenSet = false
    }
    
    //c
    @IBAction func clearDisplay(_ sender: UIButton) {
        brain = CalculatorBrain()
        displayValue = 0
        descriptionLabel.text = "    "
        userIsInTheMiddleOfTyping = false
        clearMemory()
    }
    
    //undo
    @IBAction func undo(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            var displayValueString = String(displayValue)
            
            if displayValue == Double(Int(displayValue)) {
                displayValueString.removeFirst()
                display.text = displayValueString
                displayValue = Double(display.text!)!
            } else {
                displayValueString.removeLast()
                display.text = displayValueString
            }
            
            if displayValue == 0.0 {
                userIsInTheMiddleOfTyping = false
            }
        } else {
            brain.undo()
            updateDisplay()
        }
    }
    
    //MARK: Navigation
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
        
        if segue.identifier == "graph" {
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








