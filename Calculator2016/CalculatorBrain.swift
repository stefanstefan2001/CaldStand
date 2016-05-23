//
//  CalculatorBrain.swift
//  Calculator2016
//
//  Created by Stefan Scoarta on 4/29/16.
//  Copyright © 2016 Stefan Scoarta. All rights reserved.
//

import Foundation

func factorial(op1: Double) -> Double {
    if (op1 <= 1) {
        return 1
    }
    return op1 * factorial(op1 - 1)
}

enum Error: ErrorType{
    case SquareRootOfNegativeNumber
    case DivisionByZero
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
        "π" : Operation.Constant(M_PI),
        "e" : Operation.Constant(M_E),
        "%": Operation.UnaryOperation({$0 / 100}, {"(" + $0 + ")%"},nil),
        "ᐩ/-" : Operation.UnaryOperation({ -$0 }, { "-(" + $0 + ")"},nil),
        "²√" : Operation.UnaryOperation(sqrt, { "²√(" + $0 + ")"}, {if $0 < 0{ throw Error.SquareRootOfNegativeNumber }}),
        "³√" : Operation.UnaryOperation(cbrt, { "³√(" + $0 + ")"},nil),
        "x²" : Operation.UnaryOperation({ pow($0, 2) }, { "(" + $0 + ")²"},nil),
        "x³" : Operation.UnaryOperation({ pow($0, 3) }, { "(" + $0 + ")³"},nil),
        "x⁻¹" : Operation.UnaryOperation({ 1 / $0 }, { "(" + $0 + ")⁻¹"},nil),
        "sin" : Operation.UnaryOperation(sin, { "sin(" + $0 + ")"},nil),
        "2ˣ" : Operation.UnaryOperation({pow(2, $0)}, { "2^" + $0},nil),
        "cos" : Operation.UnaryOperation(cos, { "cos(" + $0 + ")"},nil),
        "tan" : Operation.UnaryOperation(tan, { "tan(" + $0 + ")"},nil),
        "sinh" : Operation.UnaryOperation(sinh, { "sinh(" + $0 + ")"},nil),
        "cosh" : Operation.UnaryOperation(cosh, { "cosh(" + $0 + ")"},nil),
        "tanh" : Operation.UnaryOperation(tanh, { "tanh(" + $0 + ")"},nil),
        "ln" : Operation.UnaryOperation(log, { "ln(" + $0 + ")"},nil),
        "log₁₀" : Operation.UnaryOperation(log10, { "log(" + $0 + ")"},nil),
        "eˣ" : Operation.UnaryOperation(exp, { "e^(" + $0 + ")"},nil),
        "10ˣ" : Operation.UnaryOperation({ pow(10, $0) }, { "10^(" + $0 + ")"},nil),
        "x!" : Operation.UnaryOperation(factorial, { "(" + $0 + ")!"},nil),
        "×" : Operation.BinaryOperation(*, { $0 + " × " + $1 }, 1,nil),
        "÷" : Operation.BinaryOperation(/, { $0 + " ÷ " + $1 }, 1, {if $1 == 0 { throw Error.DivisionByZero }}),
        "+" : Operation.BinaryOperation(+, { $0 + " + " + $1 }, 0,nil),
        "−" : Operation.BinaryOperation(-, { $0 + " - " + $1 }, 0,nil),
        "xʸ" : Operation.BinaryOperation(pow, { $0 + " ^ " + $1 }, 2,nil),
        "yˣ" : Operation.BinaryOperation({pow($1, $0)}, { $1 + " ^ " + $0 }, 2,nil),
        "rand" : Operation.NullaryOperation(drand48, "rand()"),
        "=" : Operation.Equals
    ]
    
    private enum Operation {
        case Constant(Double)
        case UnaryOperation((Double) -> Double, (String) -> String,(Double throws -> ())?)
        case BinaryOperation((Double, Double) -> Double, (String, String) -> String, Int,((Double,Double) throws -> ())?)
        case NullaryOperation(() -> Double, String)
        case Equals
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
    
    var variableValue = [String:Double]()
    
    func setOperand(variableName: String) {
        performOperation(variableName)
    }
    
    func recalculate(){
        
        let oldProgram = internalProgram
        clear()
        program = oldProgram
    }
    
    func setOperand(operand: Double) {
        accumulator = operand
        internalProgram.append(operand)
        
        descriptionAccumulator = String(format:"%g", operand)
    }
    
    func performOperation(symbol: String) {
        internalProgram.append(symbol)
        if let operation = operations[symbol] {
            switch operation {
            case .Constant(let value):
                accumulator = value
                descriptionAccumulator = symbol
            case .NullaryOperation(let function, let descriptiveValue):
                accumulator = function()
                descriptionAccumulator = descriptiveValue
            case .UnaryOperation(let function, let descriptionFunction,_):
                accumulator = function(accumulator)
                descriptionAccumulator = descriptionFunction(descriptionAccumulator)
            case .BinaryOperation(let function, let descriptionFunction, let precedence,_):
                executePendingBinaryOperation()
                if currentPrecedence < precedence {
                    descriptionAccumulator = "(" + descriptionAccumulator + ")"
                }
                currentPrecedence = precedence
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator,
                                                     descriptionFunction: descriptionFunction, descriptionOperand: descriptionAccumulator,errorFunction: nil)
            case .Equals:
                executePendingBinaryOperation()
            }
        }else{
            accumulator = variableValue[symbol] ?? 0
            descriptionAccumulator = symbol
        }
    }
    
    func performOperationAndReportErrors(symbol: String) throws {
        internalProgram.append(symbol)
        if let operation = operations[symbol] {
            switch operation {
            case .Constant(let value):
                accumulator = value
                descriptionAccumulator = symbol
            case .NullaryOperation(let function, let descriptiveValue):
                accumulator = function()
                descriptionAccumulator = descriptiveValue
            case .UnaryOperation(let function, let descriptionFunction,let errorFunc):
                if errorFunc != nil {
                   try errorFunc!(accumulator)
                }
                accumulator = function(accumulator)
                descriptionAccumulator = descriptionFunction(descriptionAccumulator)
            case .BinaryOperation(let function, let descriptionFunction, let precedence,let errorFunc):
                try executePendingBinaryOperationWithErrors()
                if currentPrecedence < precedence {
                    descriptionAccumulator = "(" + descriptionAccumulator + ")"
                }
                currentPrecedence = precedence
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator,
                                                     descriptionFunction: descriptionFunction, descriptionOperand: descriptionAccumulator,errorFunction: errorFunc)
            case .Equals:
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
                try errorFunc(accumulator,pending!.firstOperand)
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