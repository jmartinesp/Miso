//
//  Elements.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class Elements: List<Element>, CustomStringConvertible {
    
    init() {
        super.init([])
    }
    
    public override init(_ elements: Array<Element>) {
        super.init(elements)
    }
    
    public init(_ elements: Set<Element>) {
        super.init([])
        self.elements.append(contentsOf: elements)
    }
        
    public func attr(_ name: String) -> String? {
        return elements.first(where: { $0.has(attr: name) })?.attr(name)
    }
    
    public func has(attr name: String) -> Bool {
        return elements.first(where: { $0.has(attr: name) }) != nil
    }
    
    public func select(_ query: String) -> Elements {
        return Selector.select(using: query, fromAny: self.elements)
    }
    
    public func first(attr: String) -> String? {
        for element in elements {
            if let value = element.attr(attr) {
                return value
            }
        }
        return nil
    }
    
    public func attrs(_ attrName: String) -> [String] {
        return elements.flatMap { $0.attr(attrName) }
    }
    
    public func attr(_ attrName: String, setValue value: String) -> Elements {
        elements.forEach { $0.attr(attrName, setValue: value) }
        return self
    }
    
    public func remove(attr: String) -> Elements {
        elements.forEach { $0.removeAttr(attr) }
        return self
    }
    
    public func addClass(_ className: String) -> Elements {
        elements.forEach { $0.addClass(className) }
        return self
    }
    
    public func removeClass(_ className: String) -> Elements {
        elements.forEach { $0.removeClass(className) }
        return self
    }
    
    public func toggleClass(_ className: String) -> Elements {
        elements.forEach { $0.toggleClass(className) }
        return self
    }
    
    public func hasClass(_ className: String) -> Bool {
        return elements.first { $0.hasClass(className) } != nil
    }
    
    public func matches(_ query: String) -> Bool {
        return elements.first { $0.matches(query: query) } != nil
    }
    
    public var val: String? {
        return elements.first?.val
    }
    
    public func val(replaceWith newValue: String?) -> Elements {
        elements.forEach { $0.val = newValue }
        return self
    }
    
    public func tagName(replaceWith newValue: String) -> Elements {
        elements.forEach { $0.tagName = newValue }
        return self
    }
    
    public func html(replaceWith newValue: String) -> Elements {
        elements.forEach { $0.html(replaceWith: newValue) }
        return self
    }
    
    public func prepend(html: String) -> Elements {
        elements.forEach { $0.prepend(html: html) }
        return self
    }
    
    public func append(html: String) -> Elements {
        elements.forEach { $0.append(html: html) }
        return self
    }
    
    public func insertBefore(html: String) -> Elements {
        elements.forEach { $0.insertBefore(html: html) }
        return self
    }
    
    public func insertAfter(html: String) -> Elements {
        elements.forEach { $0.insertAfter(html: html) }
        return self
    }
    
    public func wrap(html: String) -> Elements {
        elements.forEach { $0.wrap(html: html) }
        return self
    }
    
    public func unwrap() -> Elements {
        elements.forEach { $0.unwrap() }
        return self
    }
    
    public func removeAllChildren() -> Elements {
        elements.forEach { $0.removeAll() }
        return self
    }
    
    public func removeFromParent() -> Elements {
        elements.forEach { $0.removeFromParent() }
        return self
    }
    
    public func not(_ query: String) -> Elements {
        let out = Selector.select(using: query, fromAny: self.elements)
        return Selector.filterOut(elements: self.elements, excluded: out.elements)
    }
    
    public func subElements(at index: Int) -> Elements {
        return Elements([self.elements[index]])
    }
    
    public var next: Elements {
        return siblings(query: nil, next: true, all: false)
    }
    
    public func next(_ query: String) -> Elements {
        return siblings(query: query, next: true, all: false)
    }
    
    public var previous: Elements {
        return siblings(query: nil, next: false, all: false)
    }
    
    public func previous(_ query: String) -> Elements {
        return siblings(query: query, next: false, all: false)
    }
    
    public var nextForAll: Elements {
        return siblings(query: nil, next: true, all: true)
    }
    
    public func nextForAll(_ query: String) -> Elements {
        return siblings(query: query, next: true, all: true)
    }
    
    public var previousForAll: Elements {
        return siblings(query: nil, next: false, all: true)
    }
    
    public func previousForAll(_ query: String) -> Elements {
        return siblings(query: query, next: false, all: true)
    }
    
    private func siblings(query: String?, next: Bool, all: Bool) -> Elements {
        let siblings = Elements()
        var evaluator: EvaluatorProtocol? = nil
        
        if query != nil {
             evaluator = try? QueryParser.parse(query: query!)
        }
        
        self.elements.forEach {
            var element = $0
            repeat {
                let sibling = next ? element.nextSiblingElement : element.previousSiblingElement
                guard sibling != nil else { return }
                
                if evaluator == nil || (evaluator != nil && sibling!.matches(evaluator: evaluator!)) {
                    siblings.append(sibling!)
                }
                element = sibling!
            } while (all)
        }
        
        return siblings
    }
    
    public var parents: Elements {
        let parentElements = self.elements.flatMap { $0.parents.elements }.distinct()
        
        return Elements(parentElements)
    }
    
    public var html: String {
        let accum = StringBuilder()
        for element in self {
            if !accum.isEmpty {
                accum.append("\n")
            }
            accum.append(element.html)
        }
        
        return accum.stringValue
    }
    
    public var outerHTML: String {
        let accum = StringBuilder()
        for element in self {
            if !accum.isEmpty {
                accum.append("\n")
            }
            accum.append(element.outerHTML)
        }
        
        return accum.stringValue
    }
    
    public var text: String {
        let accum = StringBuilder()
        for element in self {
            if !accum.isEmpty {
                accum.append(" ")
            }
            accum.append(element.text)
        }
        
        return accum.stringValue
    }
    
    public var texts: [String] {
        return elements.flatMap { $0.text }.filter { !$0.isEmpty }
    }
    
    public var hasText: Bool {
        return elements.first { $0.hasText } != nil
    }
    
    public var description: String {
        return outerHTML
    }
    
    public func traverse(nodeVisitor: NodeVisitorProtocol) -> Elements {
        let traversor = NodeTraversor(visitor: nodeVisitor)
        elements.forEach { traversor.traverse(root: $0) }
        return self
    }
    
    public var forms: [FormElement] {
        return self.elements.flatMap { $0 as? FormElement }
    }
    
}
