//
//  CombiningEvaluator.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 14/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

class CombiningEvaluator: EvaluatorProtocol {
    var evaluators: [EvaluatorProtocol]
    var num: Int { return evaluators.count }
    
    init() {
        self.evaluators = []
    }
    
    init(_ evaluators: EvaluatorProtocol...) {
        self.evaluators = []
        self.evaluators.append(contentsOf: evaluators)
    }
    
    init(_ evaluators: [EvaluatorProtocol]) {
        self.evaluators = []
        self.evaluators.append(contentsOf: evaluators)
    }
    
    var rightMostEvaluator: EvaluatorProtocol? {
        get {
            return evaluators.last
        }
        set {
            if num > 0 && newValue != nil {
                evaluators[num - 1] = newValue!
            }
        }
    }
    
    func matches(root: Element?, and element: Element) -> Bool {
        fatalError("\(#function) in \(self.self) must be overriden")
    }
    
    var description: String {
        return "CombiningEvaluator"
    }
    
    class And: CombiningEvaluator {
        override init() {
            super.init()
        }
        
        override init(_ evaluators: EvaluatorProtocol...) {
            super.init(evaluators)
        }
        
        override init(_ evaluators: [EvaluatorProtocol]) {
            super.init(evaluators)
        }
        
        override func matches(root: Element?, and element: Element) -> Bool {
            for e in evaluators {
                if !e.matches(root: root, and: element) {
                    return false
                }
            }
            return true
        }
        
        override var description: String {
            return evaluators.joined(" ")
        }
    }
    
    class Or: CombiningEvaluator {
        
        override init() {
            super.init()
        }
        
        /**
         * Create a new Or evaluator. The initial evaluators are ANDed together and used as the first clause of the OR.
         * @param evaluators initial OR clause (these are wrapped into an AND evaluator).
         */
        override init(_ evaluators: [EvaluatorProtocol]) {
            super.init()
            
            if num > 1 {
                self.evaluators.append(And(evaluators))
            } else {
                self.evaluators.append(contentsOf: evaluators)
            }
        }
        
        override init(_ evaluators: EvaluatorProtocol...) {
            super.init()

            if num > 1 {
                self.evaluators.append(And(evaluators))
            } else {
                self.evaluators.append(contentsOf: evaluators)
            }
        }
        
        override func matches(root: Element?, and element: Element) -> Bool {
            for e in evaluators {
                if e.matches(root: root, and: element) {
                    return true
                }
            }
            return false
        }
        
        func add(_ evaluator: EvaluatorProtocol) {
            self.evaluators.append(evaluator)
        }
        
        override var description: String {
            return ":or\(self.evaluators.joined(" "))"
        }
    }
}
