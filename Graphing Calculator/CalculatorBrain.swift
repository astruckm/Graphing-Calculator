//
//  CalculatorBrain.swift
//  Graphing Calculator
//

import Foundation

struct CalculatorBrain: CustomStringConvertible {
    
    var storedVariable: Double = 0.0

    //To hold values & variables for operations
    private var stack = [Element]()
    
    private enum Element {
        case operand(Double)
        case operation(String)
        case variable(String)
    }
    
    //Making the operations specific cases of a type so can call on operation within operations dictionary.
    private enum Operation {
        case constant(Double)
        case nullaryOperation(() -> Double)
        case unaryOperation(((Double) -> Double), (String) -> String)
        case binaryOperation(((Double,Double) -> Double), (String, String) -> String)
        case equals
    }
    
    private enum ErrorOperation {
        case unaryOperation((Double) -> String?)
        case binaryOperation((Double, Double) -> String?)
    }
    
    //Put the operand or operation in the stack
    mutating func setOperand(_ operand: Double) {
        stack.append(Element.operand(operand))
    }
    
    mutating func setOperand(variable named: String) {
        stack.append(Element.variable(named))
    }
    
    mutating func performOperation(_ symbol: String) {
        stack.append(Element.operation(symbol))
    }
    
    //Remove operand or operation from the stack
    mutating func undo() {
        if !stack.isEmpty {
            stack.removeLast()
        }
    }
    
    //Like accumulator, so needs to be able to be not set initially (i.e. nil).
    var result: Double? {
        return evaluate().result
    }
    
    var resultIsPending: Bool {
        return evaluate().isPending
    }
    
    var description: String {
        return evaluate().description
    }
    
    //Store all the calculation operations in here.
    private var operations: Dictionary<String,Operation> = [
        "π" : Operation.constant(Double.pi),
        "e" : Operation.constant(M_E),
        "rand" : Operation.nullaryOperation({Double(arc4random()) / Double(UInt32.max)}),
        "√" : Operation.unaryOperation(sqrt, {"√(" + $0 + ")"}),
        "cos" : Operation.unaryOperation(cos, {"cos(" + $0 + ")" }),
        "sin" : Operation.unaryOperation(sin, {"sin(" + $0 + ")" }),
        "tan" : Operation.unaryOperation(tan, {"tan(" + $0 + ")" }),
        "+/-" : Operation.unaryOperation({ -$0 }, {"-(" + $0 + ")" }),
        "x⁻¹" : Operation.unaryOperation({ 1.0 / $0 }, {"(" + $0 + ")⁻¹" }),
        "x²" : Operation.unaryOperation({ $0 * $0 }, {"(" + $0 + ")²" }),
        "%" : Operation.unaryOperation({ $0 / 100 }, { "%(" + $0 + ")"}),
        "x" : Operation.binaryOperation({ $0 * $1 }, { $0 + " x " + $1 }),
        "÷" : Operation.binaryOperation({ $0 / $1 }, { $0 + " ÷ " + $1 }),
        "-" : Operation.binaryOperation({ $0 - $1 }, { $0 + " - " + $1 }),
        "+" : Operation.binaryOperation({ $0 + $1 }, { $0 + " + " + $1 }),
        "xʸ" : Operation.binaryOperation({ pow($0, $1) }, { "(" + $0 + ") ^ " + $1 }),
        "=" : Operation.equals
    ]
    
    private let errorOperations: Dictionary<String,ErrorOperation> = [
        "√" : ErrorOperation.unaryOperation({ $0 < 0.0 ? "SQRT of negative number" : nil }),
        "x⁻¹" : ErrorOperation.unaryOperation({ $0 == 0.0 ? "Division by 0" : nil}),
        "÷" : ErrorOperation.binaryOperation({ 1e-8 > fabs($0.1) ? "Division by 0" : nil }) //Closure func is whatever to ensure is valid
    ]
    
    func evaluate(using variables: Dictionary<String,Double>? = nil) -> (result: Double?, isPending: Bool, description: String, error: String?) {
        
        var accumulator: (Double, String)?
        var error: String?
        
        //Gives the logic for doing a binary operation
        struct PendingBinaryOperation {
            let function: (Double, Double) -> Double
            let description: (String, String) -> String
            let firstOperand: (Double, String)
            
            let symbol: String
            
            func perform(with secondOperand: (Double, String)) -> (Double, String) {
                return (function(firstOperand.0, secondOperand.0), description(firstOperand.1, secondOperand.1))
            }
        }
        
        //For the state after pressing a binary operation key, before pressing the second operand.
        var pendingBinaryOperation: PendingBinaryOperation?
        
        //Make the equals sign return what it equals.
        func performPendingBinaryOperation() {
            if pendingBinaryOperation != nil && accumulator != nil {
                if let errorOperation = errorOperations[pendingBinaryOperation!.symbol], case .binaryOperation(let errorFunction) = errorOperation {
                    error = errorFunction(pendingBinaryOperation!.firstOperand.0, accumulator!.0)
                }
                accumulator = pendingBinaryOperation!.perform(with: accumulator!)
                pendingBinaryOperation = nil
            }
        }
        
        //Tracks the Double value in accumulator
        var result: Double? {
            if accumulator != nil {
                return accumulator!.0
            } else { return nil }
        }

        var description: String {
            if pendingBinaryOperation != nil {
                return pendingBinaryOperation!.description(pendingBinaryOperation!.firstOperand.1, accumulator?.1 ?? "")
            } else {
                return accumulator?.1 ?? ""
            }
        }
        
        for element in stack {
            switch element {
            case .operand(let value):
                accumulator = (value, "\(value)")
            case .operation(let symbol):
                if let operation = operations[symbol] {
                    switch operation {
                    case .constant(let value):
                        accumulator = (value, symbol)
                    case .nullaryOperation(let function):
                        let funcValue = function()
                        accumulator = (funcValue, "\(funcValue)")
                    case .unaryOperation(let function, let description):
                        if accumulator != nil {
                            accumulator = (function(accumulator!.0), description(accumulator!.1))
                            if let errorOperation = errorOperations[symbol], case .unaryOperation(let errorFunction) = errorOperation {
                                error = errorFunction(accumulator!.0)
                            }
                        }
                    case .binaryOperation(let function, let description):
                        performPendingBinaryOperation()
                        if accumulator != nil {
                            pendingBinaryOperation = PendingBinaryOperation(function: function, description: description, firstOperand: accumulator!, symbol: symbol)
                            accumulator = nil
                        }
                        break
                    case .equals:
                        if accumulator != nil {
                            performPendingBinaryOperation()
                        }
                    }
                }
            case .variable(let symbol):
                if let value = variables?[symbol] {
                    accumulator = (value, symbol)
                } else if symbol == "M" {
                    accumulator = (storedVariable, "M")
                }
                else {
                    accumulator = (0, "0")
                }
            }
        }
        
        return (result, pendingBinaryOperation != nil, description, error)
    }    
}
