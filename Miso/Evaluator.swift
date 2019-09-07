//
//  EvaluatorProtocol.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 11/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public protocol EvaluatorProtocol: CustomStringConvertible {
    
    func matches(root: Element?, and element: Element) -> Bool
    
}

public class Evaluator {
    
    //======================================================================
    // MARK: Tag
    //======================================================================
    
    struct TagIs: EvaluatorProtocol {
        
        let tagName: String
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.tagName.lowercased() == tagName.lowercased()
        }
        
        var description: String {
            return tagName
        }
    }
    
    struct TagEndsWith: EvaluatorProtocol {
        
        let tagName: String
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.tagName.lowercased().hasSuffix(tagName.lowercased())
        }
        
        var description: String {
            return tagName
        }
    }
    
    //======================================================================
    // MARK: Id
    //======================================================================
    
    struct IdIs: EvaluatorProtocol {
        
        let id: String
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.id?.lowercased() == id.lowercased()
        }
        
        var description: String {
            return "#\(id)"
        }
    }
    
    //======================================================================
    // MARK: Class
    //======================================================================
    
    struct HasClass: EvaluatorProtocol {
        
        let className: String
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.hasClass(className)
        }
        
        var description: String {
            return ".\(className)"
        }
    }
    
    //======================================================================
    // MARK: Attribute
    //======================================================================
    
    class AttributeKeyPair: EvaluatorProtocol {
        
        var key: String
        var value: String
        
        init(key: String, value: String) throws {
            guard !key.isEmpty else {
                throw SelectorParseException(message: "Attribute selector key cannot be empty")
            }
            
            guard !value.isEmpty else {
                throw SelectorParseException(message: "Attribute selector value cannot be empty")
            }
            
            self.key = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            self.value = value
            
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                (value.hasPrefix("'") && value.hasSuffix("'")) {
                self.value = self.value[1..<self.value.unicodeScalars.count-1]
            }
            self.value = self.value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        
        func matches(root: Element?, and element: Element) -> Bool {
            fatalError("\(#function) in \(self.self) must be overriden")
        }
        
        var description: String {
            return "[\(key)]"
        }
    }
    
    struct HasAttribute: EvaluatorProtocol {
        
        let attrName: String
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.has(attr: attrName)
        }
        
        var description: String {
            return attrName
        }
        
    }
    
    struct HasAttributeStartingWith: EvaluatorProtocol {
        
        let attrStart: String
        
        func matches(root: Element?, and element: Element) -> Bool {
            return !element.attributes.keys.filter { $0.hasPrefix(self.attrStart.lowercased()) }.isEmpty
        }
        
        var description: String {
            return "[^\(attrStart)]"
        }
    }
    
    class HasAttributeWithValue: AttributeKeyPair {
        
        override func matches(root: Element?, and element: Element) -> Bool {
            return element.attributes.get(byTag: key)?.value.lowercased() == self.value
        }
        
        override var description: String {
            return "[\(key)=\(value)]"
        }
    }
    
    class HasAttributeWithValueNot: AttributeKeyPair {
        
        override func matches(root: Element?, and element: Element) -> Bool {
            return element.attributes.get(byTag: key)?.value.lowercased() != self.value
        }
        
        override var description: String {
            return "[\(key)!=\(value)]"
        }
        
    }
    
    class HasAttributeWithValueStartingWith: AttributeKeyPair {
        
        override func matches(root: Element?, and element: Element) -> Bool {
            if let value = element.attributes.get(byTag: key)?.value.lowercased() {
                return value.hasPrefix(self.value)
            }
            return false
        }
        
        override var description: String {
            return "[\(key)^=\(value)]"
        }
        
    }
    
    class HasAttributeWithValueEndingWith: AttributeKeyPair {
        
        override func matches(root: Element?, and element: Element) -> Bool {
            if let value = element.attributes.get(byTag: key)?.value.lowercased() {
                return value.hasSuffix(self.value.lowercased())
            }
            return false
        }
        
        override var description: String {
            return "[\(key)$=\(value)]"
        }
        
    }
    
    class HasAttributeWithValueContaining: AttributeKeyPair {
        
        override func matches(root: Element?, and element: Element) -> Bool {
            if let value = element.attributes.get(byTag: key)?.value.lowercased() {
                return value.contains(self.value)
            }
            return false
        }
        
        override var description: String {
            return "[\(key)*=\(value)]"
        }
        
    }
    
    struct HasAttributeWithValueMatching: EvaluatorProtocol {
        
        let key: String
        let pattern: String
        
        func matches(root: Element?, and element: Element) -> Bool {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
                return false
            }
            
            if let value = element.attributes.get(byTag: key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())?.value {
                return regex.numberOfMatches(in: value, options: [], range: NSRange(location: 0, length: value.unicodeScalars.count)) > 0
            }
            
            return false
        }
        
        var description: String {
            return "[\(key)~=\(pattern)]"
        }
    }
    
    //======================================================================
    // MARK: All (*)
    //======================================================================
    
    struct AllElements: EvaluatorProtocol {
        
        func matches(root: Element?, and element: Element) -> Bool {
            return true
        }
        
        var description: String {
            return "*"
        }
    }
    
    //======================================================================
    // MARK: Indexes
    //======================================================================
    
    struct IndexLessThan: EvaluatorProtocol {
        
        let index: Int
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.elementSiblingIndex != nil && element.elementSiblingIndex! < index
        }
        
        var description: String {
            return ":lt(\(index))"
        }
    }
    
    struct IndexGreaterThan: EvaluatorProtocol {
        
        let index: Int
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.elementSiblingIndex != nil && element.elementSiblingIndex! > index
        }
        
        var description: String {
            return ":gt(\(index))"
        }
    }
    
    struct IndexEquals: EvaluatorProtocol {
        
        let index: Int
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.elementSiblingIndex == index
        }
        
        var description: String {
            return ":eq(\(index))"
        }
    }
    
    //======================================================================
    // MARK: nth-child
    //======================================================================
    
    struct IsLastChild: EvaluatorProtocol {
        
        func matches(root: Element?, and element: Element) -> Bool {
            return !(element.parentElement is Document) && element.parentElement?.children.last == element
        }
        
        var description: String {
            return ":last-child"
        }
    }
    
    struct IsFirstChild: EvaluatorProtocol {
        
        func matches(root: Element?, and element: Element) -> Bool {
            return !(element.parentElement is Document) && element.parentElement?.children.first == element
        }
        
        var description: String {
            return ":first-child"
        }
    }
    
    class CssNthEvaluator: EvaluatorProtocol {
        
        // a(n) + b
        let a: Int
        let b: Int
        
        init(a: Int, b: Int) {
            self.a = a
            self.b = b
        }
        
        convenience init(b: Int) {
            self.init(a: 0, b: b)
        }
        
        func matches(root: Element?, and element: Element) -> Bool {
            guard element.parentNode != nil && !(element.parentNode is Document) else { return false }
            
            let pos = calculatePosition(root: root, and: element)
            guard a != 0 else { return pos == b }
            
            return (pos-b)*a >= 0 && (pos-b)%a == 0
        }
        
        var pseudoClass: String { return "" }
        func calculatePosition(root: Element?, and element: Element) -> Int { fatalError("\(#function) in \(self.self) must be overriden") }
        
        var description: String {
            if (a == 0) {
                return ":\(pseudoClass)(\(b))"
            }
            if (b == 0) {
                return ":\(pseudoClass)(\(a)n)"
            }
            return ":\(pseudoClass)(\(a)n+\(b))"
        }
        
    }
    
    class IsFirstOfType: IsNthOfType {
        
        init() {
            super.init(a: 0, b: 1)
        }
        
        override var description: String {
            return ":first-of-type"
        }
        
    }
    
    class IsLastOfType: IsNthLastOfType {
        
        init() {
            super.init(a: 0, b: 1)
        }
        
        override var description: String {
            return ":last-of-type"
        }
        
    }
    
    class IsNthChild: CssNthEvaluator {
        
        override init(a: Int, b: Int) {
            super.init(a: a, b: b)
        }
        
        override func calculatePosition(root: Element?, and element: Element) -> Int {
            guard element.elementSiblingIndex != nil else { return -1 }
            return element.elementSiblingIndex! + 1
        }
        
        override var pseudoClass: String { return "nth-child" }
        
    }
    
    class IsNthLastChild: CssNthEvaluator {
        
        override init(a: Int, b: Int) {
            super.init(a: a, b: b)
        }
        
        override func calculatePosition(root: Element?, and element: Element) -> Int {
            guard element.elementSiblingIndex != nil else { return -1 }
            return element.parentElement!.children.count - element.elementSiblingIndex!
        }
        
        override var pseudoClass: String { return "nth-last-child" }
    }
    
    class IsNthOfType: CssNthEvaluator {
        
        override init(a: Int, b: Int) {
            super.init(a: a, b: b)
        }
        
        override func calculatePosition(root: Element?, and element: Element) -> Int {
            let type = element.tagName
            guard let allElements = element.parentElement?.children else {
                return -1
            }
            
            let elementsOfType = allElements.filter { $0.tagName == type }
            
            guard let index = elementsOfType.firstIndex(of: element) else { return -1 }
            return index + 1
        }
        
        override var pseudoClass: String { return "nth-of-type" }
    }
    
    class IsNthLastOfType: CssNthEvaluator {
        
        override init(a: Int, b: Int) {
            super.init(a: a, b: b)
        }
        
        override func calculatePosition(root: Element?, and element: Element) -> Int {
            return element.parentElement!.children.filter {
                    $0.tagName == element.tagName
                }.reversed().firstIndex(of: element)! + 1
        }
        
        override var pseudoClass: String { return "nth-last-of-type" }
    }
    
    //======================================================================
    // MARK: Root
    //======================================================================
    
    struct IsRoot: EvaluatorProtocol {
        
        func matches(root: Element?, and element: Element) -> Bool {
            let root = root is Document ? root!.children[0] : root
            return root == element
        }
        
        var description: String {
            return ":root"
        }
    }
    
    //======================================================================
    // MARK: Only
    //======================================================================
    
    struct IsOnlyChild: EvaluatorProtocol {
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.siblingElements.isEmpty
        }
        
        var description: String {
            return ":only-child"
        }
    }
    
    struct IsOnlyOfType: EvaluatorProtocol {
        
        func matches(root: Element?, and element: Element) -> Bool {
            guard element.parentNode != nil && !(element.parentNode! is Document) else { return false }
            return element.siblingElements.filter { $0.tagName == element.tagName }.isEmpty
        }
        
        var description: String {
            return ":only-of-type"
        }
    }
    
    struct IsEmpty: EvaluatorProtocol {
        
        func matches(root: Element?, and element: Element) -> Bool {
            for child in element.childNodes {
                if !(child is Comment || child is XmlDeclaration || child is DocumentType) {
                    return false
                }
            }
            return true
        }
        
        var description: String {
            return ":empty"
        }
    }
    
    //======================================================================
    // MARK: Contains
    //======================================================================
    
    struct ContainsText: EvaluatorProtocol {
        
        let searchText: String
        
        init(searchText: String) {
            self.searchText = searchText.lowercased()
        }
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.text.lowercased().contains(searchText)
        }
        
        var description: String {
            return ":contains(\(searchText))"
        }
    }
    
    struct ContainsData: EvaluatorProtocol {
        
        let searchData: String
        
        init(searchData: String) {
            self.searchData = searchData.lowercased()
        }
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.data.lowercased().contains(searchData)
        }
        
        var description: String {
            return ":containsData(\(searchData))"
        }
    }
    
    struct ContainsOwnText: EvaluatorProtocol {
        
        let searchOwnText: String
        
        init(searchOwnText: String) {
            self.searchOwnText = searchOwnText.lowercased()
        }
        
        func matches(root: Element?, and element: Element) -> Bool {
            return element.ownText.lowercased().contains(searchOwnText)
        }
        
        var description: String {
            return ":containsOwn(\(searchOwnText))"
        }
    }
    
    //======================================================================
    // MARK: Matches
    //======================================================================
    
    struct MatchesText: EvaluatorProtocol {
        
        let pattern: String
        
        func matches(root: Element?, and element: Element) -> Bool {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
                return false
            }
            return regex.numberOfMatches(in: element.text, options: [], range:
                NSRange(location: 0, length: element.text.unicodeScalars.count)) > 0
        }
        
        var description: String {
            return ":matches(\(pattern))"
        }
    }
    
    struct MatchesOwnText: EvaluatorProtocol {
        
        let pattern: String
        
        func matches(root: Element?, and element: Element) -> Bool {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
                return false
            }
            return regex.numberOfMatches(in: element.ownText, options: [.anchored], range:
                NSRange(location: 0, length: element.ownText.unicodeScalars.count)) > 0
        }
        
        var description: String {
            return ":matchesOwn(\(pattern))"
        }
    }
    
}
