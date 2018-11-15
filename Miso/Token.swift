//
//  Token.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class Token: CustomStringConvertible {
    
    var type: TokenType { fatalError("\(#function) in \(self.self) must be overriden") }
    
    @discardableResult
    func reset() -> Token { fatalError("\(#function) in \(self.self) must be overriden") }
    
    open var description: String { return type.description }
    
    final class DocType: Token {
        
        var name: String = ""
        override var type: TokenType { return .Doctype }
        var pubSysKey: String? = nil
        var publicIdentifier: String = ""
        var systemIdentifier: String = ""
        var forceQuirks = false
        
        @discardableResult
        override func reset() -> Token {
            name = ""
            pubSysKey = nil
            publicIdentifier = ""
            systemIdentifier = ""
            forceQuirks = false
            return self
        }
        
        override var description: String {
            return name
        }
    }

    class Tag: Token {
        
        var tagName: String? {
            didSet {
                normalizedName = tagName?.lowercased()
            }
        }
        private(set) var normalizedName: String?
        var pendingAttributeName: String?
        var pendingAttributeValue: String?
        var hasEmptyAttributeValue = false
        var hasPendingAttributeValue = false
        var selfClosing = false
        var attributes = Attributes()
        
        override var type: TokenType { fatalError() }
        
        @discardableResult
        override func reset() -> Token {
            tagName = nil
            normalizedName = nil
            pendingAttributeName = nil
            pendingAttributeValue = nil
            hasEmptyAttributeValue = false
            hasPendingAttributeValue = false
            selfClosing = false
            attributes = Attributes()
            return self
        }
        
        func newAttribute() {
            if let trimmedName = self.pendingAttributeName?.trimmingCharacters(in: .whitespacesAndNewlines) {
                self.pendingAttributeName = trimmedName
                
                if !trimmedName.isEmpty {
                    let attribute: Attribute
                    
                    if hasPendingAttributeValue {
                        attribute = Attribute(tag: trimmedName, value: pendingAttributeValue!.trimmingCharacters(in: .whitespaces))
                    } else if hasEmptyAttributeValue {
                        attribute = Attribute(tag: trimmedName, value: "")
                    } else {
                        attribute = BooleanAttribute(tag: trimmedName)
                    }
                    
                    attributes[trimmedName] = attribute
                }
                
                pendingAttributeName = nil
                pendingAttributeValue = nil
                hasPendingAttributeValue = false
                hasEmptyAttributeValue = false
            }
        }
        
        func finalizeTag() {
            if pendingAttributeName != nil {
                newAttribute()
            }
        }
        
        func append(tagName: String) {
            self.tagName = self.tagName != nil ? self.tagName! + tagName : tagName
        }
        
        func append(attributeName: String) {
            pendingAttributeName = pendingAttributeName != nil ? pendingAttributeName! + attributeName : attributeName
        }
        
        func append(attributeValue: String) {
            hasPendingAttributeValue = true
            pendingAttributeValue = pendingAttributeValue != nil ? pendingAttributeValue! + attributeValue : attributeValue
        }
        
        override var description: String {
            return tagName ?? ""
        }
    }

    final class StartTag: Tag {
        
        override var type: TokenType { return .StartTag }
        
        override init() {
            super.init()
            
            attributes = Attributes()
        }
        
        @discardableResult
        override func reset() -> Token {
            super.reset()
            
            attributes = Attributes()
            
            return self
        }
        
        @discardableResult
        func nameAttr(name: String, attributes: Attributes) -> StartTag {
            self.tagName = name
            self.attributes = attributes
            return self
        }
        
        override var description: String {
            if attributes.isEmpty {
                return "<\(tagName ?? "null")>"
            } else {
                return "<\(tagName ?? "null") \(attributes.html)>"
            }
        }
    }

    final class EndTag: Tag {
        
        override var type: TokenType { return .EndTag }
        
        override var description: String {
            return "</\(tagName ?? "null")>"
        }
    }

    final class Comment: Token {
        var data = ""
        var bogus = false
        
        override var type: TokenType { return .Comment }
        
        @discardableResult
        override func reset() -> Token {
            self.data = ""
            self.bogus = false
            
            return self
        }
        
        override var description: String {
            return "<!-- \(data) -->"
        }
    }

    final class Character: Token {
        
        var data: String?
        
        override var type: TokenType { return .Character }
        
        @discardableResult
        override func reset() -> Token {
            data = nil
            return self
        }
        
        override var description: String {
            return data ?? "null"
        }
    }

    final class EOF: Token {
        
        override var type: TokenType { return .EOF }
        
        @discardableResult
        override func reset() -> Token {
            return self
        }
        
        override var description: String {
            return ""
        }
    }
}

extension Token {
    
    var isDocType: Bool { return type == .Doctype }
    var isStartTag: Bool { return type == .StartTag }
    var isEndTag: Bool { return type == .EndTag }
    var isComment: Bool { return type == .Comment }
    var isCharacter: Bool { return type == .Character }
    var isEOF: Bool { return type == .EOF }
    
}

enum TokenType: String, CustomStringConvertible {
    case Doctype, StartTag, EndTag, Comment, Character, EOF
    
    var description: String {
        switch self {
        case .Doctype:
            return "Doctype"
        case .StartTag:
            return "StartTag"
        case .EndTag:
            return "EndTag"
        case .Comment:
            return "Comment"
        case .Character:
            return "Character"
        case .EOF:
            return "EOF"
        }
    }
}
