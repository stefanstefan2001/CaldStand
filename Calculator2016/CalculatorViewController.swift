//
//  ViewController.swift
//  Calculator2016
//
//  Created by Stefan Scoarta on 4/20/16.
//  Copyright © 2016 Stefan Scoarta. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    
    private var userIsInTheMiddleOfTyping = false
    
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var display: UILabel!
    
    @IBAction private func touchDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsInTheMiddleOfTyping{
            // If the user taps the period and there is a period in the display then do nothing
            if (digit == ".") && (display.text?.rangeOfString(".") != nil ) { return }
            display.text! += digit
        }else{
            display.text = digit
            userIsInTheMiddleOfTyping = true
        }
    }
    
    private var equalsWasJustUsed = false
    
    private var displayValue: Double?{
        get{
            return Double(display.text!)
        }set{
            let numberFormatter = NSNumberFormatter()
            numberFormatter.maximumFractionDigits = 6
            numberFormatter.minimumIntegerDigits = 1
            display.text = numberFormatter.stringFromNumber(newValue!)
        }
    }
    
    private let brain = CalculatorBrain()
    
    private var brainDescription: String {
        var description = brain.description
        if brain.isOperationPending{
            description += " ..."
        }
        if equalsWasJustUsed{
            description += " ="
        }
        return description
        
    }
    
    @IBAction private func setVariable() {
        brain.variableValue["M"] = displayValue
        brain.recalculate()
        userIsInTheMiddleOfTyping = false
        equalsWasJustUsed = false
        updateUI()
    }
    
    @IBAction func pushVariable() {
        brain.setOperand("M")
        updateUI()
    }
    
    
    @IBAction private func clear() {
        brain.clear()
        brain.variableValue["M"] = 0
        displayValue = 0
        descriptionLabel.text = " "
        userIsInTheMiddleOfTyping = false
        equalsWasJustUsed = false
    }
    
    @IBAction private func backspace() {
        if userIsInTheMiddleOfTyping{
            var char = display.text!.characters
            if char.count >= 0{
                char.removeLast()
            }
            display.text! = String(char)
            if char.count == 0 {
                displayValue = 0
                userIsInTheMiddleOfTyping = false
            }
        }else{
            brain.undo()
            equalsWasJustUsed = false
            updateUI()
            
        }
    }
    
    @IBAction private func performOperation(sender: UIButton) {
        if userIsInTheMiddleOfTyping{
            if let value = displayValue{
                brain.setOperand(value)
            }
            userIsInTheMiddleOfTyping = false
        }
        do{
            if let mathematicalSymbol = sender.currentTitle{
                equalsWasJustUsed = false
                try brain.performOperationAndReportErrors(mathematicalSymbol)
                if mathematicalSymbol == "="{
                    equalsWasJustUsed = true
                }
            }
            updateUI()
        }catch Error.SquareRootOfNegativeNumber{
            display.text = "Square Root of Negative Number"
        }catch Error.DivisionByZero{
            display.text = "Division by Zero"
        }catch{
            display.text = "Something went wrong"
        }
    }
    
    private func updateUI(){
        displayValue = brain.result
        descriptionLabel.text = brainDescription
    }
}