//
//  TreeBuilder.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class TreeBuilder {
    
    var characterReader: CharacterReader!
    var tokeniser: Tokeniser!
    var document: Document!
    var stack: [Element]!
    var baseUri: String?
    var currentToken: Token?
    var errors: ParseErrorList!
    var settings: ParseSettings!
    
    var start = Token.StartTag()
    var end = Token.EndTag()
    
    var defaultSettings: ParseSettings { fatalError("\(#function) in \(self.self) must be overriden") }
    
    func initializeParse(input: String, baseUri: String?, errors: ParseErrorList, settings: ParseSettings) {
        self.document = Document(baseUri: baseUri)
        self.settings = settings
        self.characterReader = CharacterReader(input: input)
        self.errors = errors
        self.tokeniser = Tokeniser(reader: self.characterReader, errors: errors)
        self.stack = []
        self.baseUri = baseUri
    }
    
    func parse(input: String, baseUri: String?, errors: ParseErrorList, settings: ParseSettings) -> Document {
        initializeParse(input: input, baseUri: baseUri, errors: errors, settings: settings)
        runParser()
        document.errors = errors
        return document
    }
    
    func runParser() {
        var token: Token
        repeat {
            token = tokeniser.read()
            process(token: token)
            token.reset()
        } while token.type != .EOF
    }

    @discardableResult
    func process(token: Token) -> Bool { fatalError("\(#function) in \(self.self) must be overriden") }

    @discardableResult
    func process(startTag name: String, attributes: Attributes? = nil) -> Bool {
        if currentToken != nil && currentToken! === start {
            if attributes != nil {
                return process(token: Token.StartTag().nameAttr(name: name, attributes: attributes!))
            } else {
                return process(token: build(Token.StartTag()) { $0.tagName = name })
            }
        }
        start.reset()
        if attributes != nil {
            start.nameAttr(name: name, attributes: attributes!)
        } else {
            start.tagName = name
        }
        return process(token: start)
    }

    @discardableResult
    func process(endTag name: String) -> Bool {
        if currentToken === end {
            return process(token: build(Token.EndTag()) { $0.tagName = name })
        }
        
        end.reset()
        end.tagName = name
        return process(token: end)
    }
    
    open var currentElement: Element? {
        return stack.last
    }
    
}
