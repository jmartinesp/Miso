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
    
    public func removeFromParent() {
        elements.forEach { $0.removeFromParent() }
    }
    
    public func attr(_ name: String) -> String? {
        return elements.first(where: { $0.has(attr: name) })?.attr(name)
    }
    
    public func has(attr name: String) -> Bool {
        return elements.first(where: { $0.has(attr: name) }) != nil
    }
    
    public var val: String? {
        return elements.first?.val
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
                accum.append("\n")
            }
            accum.append(element.text)
        }
        
        return accum.stringValue
    }
    
    public var description: String {
        return outerHTML
    }
    
}
