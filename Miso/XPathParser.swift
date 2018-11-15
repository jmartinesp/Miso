//
//  XPathParser.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 17/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class XPathParser {
    
    let combinators = ["//", "/", "..", "."]
    
    var tokenQueue: TokenQueue
    var query: String
    var evaluators = [XPathEvaluator]()
    
    private init(query: String) {
        self.query = query
        
        tokenQueue = TokenQueue(query: query)
    }
    
    public static func parse(query: String) throws -> [XPathEvaluator] {
        let queryParser = XPathParser(query: query)
        return try queryParser.parse()
    }
    
    func parse() throws -> [XPathEvaluator] {
        tokenQueue.consumeWhitespace()
        
        while !tokenQueue.isEmpty {
            try findElements()
        }
        
        return evaluators
    }
    
    private func findElements() throws {
        guard !tokenQueue.isEmpty else {
            throw SelectorParseException(message: "String must not be empty")
        }
        
        if tokenQueue.matches(any: combinators) {
            try combinator()
        } else if tokenQueue.matchAndChomp(text: "*") {
            allElements()
        } else if tokenQueue.matches(text: "[") {
            childrenConforms()
        } else if tokenQueue.matchesWord() {
            byTag()
        }
    }
    
    private func combinator() throws {
        var combinator = tokenQueue.consume(to: "/")
        
        if combinator.isEmpty && tokenQueue.matches(text: "//") {
            combinator = "//"
            tokenQueue.advance()
            tokenQueue.advance()
        } else if combinator.isEmpty && tokenQueue.matches(text: "/") {
            combinator = "/"
            tokenQueue.advance()
        }
        
        switch combinator {
        case ".":
            evaluators.append(XPathEvaluator.CurrentNode())
        case "//":
            if evaluators.isEmpty {
                evaluators.append(XPathEvaluator.Root())
            }
            evaluators.append(XPathEvaluator.AnyChild())
        case "/":
            if evaluators.isEmpty {
                evaluators.append(XPathEvaluator.Root())
            }
            evaluators.append(XPathEvaluator.ImmediateChildren())
        case "..":
            if evaluators.last is XPathEvaluator.ImmediateChildren {
                evaluators.removeLast()
            }
            evaluators.append(XPathEvaluator.ImmediateParent())
        default:
            tokenQueue.advance()
            break
        }        
    }
    
    private func consumeSubQuery() throws -> String {
        let accum = StringBuilder()
        
        while !tokenQueue.isEmpty {
            if tokenQueue.matches(text: "(") {
                accum += "(" + (try tokenQueue.chompBalanced(open: "(", close: ")")) + ")"
            } else if tokenQueue.matches(text: "[") {
                accum += "[" + (try tokenQueue.chompBalanced(open: "[", close: "]")) + "]"
            } else if tokenQueue.matches(any: combinators) {
                break
            } else {
                accum.append(tokenQueue.consume())
            }
        }
        
        return accum.stringValue
    }
    
    private func byTag() {
        let tag = tokenQueue.consumeElementSelector()
        
        if evaluators.isEmpty {
            evaluators.append(XPathEvaluator.ImmediateChildren())
        }
        evaluators.append(XPathEvaluator.NameIs(tag))
    }
    
    private func allElements() {
        evaluators.append(XPathEvaluator.AllElements())
    }
    
    private func childrenConforms() {
        tokenQueue.advance()
        let queryKey = tokenQueue.consume(toAny: [" ", "]", "="])
        tokenQueue.consumeWhitespace()
        
        if let index = Int(queryKey, radix: 10) {
            evaluators.append(XPathEvaluator.Index(index))
        } else if queryKey.hasPrefix("@") {
            let attributeName = queryKey[1..<queryKey.unicodeScalars.count]
            
            tokenQueue.consumeWhitespace()
            
            if tokenQueue.matches(any: ["="]) {
                let operation = tokenQueue.consume()
                
                if operation == "=" {
                    tokenQueue.consumeWhitespace()
                    var value = tokenQueue.consume(to: "]")
                    
                    if value.hasPrefix("\"") || value.hasPrefix("'") {
                        value = value[1..<value.unicodeScalars.count-1].trimmingCharacters(in: .whitespaces)
                    }
                    evaluators.append(XPathEvaluator.HasAttributeValue(name: attributeName, value: value))
                }
            } else {
                evaluators.append(XPathEvaluator.HasAttribute(attributeName))
            }
        } else if queryKey == "last()" {
            evaluators.append(XPathEvaluator.Index(-1))
        } else if queryKey == "first()" {
            evaluators.append(XPathEvaluator.Index(0))
        } else if !queryKey.isEmpty {
            tokenQueue.consumeWhitespace()
            if tokenQueue.matches(any: ["="]) {
                let operation = tokenQueue.consume()
                
                if operation == "=" {
                    tokenQueue.consumeWhitespace()
                    var textValue = tokenQueue.consume(to: "]")
                    
                    if textValue.hasPrefix("\"") || textValue.hasPrefix("'") {
                        textValue = textValue[1..<textValue.unicodeScalars.count-1].trimmingCharacters(in: .whitespaces)
                    }
                    evaluators.append(XPathEvaluator.HasChildrenWithTextValue(textValue))
                }
            } else {
                evaluators.append(XPathEvaluator.HasChildrenNamed(queryKey))
            }
        }
        
        if tokenQueue.matches(text: "and") {
            // TODO
        }
        
        tokenQueue.advance()
    }
}

