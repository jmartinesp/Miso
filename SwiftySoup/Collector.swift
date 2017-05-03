//
//  Collector.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class Collector {
    
    public static func collect(evaluator: EvaluatorProtocol, root: Element) -> Elements {
        var elements = Elements()
        NodeTraversor(visitor: Accumulator(root: root, elements: elements, evaluator: evaluator)).traverse(root: root)
        return elements
    }
    
    public class Accumulator: NodeVisitorProtocol {
        
        let root: Element
        var elements: Elements
        let evaluator: EvaluatorProtocol
        
        public init(root: Element, elements: Elements, evaluator: EvaluatorProtocol) {
            self.root = root
            self.elements = elements
            self.evaluator = evaluator
        }
        
        public var head: ((Node, Int) -> Void) {
            return { [unowned self] node, depth in
                if let element = node as? Element {
                    if self.evaluator.matches(root: self.root, and: element) {
                        self.elements.append(element)
                    }
                }
            }
        }
        public var tail: ((Node, Int) -> Void) {
            return { _,_ in }
        }
        
    }
    
}
