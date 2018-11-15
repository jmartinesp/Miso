//
//  Selector.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 14/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class Selector {
    let evaluator: EvaluatorProtocol
    let root: Element
    
    private init(query: String, root: Element) {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.evaluator = try! QueryParser.parse(query: query)
        self.root = root
    }
    
    private init(evaluator: EvaluatorProtocol, root: Element) {
        self.evaluator = evaluator
        self.root = root
    }
    
    func select() -> Elements {
        return Collector.collect(evaluator: evaluator, root: root)
    }
    
    public static func select(using query: String, from root: Element) -> Elements {
        return Selector(query: query, root: root).select()
    }
    
    public static func select(using evaluator: EvaluatorProtocol, from root: Element) -> Elements {
        return Selector(evaluator: evaluator, root: root).select()
    }
    
    public static func select(using query: String, fromAny roots: [Element]) -> Elements {
        let elements = OrderedSet<Element>()

        do {
            let evaluator = try QueryParser.parse(query: query)
            for root in roots {
                Selector.select(using: evaluator, from: root).forEach { element in elements.insert(element) }
            }

            return Elements(elements.orderedItems)
        } catch {
            print(error)
            return Elements()
        }
    }
    
    static func filterOut<T>(elements: T, excluded: T) -> Elements where T: Collection, T.Iterator.Element: Element {
        return Elements(elements.filter { !excluded.contains($0) })
    }
}
