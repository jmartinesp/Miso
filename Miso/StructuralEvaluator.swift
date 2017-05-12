//
//  StructuralEvaluator.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 14/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class StructuralEvaluator: EvaluatorProtocol {
    var evaluator: EvaluatorProtocol! = nil
    
    public func matches(root: Element?, and element: Element) -> Bool {
        fatalError("\(#function) in \(self.self) must be overriden")
    }
    
    public var description: String {
        return "StructuralEvaluator"
    }
    
    class Root: EvaluatorProtocol {
        func matches(root: Element?, and element: Element) -> Bool {
            return root == element
        }
        
        var description: String {
            return "root()"
        }
    }
    
    class Has: StructuralEvaluator {
        init(_ evaluator: EvaluatorProtocol) {
            super.init()
            self.evaluator = evaluator
        }
        
        override func matches(root: Element?, and element: Element) -> Bool {
            let allElements = Collector.collect(evaluator: Evaluator.AllElements(), root: element)
            for e in allElements {
                if e != element && evaluator.matches(root: root, and: e) {
                    return true
                }
            }
            return false
        }
        
        override var description: String {
            return ":has\(evaluator.description)"
        }
    }
    
    class Not: StructuralEvaluator {
        init(_ evaluator: EvaluatorProtocol) {
            super.init()
            self.evaluator = evaluator
        }
        
        override func matches(root: Element?, and element: Element) -> Bool {
            return !evaluator.matches(root: root, and: element)
        }
        
        override var description: String {
            return ":not\(evaluator.description)"
        }
    }
    
    class Parent: StructuralEvaluator {
        init(_ evaluator: EvaluatorProtocol) {
            super.init()
            self.evaluator = evaluator
        }
        
        override func matches(root: Element?, and element: Element) -> Bool {
            guard root != element else { return false }
            guard root != nil, element.parentElement != nil else { return false }
            
            var parent: Element? = element.parentElement
            
            while parent != nil {
                if evaluator.matches(root: root, and: parent!) {
                    return true
                }
                if root == parent {
                    break
                }
                parent = parent?.parentElement
            }
            return false
        }
        
        override var description: String {
            return ":parent\(evaluator.description)"
        }
    }
    
    class ImmediateParent: StructuralEvaluator {
        init(_ evaluator: EvaluatorProtocol) {
            super.init()
            self.evaluator = evaluator
        }
        
        override func matches(root: Element?, and element: Element) -> Bool {
            guard root != element else { return false }
            
            guard let parent = element.parentElement else { return false }
            
            return evaluator.matches(root: root, and: parent)
        }
        
        override var description: String {
            return ":ImmediateParent\(evaluator.description)"
        }
    }
    
    class PreviousSibling: StructuralEvaluator {
        init(_ evaluator: EvaluatorProtocol) {
            super.init()
            self.evaluator = evaluator
        }
        
        override func matches(root: Element?, and element: Element) -> Bool {
            guard root != element else { return false }
            
            var prev = element.previousSiblingElement
            
            while prev != nil {
                if evaluator.matches(root: root, and: prev!) {
                    return true
                }
                prev = prev?.previousSiblingElement
            }
            
            return false
        }
        
        override var description: String {
            return ":prev*\(evaluator.description)"
        }
    }
    
    class ImmediatePreviousSibling: StructuralEvaluator {
        init(_ evaluator: EvaluatorProtocol) {
            super.init()
            self.evaluator = evaluator
        }
        
        override func matches(root: Element?, and element: Element) -> Bool {
            guard root != element else { return false }
            
            guard let prev = element.previousSiblingElement else { return false }
            
            return evaluator.matches(root: root, and: prev)
        }
        
        override var description: String {
            return ":prev\(evaluator.description)"
        }
    }
}
