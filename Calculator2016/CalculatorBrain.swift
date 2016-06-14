//
//  CalculatorBrain.swift
//  Calculator2016
//
//  Created by Stefan Scoarta on 4/29/16.
//  Copyright © 2016 Stefan Scoarta. All rights reserved.
//

import Foundation

func factorial(_ op1: Double) -> Double {
    if (op1 <= 1) {
        return 1
    }
    return op1 * factorial(op1 - 1)
}

enum Error: ErrorProtocol{
    case squareRootOfNegativeNumber
    case divisionByZero
}

class CalculatorBrain {
    private var accumulator = 0.0
    
    private var internalProgram = [AnyObject]()
    
    
    private var descriptionAccumulator = "0" {
        didSet {
            if pending == nil {
                currentPrecedence = Int.max
            }
        }
    }
    
    private var operations: Dictionary<String,Operation> = [
        "π" : Operation.constant(M_PI),
        "e" : Operation.constant(M_E),
        "%": Operation.unaryOperation({$0 / 100}, {"(" + $0 + ")%"},nil),
        "ᐩ/-" : Operation.unaryOperation({ -$0 }, { "-(" + $0 + ")"},nil),
        "²√" : Operation.unaryOperation(sqrt, { "²√(" + $0 + ")"}, {if $0 < 0{ throw Error.squareRootOfNegativeNumber }}),
        "³√" : Operation.unaryOperation(cbrt, { "³√(" + $0 + ")"},nil),
        "x²" : Operation.unaryOperation({ pow($0, 2) }, { "(" + $0 + ")²"},nil),
        "x³" : Operation.unaryOperation({ pow($0, 3) }, { "(" + $0 + ")³"},nil),
        "x⁻¹" : Operation.unaryOperation({ 1 / $0 }, { "(" + $0 + ")⁻¹"},nil),
        "sin" : Operation.unaryOperation(sin, { "sin(" + $0 + ")"},nil),
        "2ˣ" : Operation.unaryOperation({pow(2, $0)}, { "2^" + $0},nil),
        "cos" : Operation.unaryOperation(cos, { "cos(" + $0 + ")"},nil),
        "tan" : Operation.unaryOperation(tan, { "tan(" + $0 + ")"},nil),
        "sinh" : Operation.unaryOperation(sinh, { "sinh(" + $0 + ")"},nil),
        "cosh" : Operation.unaryOperation(cosh, { "cosh(" + $0 + ")"},nil),
        "tanh" : Operation.unaryOperation(tanh, { "tanh(" + $0 + ")"},nil),
        "ln" : Operation.unaryOperation(log, { "ln(" + $0 + ")"},nil),
        "log₁₀" : Operation.unaryOperation(log10, { "log(" + $0 + ")"},nil),
        "eˣ" : Operation.unaryOperation(exp, { "e^(" + $0 + ")"},nil),
        "10ˣ" : Operation.unaryOperation({ pow(10, $0) }, { "10^(" + $0 + ")"},nil),
        "x!" : Operation.unaryOperation(factorial, { "(" + $0 + ")!"},nil),
        "×" : Operation.binaryOperation(*, { $0 + " × " + $1 }, 1,nil),
        "÷" : Operation.binaryOperation(/, { $0 + " ÷ " + $1 }, 1, {if $1 == 0 { throw Error.divisionByZero }}),
        "+" : Operation.binaryOperation(+, { $0 + " + " + $1 }, 0,nil),
        "−" : Operation.binaryOperation(-, { $0 + " - " + $1 }, 0,nil),
        "xʸ" : Operation.binaryOperation(pow, { $0 + " ^ " + $1 }, 2,nil),
        "yˣ" : Operation.binaryOperation({pow($1, $0)}, { $1 + " ^ " + $0 }, 2,nil),
        "rand" : Operation.nullaryOperation(drand48, "rand()"),
        "=" : Operation.equals
    ]
    
    private enum Operation {
        case constant(Double)
        case unaryOperation((Double) -> Double, (String) -> String,((Double) throws -> ())?)
        case binaryOperation((Double, Double) -> Double, (String, String) -> String, Int,((Double,Double) throws -> ())?)
        case nullaryOperation(() -> Double, String)
        case equals
    }
    
    private var currentPrecedence = Int.max
    
    private var pending: PendingBinaryOperationInfo?
    
    
    
    var result: Double {
        get {
            return accumulator
        }
    }
    
    var isOperationPending: Bool{
        return pending != nil
    }
    
    typealias PropertyList = AnyObject
    
    var program: PropertyList{
        get{
            return internalProgram
        }set{
            clear()
            if let arrayOfOps = newValue as? [AnyObject]{
                for op in arrayOfOps {
                    if let operand = op as? Double{
                        setOperand(operand)
                    }else if let operation = op as? String{
                        performOperation(operation)
                    }
                }
            }
        }
    }
    
    var description: String {
        get {
            if pending == nil {
                return descriptionAccumulator
            } else {
                return pending!.descriptionFunction(pending!.descriptionOperand,
                                                    pending!.descriptionOperand != descriptionAccumulator ? descriptionAccumulator : "")
            }
        }
    }
    
    var variableValue = [String:Double](){
        didSet{
            recalculate()
        }
    }
    
    func setOperand(_ variableName: String) {
        performOperation(variableName)
    }
    
    private func recalculate(){
        
        let oldProgram = internalProgram
        clear()
        program = oldProgram
    }
    
    func setOperand(_ operand: Double) {
        accumulator = operand
        internalProgram.append(operand)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 6
        numberFormatter.minimumIntegerDigits = 1
        descriptionAccumulator = numberFormatter.string(from: operand)!
    }
    
    func performOperation(_ symbol: String) {
        internalProgram.append(symbol)
        if let operation = operations[symbol] {
            switch operation {
            case .constant(let value):
                accumulator = value
                descriptionAccumulator = symbol
            case .nullaryOperation(let function, let descriptiveValue):
                accumulator = function()
                descriptionAccumulator = descriptiveValue
            case .unaryOperation(let function, let descriptionFunction,_):
                accumulator = function(accumulator)
                descriptionAccumulator = descriptionFunction(descriptionAccumulator)
            case .binaryOperation(let function, let descriptionFunction, let precedence,_):
                executePendingBinaryOperation()
                if currentPrecedence < precedence {
                    descriptionAccumulator = "(" + descriptionAccumulator + ")"
                }
                currentPrecedence = precedence
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator,
                                                     descriptionFunction: descriptionFunction, descriptionOperand: descriptionAccumulator,errorFunction: nil)
            case .equals:
                executePendingBinaryOperation()
            }
        }else{
            accumulator = variableValue[symbol] ?? 0
            descriptionAccumulator = symbol
        }
    }
    
    func performOperationAndReportErrors(_ symbol: String) throws {
        internalProgram.append(symbol)
        if let operation = operations[symbol] {
            switch operation {
            case .constant(let value):
                accumulator = value
                descriptionAccumulator = symbol
            case .nullaryOperation(let function, let descriptiveValue):
                accumulator = function()
                descriptionAccumulator = descriptiveValue
            case .unaryOperation(let function, let descriptionFunction,let errorFunc):
                if errorFunc != nil {
                    try errorFunc!(accumulator)
                }
                accumulator = function(accumulator)
                descriptionAccumulator = descriptionFunction(descriptionAccumulator)
            case .binaryOperation(let function, let descriptionFunction, let precedence,let errorFunc):
                try executePendingBinaryOperationWithErrors()
                if currentPrecedence < precedence {
                    descriptionAccumulator = "(" + descriptionAccumulator + ")"
                }
                currentPrecedence = precedence
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator,
                                                     descriptionFunction: descriptionFunction, descriptionOperand: descriptionAccumulator,errorFunction: errorFunc)
            case .equals:
                try executePendingBinaryOperationWithErrors()
            }
        }else{
            accumulator = variableValue[symbol] ?? 0
            descriptionAccumulator = symbol
        }
    }
    
    func undo() {
        guard internalProgram.count > 0 else { return }
        internalProgram.removeLast()
        program = internalProgram
    }
    
    private func executePendingBinaryOperation() {
        if pending != nil {
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            descriptionAccumulator = pending!.descriptionFunction(pending!.descriptionOperand, descriptionAccumulator)
            pending = nil
        }
    }
    private func executePendingBinaryOperationWithErrors() throws {
        if pending != nil {
            if let errorFunc = pending?.errorFunction{
                try errorFunc(pending!.firstOperand,accumulator)
            }
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            descriptionAccumulator = pending!.descriptionFunction(pending!.descriptionOperand, descriptionAccumulator)
            pending = nil
        }
    }
    
    func clear() {
        accumulator = 0
        pending = nil
        descriptionAccumulator = " "
        internalProgram.removeAll()
    }
    
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
        var descriptionFunction: (String, String) -> String
        var descriptionOperand: String
        var errorFunction: ((Double, Double) throws -> ())?
    }
}
