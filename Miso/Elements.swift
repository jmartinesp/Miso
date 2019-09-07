//
//  Elements.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public typealias Elements = Array<Element>

extension Elements {
    
    public class Safe {
        
        let elements: Elements
        
        init(elements: Elements) {
            self.elements = elements
        }
        
        @discardableResult
        public func html(replaceWith newValue: String) throws -> Elements {
            try elements.forEach { try $0.safe.html(replaceWith: newValue) }
            return elements
        }
        
        @discardableResult
        public func prepend(html: String) throws -> Elements {
            try elements.forEach { try $0.safe.prepend(html: html) }
            return elements
        }
        
        @discardableResult
        public func append(html: String) throws -> Elements {
            try elements.forEach { try $0.safe.append(html: html) }
            return elements
        }
        
        @discardableResult
        public func insertBefore(html: String) throws -> Elements {
            try elements.forEach { try $0.safe.insertBefore(html: html) }
            return elements
        }
        
        @discardableResult
        public func insertAfter(html: String) throws -> Elements {
            try elements.forEach { try $0.safe.insertAfter(html: html) }
            return elements
        }
        
        @discardableResult
        public func wrap(html: String) throws -> Elements {
            try elements.forEach { try $0.safe.wrap(html: html) }
            return elements
        }
        
    }
    
    public var safe: Safe {
        return Safe(elements: self)
    }
    
    public var val: String? {
        return self.first?.val
    }
    
    public func attr(_ name: String) -> String? {
        return self.first(where: { $0.has(attr: name) })?.attr(name)
    }
    
    public func has(attr name: String) -> Bool {
        return self.first(where: { $0.has(attr: name) }) != nil
    }
    
    public func select(_ query: String) -> Elements {
        return Selector.select(using: query, fromAny: self)
    }
    
    public func first(attr: String) -> String? {
        for element in self {
            if let value = element.attr(attr) {
                return value
            }
        }
        return nil
    }
    
    public func attrs(_ attrName: String) -> [String] {
        return self.compactMap { $0.attr(attrName) }
    }
    
    @discardableResult
    public func attr(_ attrName: String, setValue value: String) -> Elements {
        self.forEach { $0.attr(attrName, setValue: value) }
        return self
    }
    
    @discardableResult
    public func remove(attr: String) -> Elements {
        self.forEach { $0.removeAttr(attr) }
        return self
    }
    
    @discardableResult
    public func addClass(_ className: String) -> Elements {
        self.forEach { $0.addClass(className) }
        return self
    }
    
    @discardableResult
    public func removeClass(_ className: String) -> Elements {
        self.forEach { $0.removeClass(className) }
        return self
    }
    
    @discardableResult
    public func toggleClass(_ className: String) -> Elements {
        self.forEach { $0.toggleClass(className) }
        return self
    }
    
    public func hasClass(_ className: String) -> Bool {
        return self.contains(where: { $0.hasClass(className) })
    }
    
    public func matches(_ query: String) -> Bool {
        return self.contains(where: { $0.matches(query: query) })
    }
    
    @discardableResult
    public func val(replaceWith newValue: String?) -> Elements {
        self.forEach { $0.val = newValue }
        return self
    }
    
    @discardableResult
    public func tagName(replaceWith newValue: String) -> Elements {
        self.forEach { $0.tagName = newValue }
        return self
    }
    
    @discardableResult
    public func html(replaceWith newValue: String) -> Elements {
        self.forEach { $0.html(replaceWith: newValue) }
        return self
    }
    
    @discardableResult
    public func prepend(html: String) -> Elements {
        self.forEach { $0.prepend(html: html) }
        return self
    }
    
    @discardableResult
    public func append(html: String) -> Elements {
        self.forEach { $0.append(html: html) }
        return self
    }
    
    @discardableResult
    public func insertBefore(html: String) -> Elements {
        self.forEach { $0.insertBefore(html: html) }
        return self
    }
    
    @discardableResult
    public func insertAfter(html: String) -> Elements {
        self.forEach { $0.insertAfter(html: html) }
        return self
    }
    
    @discardableResult
    public func wrap(html: String) -> Elements {
        self.forEach { $0.wrap(html: html) }
        return self
    }
    
    @discardableResult
    public func unwrap() -> Elements {
        self.forEach { _ = $0.unwrap() }
        return self
    }
    
    @discardableResult
    public func removeAllChildren() -> Elements {
        self.forEach { $0.removeAll() }
        return self
    }
    
    @discardableResult
    public func removeFromParent() -> Elements {
        self.forEach { $0.removeFromParent() }
        return self
    }
    
    @discardableResult
    public func not(_ query: String) -> Elements {
        let out = Selector.select(using: query, fromAny: self)
        return Selector.filterOut(elements: self, excluded: out)
    }
    
    public func subElements(at index: Int) -> Elements {
        return Elements([self[index]])
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
        var siblings = Elements()
        var evaluator: EvaluatorProtocol? = nil
        
        if query != nil {
            evaluator = try? QueryParser.parse(query: query!)
        }
        
        self.forEach {
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
        let parentElements = self.flatMap { $0.parents }.distinct()
        
        return Elements(parentElements)
    }
    
    public var html: String {
        return self.reduce(StringBuilder(), { accum, next in
                if !accum.isEmpty {
                    accum.append("\n")
                }
                accum.append(next.html)
                return accum
            })
            .stringValue
    }
    
    public var outerHTML: String {
        return self.reduce(StringBuilder(), { accum, next in
                if !accum.isEmpty {
                    accum.append("\n")
                }
                accum.append(next.outerHTML)
                return accum
            })
            .stringValue
    }
    
    public var text: String {
        return self.reduce(StringBuilder(), { accum, next in
                if !accum.isEmpty {
                    accum.append(" ")
                }
                accum.append(next.text)
                return accum
            })
            .stringValue
    }
    
    public var texts: [String] {
        return self.compactMap { $0.text }.filter { !$0.isEmpty }
    }
    
    public var hasText: Bool {
        return self.contains(where: { $0.hasText })
    }
    
    public var description: String {
        return outerHTML
    }
    
    public func traverse(nodeVisitor: NodeVisitorProtocol) -> Elements {
        let traversor = NodeTraversor(visitor: nodeVisitor)
        self.forEach { traversor.traverse(root: $0) }
        return self
    }
    
    public var forms: [FormElement] {
        return self.compactMap { $0 as? FormElement }
    }
    
}
