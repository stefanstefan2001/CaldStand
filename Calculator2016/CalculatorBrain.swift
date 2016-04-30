//
//  CalculatorBrain.swift
//  Calculator2016
//
//  Created by Stefan Scoarta on 4/29/16.
//  Copyright © 2016 Stefan Scoarta. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    private var accumulator = 0.0
    
    private var internalProgram = [AnyObject]()
    
    func setOperand(operand: Double){
        accumulator = operand
        internalProgram.append(operand)
        opStack.append(Op.Operand(operand))
    }
    
    private var operations: [String:Operation] = [
        "π" : Operation.Constant(M_PI),
        "e" : Operation.Constant(M_E),
        "√" : Operation.UnaryOperation(sqrt),
        "ᐩ/-": Operation.UnaryOperation { -$0 },
        "cos" : Operation.UnaryOperation(cos),
        "sin" : Operation.UnaryOperation(sin),
        "tan" : Operation.UnaryOperation(tan),
        "%" : Operation.UnaryOperation { $0 / 100},
        "log₁₀" : Operation.UnaryOperation(log10),
        "×" : Operation.BinaryOperation(*),
        "÷" : Operation.BinaryOperation(/),
        "+" : Operation.BinaryOperation(+),
        "−" : Operation.BinaryOperation(-),
        "=" : Operation.Equals,
        "rand" : Operation.RandomNumber(Double.random)
    ]
    
    private enum Operation {
        case Constant(Double)
        case UnaryOperation((Double) -> Double)
        case BinaryOperation((Double,Double) -> Double)
        case RandomNumber(Double)
        case Equals
    }
    
    private enum Op{
        case Operand(Double)
        case Operation(CalculatorBrain.Operation,String)
    }
    
    private var opStack : [Op] = []
    
    //TODO: Right now this isn't working as intended, it might need to be done from scrach
    var description: String{
        var result: String = " "
        for op in opStack{
            switch op {
            case .Operand(let value):
                let numberFormatter = NSNumberFormatter()
                numberFormatter.maximumFractionDigits = 6
                numberFormatter.minimumIntegerDigits = 1
                
                let numberString = numberFormatter.stringFromNumber(value)!
                result += numberString + " "
                
            case .Operation(let kind, let operation):
                switch kind {
                case .Equals: continue
                default: break
                }
                result += operation + " "
            }
        }
        
        
        return result
    }
    
    
    func performOperation(symbol: String){
        if let operation = operations[symbol]{
            
            opStack.append(Op.Operation(operation,symbol))
            internalProgram.append(symbol)
            
            switch operation {
            case .Constant(let value):
                accumulator = value
            case .UnaryOperation(let function):
                accumulator = function(accumulator)
            case .BinaryOperation(let function) :
                executePendingBinaryOperation()
                pending = PendingBinaryOperationInfo(binaryFunciton: function, firstOperand: accumulator)
            case .Equals :
                executePendingBinaryOperation()
            case .RandomNumber(let value):
                accumulator = value
            }
        }
    }
    
    private func executePendingBinaryOperation(){
        if pending != nil{
            accumulator = pending!.binaryFunciton(pending!.firstOperand,accumulator)
            pending = nil
        }
    }
    
    private var pending: PendingBinaryOperationInfo?
    
    private struct PendingBinaryOperationInfo{
        var binaryFunciton: (Double,Double) -> Double
        var firstOperand: Double
    }
    
    var isPartialResult: Bool{
        return pending != nil ? true : false
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
    
    func clear() {
        accumulator = 0
        pending = nil
        internalProgram.removeAll()
        opStack.removeAll()
    }
    
    var result: Double{
        get{
            return accumulator
        }
    }
}

public extension Double {
    /// Returns a random floating point number between 0.0 and 1.0, inclusive.
    public static var random : Double {
        return Double(arc4random()) / 0xFFFFFFFF
    }
}