//
//  QueryParser.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 12/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class QueryParser {
    
    static let combinators: [UnicodeScalar] = [",", ">", "+", "~", " "]
    static let AttributeEvals: [String] = ["=", "!=", "^=", "$=", "*=", "~="]
    
    var tokenQueue: TokenQueue
    var query: String
    var evaluators = [EvaluatorProtocol]()
    var errors = ParseErrorList.tracking()
    
    private init(query: String) {
        self.query = query
        
        tokenQueue = TokenQueue(query: query)
    }
    
    public static func parse(query: String) throws -> EvaluatorProtocol {
        let queryParser = QueryParser(query: query)
        return try queryParser.parse()
    }
    
    func parse() throws -> EvaluatorProtocol {
        tokenQueue.consumeWhitespace()
        
        if tokenQueue.matches(any: QueryParser.combinators) { // if starts with a combinator, use root as elements
            evaluators.append(StructuralEvaluator.Root())
            combinator(tokenQueue.consume())
        } else {
            findElements()
        }
        
        while !tokenQueue.isEmpty {
            let foundWhite = tokenQueue.consumeWhitespace()
            
            if tokenQueue.matches(any: QueryParser.combinators) {
                combinator(tokenQueue.consume())
            } else if foundWhite {
                combinator(" ")
            } else { // E.class, E#id, E[attr] etc. AND
                findElements()
            }
        }
        
        if evaluators.count == 1 {
            return evaluators[0]
        }
        
        return CombiningEvaluator.And(evaluators)
    }
    
    private func combinator(_ combinator: UnicodeScalar) {
        tokenQueue.consumeWhitespace()
        
        let subQuery = consumeSubQuery()
        
        var rootEvaluator: EvaluatorProtocol // the topmost evaluator
        var currentEvaluator: EvaluatorProtocol // the evaluator the eval will be combined to. could be root, or rightmost or.
        var newEvaluator = try? QueryParser.parse(query: subQuery) // the evaluator to add into target evaluator

        guard newEvaluator != nil else { return }
        
        var replaceRightMost = false
        
        if evaluators.count == 1 {
            currentEvaluator = evaluators[0]
            rootEvaluator = currentEvaluator
            
            if let orEvaluator = currentEvaluator as? CombiningEvaluator.Or, combinator != "," {
                currentEvaluator = orEvaluator.rightMostEvaluator!
                replaceRightMost = true
            }
        } else {
            currentEvaluator = CombiningEvaluator.And(evaluators)
            rootEvaluator = currentEvaluator
        }
        
        evaluators.removeAll()
        
        // for most combinators: change the current eval into an AND of the current eval and the eval
        switch combinator {
        case ">":
            currentEvaluator = CombiningEvaluator.And(newEvaluator!, StructuralEvaluator.ImmediateParent(currentEvaluator))
            break
        case " ":
            currentEvaluator = CombiningEvaluator.And(newEvaluator!, StructuralEvaluator.Parent(currentEvaluator))
            break
        case "+":
            currentEvaluator = CombiningEvaluator.And(newEvaluator!, StructuralEvaluator.ImmediatePreviousSibling(currentEvaluator))
            break
        case "~":
            currentEvaluator = CombiningEvaluator.And(newEvaluator!, StructuralEvaluator.PreviousSibling(currentEvaluator))
            break
        case ",": // group or
            var or: CombiningEvaluator.Or
            
            if let orEval = currentEvaluator as? CombiningEvaluator.Or {
                or = orEval
                or.add(newEvaluator!)
            } else {
                or = CombiningEvaluator.Or()
                or.add(currentEvaluator)
                or.add(newEvaluator!)
            }
            
            currentEvaluator = or
            break
        default:
            errors.append(SelectorParseException(message: "Unknown combinator: " + combinator))
        }
        
        if replaceRightMost {
            (rootEvaluator as? CombiningEvaluator.Or)?.rightMostEvaluator = currentEvaluator
        } else {
            rootEvaluator = currentEvaluator
        }
        
        evaluators.append(rootEvaluator)
    }
    
    private func consumeSubQuery() -> String {
        let accum = StringBuilder()
        
        while !tokenQueue.isEmpty {
            if tokenQueue.matches(text: "(") {
                accum += "(" + tokenQueue.chompBalanced(open: "(", close: ")") + ")"
            } else if tokenQueue.matches(text: "[") {
                accum += "[" + tokenQueue.chompBalanced(open: "[", close: "]") + "]"
            } else if tokenQueue.matches(any: QueryParser.combinators) {
                break
            } else {
                accum.append(tokenQueue.consume())
            }
        }
        
        return accum.stringValue
    }
    
    private func findElements() {
        do {
            if tokenQueue.matchAndChomp(text: "#") {
                byId()
            } else if tokenQueue.matchAndChomp(text: ".") {
                byClass()
            } else if tokenQueue.matchesWord() || tokenQueue.matches(text: "*|") {
                byTag()
            } else if tokenQueue.matches(text: "[") {
                try byAttribute()
            } else if tokenQueue.matchAndChomp(text: "*") {
                allElements()
            } else if tokenQueue.matchAndChomp(text: ":lt(") {
                indexLessThan()
            } else if tokenQueue.matchAndChomp(text: ":gt(") {
                indexGreaterThan()
            } else if tokenQueue.matchAndChomp(text: ":eq(") {
                indexEquals()
            } else if tokenQueue.matches(text: ":has(") {
                has()
            } else if tokenQueue.matches(text: ":contains(") {
                contains(own: false)
            } else if tokenQueue.matches(text: ":containsOwn(") {
                contains(own: true)
            } else if tokenQueue.matches(text: ":containsData(") {
                containsData()
            } else if tokenQueue.matches(text: ":matches(text: ") {
                matches(own: false)
            } else if tokenQueue.matches(text: ":matchesOwn(") {
                matches(own: true)
            } else if tokenQueue.matches(text: ":not(") {
                not()
            } else if tokenQueue.matchAndChomp(text: ":nth-child(") {
                try cssNthChild(backwards: false, ofType: false)
            } else if tokenQueue.matchAndChomp(text: ":nth-last-child(") {
                try cssNthChild(backwards: true, ofType: false)
            } else if tokenQueue.matchAndChomp(text: ":nth-of-type(") {
                try cssNthChild(backwards: false, ofType: true)
            } else if tokenQueue.matchAndChomp(text: ":nth-last-of-type(") {
                try cssNthChild(backwards: true, ofType: true)
            } else if tokenQueue.matchAndChomp(text: ":first-child") {
                evaluators.append(Evaluator.IsFirstChild())
            } else if tokenQueue.matchAndChomp(text: ":last-child") {
                evaluators.append(Evaluator.IsLastChild())
            } else if tokenQueue.matchAndChomp(text: ":first-of-type") {
                evaluators.append(Evaluator.IsFirstOfType())
            } else if tokenQueue.matchAndChomp(text: ":last-of-type") {
                evaluators.append(Evaluator.IsLastOfType())
            } else if tokenQueue.matchAndChomp(text: ":only-child") {
                evaluators.append(Evaluator.IsOnlyChild())
            } else if tokenQueue.matchAndChomp(text: ":only-of-type") {
                evaluators.append(Evaluator.IsOnlyOfType())
            } else if tokenQueue.matchAndChomp(text: ":empty") {
                evaluators.append(Evaluator.IsEmpty())
            } else if tokenQueue.matchAndChomp(text: ":root") {
                evaluators.append(Evaluator.IsRoot())
            } else { // unhandled
                throw SelectorParseException(message: "Could not parse query \(query): unexpected token at '\(tokenQueue.remainder())'")
            }
        } catch {
            if let localizedError = error as? LocalizedError {
                errors.append(localizedError)
            }
        }
    }
    
    private func byId() {
        let id = tokenQueue.consumeCSSIdentifier()
        evaluators.append(Evaluator.IdIs(id: id))
    }
    
    private func byClass() {
        let className = tokenQueue.consumeCSSIdentifier()
        evaluators.append(Evaluator.HasClass(className: className))
    }
    
    private func byTag() {
        var tagName = tokenQueue.consumeElementSelector()
        
        // namespaces: wildcard match equals(tagName) or ending in ":"+tagName
        if tagName.hasPrefix("*|") {
            evaluators.append(CombiningEvaluator.Or(
                Evaluator.TagIs(tagName: tagName.trimmingCharacters(in: .whitespaces).lowercased()),
                Evaluator.TagEndsWith(tagName: tagName.replacingOccurrences(of: "*|", with: ":").trimmingCharacters(in: .whitespaces).lowercased())
            ))
        } else {
            tagName = tagName.replacingOccurrences(of: "|", with: ":")
            evaluators.append(Evaluator.TagIs(tagName: tagName.trimmingCharacters(in: .whitespaces)))
        }
    }
    
    private func byAttribute() throws {
        let contentQueue = TokenQueue(query: tokenQueue.chompBalanced(open: "[", close: "]"))
        let key = contentQueue.consume(toAny: QueryParser.AttributeEvals)
        
        contentQueue.consumeWhitespace()
        
        if contentQueue.isEmpty {
            if key.hasPrefix("^") {
                evaluators.append(Evaluator.HasAttributeStartingWith(attrStart: key[1..<key.unicodeScalars.count]))
            } else {
                evaluators.append(Evaluator.HasAttribute(attrName: key))
            }
        } else {
            if contentQueue.matchAndChomp(text: "=") {
                evaluators.append(Evaluator.HasAttributeWithValue(key: key, value: contentQueue.remainder()))
            } else if contentQueue.matchAndChomp(text: "!=") {
                evaluators.append(Evaluator.HasAttributeWithValueNot(key: key, value: contentQueue.remainder()))
            } else if contentQueue.matchAndChomp(text: "^=") {
                evaluators.append(Evaluator.HasAttributeWithValueStartingWith(key: key, value: contentQueue.remainder()))
            } else if contentQueue.matchAndChomp(text: "$=") {
                evaluators.append(Evaluator.HasAttributeWithValueEndingWith(key: key, value: contentQueue.remainder()))
            } else if contentQueue.matchAndChomp(text: "*=") {
                evaluators.append(Evaluator.HasAttributeWithValueContaining(key: key, value: contentQueue.remainder()))
            } else if contentQueue.matchAndChomp(text: "~=") {
                evaluators.append(Evaluator.HasAttributeWithValueMatching(key: key, pattern: contentQueue.remainder()))
            } else {
                throw SelectorParseException(message: "Could not parse attribute query '\(query)': unexpected token at '\(contentQueue.remainder())'")
            }
        }
    }
    
    private func allElements() {
        evaluators.append(Evaluator.AllElements())
    }
    
    // pseudo selectors :lt, :gt, :eq
    private func indexLessThan() {
        evaluators.append(Evaluator.IndexLessThan(index: consumeIndex()))
    }
    
    private func indexGreaterThan() {
        evaluators.append(Evaluator.IndexGreaterThan(index: consumeIndex()))
    }
    
    private func indexEquals() {
        evaluators.append(Evaluator.IndexEquals(index: consumeIndex()))
    }
    
    //pseudo selectors :first-child, :last-child, :nth-child, ...
    private static let NTH_AB = try! NSRegularExpression(pattern: "((\\+|-)?(\\d+)?)n(\\s*(\\+|-)?\\s*\\d+)?", options: [.caseInsensitive])
    private static let NTH_B  = try! NSRegularExpression(pattern: "(\\+|-)?(\\d+)", options: [])
    
    private func cssNthChild(backwards: Bool, ofType: Bool) throws {
        let string = tokenQueue.chomp(to: ")").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let range = NSRange(location: 0, length: string.unicodeScalars.count)
        
        let matchAB = QueryParser.NTH_AB.matches(in: string, options: [], range: range)
        let matchB = QueryParser.NTH_B.matches(in: string, options: [], range: range)
        
        let a, b: Int
        
        if "odd" == string {
            a = 2
            b = 1
        } else if "even" == string {
            a = 2
            b = 0
        } else if !matchAB.isEmpty {
            a = !string[matchAB.first!.rangeAt(3)].isEmpty ? Int(string[matchAB.first!.rangeAt(1)].replaceFirst(regex: "^\\+", by: ""))! : 1
            b = !string[matchAB.first!.rangeAt(4)].isEmpty ? Int(string[matchAB.first!.rangeAt(4)].replaceFirst(regex: "^\\+", by: ""))! : 0
        } else if !matchB.isEmpty {
            a = 0
            b = Int(string[matchB.first!.range].replaceFirst(regex: "^\\+", by: ""))!
        } else {
            throw SelectorParseException(message: "Could not parse nth-index '\(string)': unexpected format")
        }
        
        if ofType {
            if backwards {
                evaluators.append(Evaluator.IsNthLastOfType(a: a, b: b))
            } else {
                evaluators.append(Evaluator.IsNthOfType(a: a, b: b))
            }
        } else {
            if backwards {
                evaluators.append(Evaluator.IsNthLastChild(a: a, b: b))
            } else {
                evaluators.append(Evaluator.IsNthChild(a: a, b: b))
            }
        }
    }
    
    private func consumeIndex() -> Int {
        let indexString = tokenQueue.chomp(to: ")").trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(indexString)!
    }
    
    // pseudo selector :has(el)
    private func has() {
        tokenQueue.consume(text: ":has")
        let subQuery = tokenQueue.chompBalanced(open: "(", close: ")")
        do {
            let evaluator = try QueryParser.parse(query: subQuery)
            evaluators.append(StructuralEvaluator.Has(evaluator))
        } catch {
            print(error)
            return
        }
    }
    
    // pseudo selector :contains(text), containsOwn(text)
    private func contains(own: Bool) {
        tokenQueue.consume(text: own ? ":containsOwn" : ":contains")
        let searchText = TokenQueue.unescape(tokenQueue.chompBalanced(open: "(", close: ")"))
        if own {
            evaluators.append(Evaluator.ContainsOwnText(searchOwnText: searchText))
        } else {
            evaluators.append(Evaluator.ContainsText(searchText: searchText))
        }
    }
    
    // pseudo selector :containsData(data)
    private func containsData() {
        tokenQueue.consume(text: ":containsData")
        let searchText = TokenQueue.unescape(tokenQueue.chompBalanced(open: "(", close: ")"))
        evaluators.append(Evaluator.ContainsData(searchData: searchText))
    }
    
    // :matches(regex), matchesOwn(regex)
    private func matches(own: Bool) {
        tokenQueue.consume(text: own ? ":matchesOwn" : ":matches")
        let pattern = tokenQueue.chompBalanced(open: "(", close: ")")
        if own {
            evaluators.append(Evaluator.MatchesOwnText(pattern: pattern))
        } else {
            evaluators.append(Evaluator.MatchesText(pattern: pattern))
        }
    }
    
    // :not(selector)
    private func not() {
        tokenQueue.consume(text: ":not")
        let subQuery = tokenQueue.chompBalanced(open: "(", close: ")")
        do {
            let evaluator = try QueryParser.parse(query: subQuery)
            evaluators.append(StructuralEvaluator.Not(evaluator))
        } catch {
            print(error)
            return
        }

    }
    
}

struct SelectorParseException: LocalizedError {
    
    let message: String
    
    var errorDescription: String? {
        return message
    }
}
