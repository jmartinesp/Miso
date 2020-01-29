//
//  TokeniserState.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 12/10/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

protocol TokeniserStateProtocol {
    func read(_ t: Tokeniser, _ r: CharacterReader) throws
}

public class TokeniserStateVars {
    public static let nullScalar: UnicodeScalar = "\u{0000}"
    
    static let attributeSingleValueCharsSorted: [UnicodeScalar] = ["\'", UnicodeScalar.Ampersand, nullScalar].sorted()
    static let attributeDoubleValueCharsSorted = ["\"", UnicodeScalar.Ampersand, nullScalar].sorted()
    static let attributeNameCharsSorted = ["\t", "\n", "\r", UnicodeScalar.BackslashF, " ", "/", "=", ">", nullScalar, "\"", "'", UnicodeScalar.LessThan].sorted()
    static let attributeValueUnquoted = ["\t", "\n", "\r", UnicodeScalar.BackslashF, " ", UnicodeScalar.Ampersand, ">", nullScalar, "\"", "'", UnicodeScalar.LessThan, "=", "`"].sorted()
    
    static let replacementChar: UnicodeScalar = Tokeniser.REPLACEMENT_CHAR
    static let replacementStr: String = String(Tokeniser.REPLACEMENT_CHAR)
    static let eof: UnicodeScalar = CharacterReader.EOF
}

enum TokeniserState: TokeniserStateProtocol {
    case Data
    case CharacterReferenceInData
    case Rcdata
    case CharacterReferenceInRcdata
    case Rawtext
    case ScriptData
    case PLAINTEXT
    case TagOpen
    case EndTagOpen
    case TagName
    case RcdataLessthanSign
    case RCDATAEndTagOpen
    case RCDATAEndTagName
    case RawtextLessthanSign
    case RawtextEndTagOpen
    case RawtextEndTagName
    case ScriptDataLessthanSign
    case ScriptDataEndTagOpen
    case ScriptDataEndTagName
    case ScriptDataEscapeStart
    case ScriptDataEscapeStartDash
    case ScriptDataEscaped
    case ScriptDataEscapedDash
    case ScriptDataEscapedDashDash
    case ScriptDataEscapedLessthanSign
    case ScriptDataEscapedEndTagOpen
    case ScriptDataEscapedEndTagName
    case ScriptDataDoubleEscapeStart
    case ScriptDataDoubleEscaped
    case ScriptDataDoubleEscapedDash
    case ScriptDataDoubleEscapedDashDash
    case ScriptDataDoubleEscapedLessthanSign
    case ScriptDataDoubleEscapeEnd
    case BeforeAttributeName
    case AttributeName
    case AfterAttributeName
    case BeforeAttributeValue
    case AttributeValue_doubleQuoted
    case AttributeValue_singleQuoted
    case AttributeValue_unquoted
    case AfterAttributeValue_quoted
    case SelfClosingStartTag
    case BogusComment
    case MarkupDeclarationOpen
    case CommentStart
    case CommentStartDash
    case Comment
    case CommentEndDash
    case CommentEnd
    case CommentEndBang
    case Doctype
    case BeforeDoctypeName
    case DoctypeName
    case AfterDoctypeName
    case AfterDoctypePublicKeyword
    case BeforeDoctypePublicIdentifier
    case DoctypePublicIdentifier_doubleQuoted
    case DoctypePublicIdentifier_singleQuoted
    case AfterDoctypePublicIdentifier
    case BetweenDoctypePublicAndSystemIdentifiers
    case AfterDoctypeSystemKeyword
    case BeforeDoctypeSystemIdentifier
    case DoctypeSystemIdentifier_doubleQuoted
    case DoctypeSystemIdentifier_singleQuoted
    case AfterDoctypeSystemIdentifier
    case BogusDoctype
    case CdataSection
    
    internal func read(_ t: Tokeniser, _ r: CharacterReader) throws {
        switch self {
        case .Data:
            switch (r.current) {
            case UnicodeScalar.Ampersand:
                t.advanceTransition(newState: .CharacterReferenceInData)
                break
            case UnicodeScalar.LessThan:
                t.advanceTransition(newState: .TagOpen)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self) // NOT replacement character (oddly?)
                t.emit(r.consume())
                break
            case TokeniserStateVars.eof:
                t.emit(Token.EOF())
                break
            default:
                let data: String = r.consumeData()
                t.emit(data)
                break
            }
            break
        case .CharacterReferenceInData:
            try TokeniserState.readCharRef(t, .Data)
            break
        case .Rcdata:
            switch (r.current) {
            case UnicodeScalar.Ampersand:
                t.advanceTransition(newState: .CharacterReferenceInRcdata)
                break
            case UnicodeScalar.LessThan:
                t.advanceTransition(newState: .RcdataLessthanSign)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                r.advance()
                t.emit(TokeniserStateVars.replacementChar)
                break
            case TokeniserStateVars.eof:
                t.emit(Token.EOF())
                break
            default:
                let data = r.consume(toAny: [UnicodeScalar.Ampersand, UnicodeScalar.LessThan, TokeniserStateVars.nullScalar])
                t.emit(data)
                break
            }
            break
        case .CharacterReferenceInRcdata:
            try TokeniserState.readCharRef(t, .Rcdata)
            break
        case .Rawtext:
            try TokeniserState.readData(t, r, self, .RawtextLessthanSign)
            break
        case .ScriptData:
            try TokeniserState.readData(t, r, self, .ScriptDataLessthanSign)
            break
        case .PLAINTEXT:
            switch (r.current) {
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                r.advance()
                t.emit(TokeniserStateVars.replacementChar)
                break
            case TokeniserStateVars.eof:
                t.emit(Token.EOF())
                break
            default:
                let data = r.consume(to: TokeniserStateVars.nullScalar)
                t.emit(data)
                break
            }
            break
        case .TagOpen:
            // from < in data
            switch (r.current) {
            case "!":
                t.advanceTransition(newState: .MarkupDeclarationOpen)
                break
            case "/":
                t.advanceTransition(newState: .EndTagOpen)
                break
            case "?":
                t.advanceTransition(newState: .BogusComment)
                break
            default:
                if (r.matchesLetter()) {
                    _ = t.createTagPending(start: true)
                    t.transition(newState: .TagName)
                } else {
                    t.error(state: self)
                    t.emit(UnicodeScalar.LessThan) // char that got us here
                    t.transition(newState: .Data)
                }
                break
            }
            break
        case .EndTagOpen:
            if (r.isEmpty) {
                t.eofError(state: self)
                t.emit("</")
                t.transition(newState: .Data)
            } else if (r.matchesLetter()) {
                _ = t.createTagPending(start: false)
                t.transition(newState: .TagName)
            } else if (r.matches(char: ">")) {
                t.error(state: self)
                t.advanceTransition(newState: .Data)
            } else {
                t.error(state: self)
                t.advanceTransition(newState: .BogusComment)
            }
            break
        case .TagName:
            // from < or </ in data, will have start or end tag pending
            // previous TagOpen state did NOT consume, will have a letter char in current
            //String tagName = r.consumeToAnySorted(tagCharsSorted).toLowerCase()
            let tagName = r.consumeTagName()
            t.tagPending?.append(tagName: tagName)
            
            switch (r.consume()) {
            case "\t":
                t.transition(newState: .BeforeAttributeName)
                break
            case "\n":
                t.transition(newState: .BeforeAttributeName)
                break
            case "\r":
                t.transition(newState: .BeforeAttributeName)
                break
            case UnicodeScalar.BackslashF:
                t.transition(newState: .BeforeAttributeName)
                break
            case " ":
                t.transition(newState: .BeforeAttributeName)
                break
            case "/":
                t.transition(newState: .SelfClosingStartTag)
                break
            case ">":
                t.emitTagPending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.nullScalar: // replacement
                t.tagPending?.append(tagName: TokeniserStateVars.replacementStr)
                break
            case TokeniserStateVars.eof: // should emit pending tag?
                t.eofError(state: self)
                t.transition(newState: .Data)
            // no default, as covered with above consumeToAny
            default:
                break
            }
        case .RcdataLessthanSign:
            if (r.matches(char: "/")) {
                t.createTempBuffer()
                t.advanceTransition(newState: .RCDATAEndTagOpen)
            } else if (r.matchesLetter() && t.appropriateEndTagName != nil && !r.containsIgnoreCase(sequence: "</" + t.appropriateEndTagName!)) {
                // diverge from spec: got a start tag, but there's no appropriate end tag (</title>), so rather than
                // consuming to EOF break out here
                let pending = t.createTagPending(start: false)
                pending.tagName = t.appropriateEndTagName
                t.tagPending = pending
                t.emitTagPending()
                r.unconsume() // undo UnicodeScalar.LessThan
                t.transition(newState: .Data)
            } else {
                t.emit(UnicodeScalar.LessThan)
                t.transition(newState: .Rcdata)
            }
            break
        case .RCDATAEndTagOpen:
            if (r.matchesLetter()) {
                _ = t.createTagPending(start: false)
                t.tagPending?.append(tagName: r.current.string)
                t.dataBuffer += r.current.string
                t.advanceTransition(newState: .RCDATAEndTagName)
            } else {
                t.emit("</")
                t.transition(newState: .Rcdata)
            }
            break
        case .RCDATAEndTagName:
            if (r.matchesLetter()) {
                let name = r.consumeLetterSequence()
                t.tagPending?.append(tagName: name)
                t.dataBuffer.append(name)
                return
            }
            
            func anythingElse(_ t: Tokeniser, _ r: CharacterReader) {
                t.emit("</" + t.dataBuffer)
                r.unconsume()
                t.transition(newState: .Rcdata)
            }
            
            let c = r.consume()
            switch (c) {
            case "\t":
                if (t.isAppropriateEndTagToken) {
                    t.transition(newState: .BeforeAttributeName)
                } else {
                    anythingElse(t, r)
                }
                break
            case "\n":
                if (t.isAppropriateEndTagToken) {
                    t.transition(newState: .BeforeAttributeName)
                } else {
                    anythingElse(t, r)
                }
                break
            case "\r":
                if (t.isAppropriateEndTagToken) {
                    t.transition(newState: .BeforeAttributeName)
                } else {
                    anythingElse(t, r)
                }
                break
            case UnicodeScalar.BackslashF:
                if (t.isAppropriateEndTagToken) {
                    t.transition(newState: .BeforeAttributeName)
                } else {
                    anythingElse(t, r)
                }
                break
            case " ":
                if (t.isAppropriateEndTagToken) {
                    t.transition(newState: .BeforeAttributeName)
                } else {
                    anythingElse(t, r)
                }
                break
            case "/":
                if (t.isAppropriateEndTagToken) {
                    t.transition(newState: .SelfClosingStartTag)
                } else {
                    anythingElse(t, r)
                }
                break
            case ">":
                if (t.isAppropriateEndTagToken) {
                    t.emitTagPending()
                    t.transition(newState: .Data)
                } else {anythingElse(t, r)}
                break
            default:
                anythingElse(t, r)
                break
            }
            break
        case .RawtextLessthanSign:
            if (r.matches(char: "/")) {
                t.createTempBuffer()
                t.advanceTransition(newState: .RawtextEndTagOpen)
            } else {
                t.emit(UnicodeScalar.LessThan)
                t.transition(newState: .Rawtext)
            }
            break
        case .RawtextEndTagOpen:
            TokeniserState.readEndTag(t, r, .RawtextEndTagName, .Rawtext)
            break
        case .RawtextEndTagName:
            try TokeniserState.handleDataEndTag(t, r, .Rawtext)
            break
        case .ScriptDataLessthanSign:
            switch (r.consume()) {
            case "/":
                t.createTempBuffer()
                t.transition(newState: .ScriptDataEndTagOpen)
                break
            case "!":
                t.emit("<!")
                t.transition(newState: .ScriptDataEscapeStart)
                break
            default:
                t.emit(UnicodeScalar.LessThan)
                r.unconsume()
                t.transition(newState: .ScriptData)
            }
            break
        case .ScriptDataEndTagOpen:
            TokeniserState.readEndTag(t, r, .ScriptDataEndTagName, .ScriptData)
            break
        case .ScriptDataEndTagName:
            try TokeniserState.handleDataEndTag(t, r, .ScriptData)
            break
        case .ScriptDataEscapeStart:
            if (r.matches(char: "-")) {
                t.emit("-")
                t.advanceTransition(newState: .ScriptDataEscapeStartDash)
            } else {
                t.transition(newState: .ScriptData)
            }
            break
        case .ScriptDataEscapeStartDash:
            if (r.matches(char: "-")) {
                t.emit("-")
                t.advanceTransition(newState: .ScriptDataEscapedDashDash)
            } else {
                t.transition(newState: .ScriptData)
            }
            break
        case .ScriptDataEscaped:
            if (r.isEmpty) {
                t.eofError(state: self)
                t.transition(newState: .Data)
                return
            }
            
            switch (r.current) {
            case "-":
                t.emit("-")
                t.advanceTransition(newState: .ScriptDataEscapedDash)
                break
            case UnicodeScalar.LessThan:
                t.advanceTransition(newState: .ScriptDataEscapedLessthanSign)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                r.advance()
                t.emit(TokeniserStateVars.replacementChar)
                break
            default:
                let data = r.consume(toAny: ["-", UnicodeScalar.LessThan, TokeniserStateVars.nullScalar])
                t.emit(data)
            }
            break
        case .ScriptDataEscapedDash:
            if (r.isEmpty) {
                t.eofError(state: self)
                t.transition(newState: .Data)
                return
            }
            
            let c = r.consume()
            switch (c) {
            case "-":
                t.emit(c)
                t.transition(newState: .ScriptDataEscapedDashDash)
                break
            case UnicodeScalar.LessThan:
                t.transition(newState: .ScriptDataEscapedLessthanSign)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.emit(TokeniserStateVars.replacementChar)
                t.transition(newState: .ScriptDataEscaped)
                break
            default:
                t.emit(c)
                t.transition(newState: .ScriptDataEscaped)
            }
            break
        case .ScriptDataEscapedDashDash:
            if (r.isEmpty) {
                t.eofError(state: self)
                t.transition(newState: .Data)
                return
            }
            
            let c = r.consume()
            switch (c) {
            case "-":
                t.emit(c)
                break
            case UnicodeScalar.LessThan:
                t.transition(newState: .ScriptDataEscapedLessthanSign)
                break
            case ">":
                t.emit(c)
                t.transition(newState: .ScriptData)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.emit(TokeniserStateVars.replacementChar)
                t.transition(newState: .ScriptDataEscaped)
                break
            default:
                t.emit(c)
                t.transition(newState: .ScriptDataEscaped)
            }
            break
        case .ScriptDataEscapedLessthanSign:
            if (r.matchesLetter()) {
                t.createTempBuffer()
                t.dataBuffer.append(r.current)
                t.emit("<" + String(r.current))
                t.advanceTransition(newState: .ScriptDataDoubleEscapeStart)
            } else if (r.matches(char: "/")) {
                t.createTempBuffer()
                t.advanceTransition(newState: .ScriptDataEscapedEndTagOpen)
            } else {
                t.emit(UnicodeScalar.LessThan)
                t.transition(newState: .ScriptDataEscaped)
            }
            break
        case .ScriptDataEscapedEndTagOpen:
            if (r.matchesLetter()) {
                _ = t.createTagPending(start: false)
                t.tagPending?.append(tagName: r.current.string)
                t.dataBuffer.append(r.current)
                t.advanceTransition(newState: .ScriptDataEscapedEndTagName)
            } else {
                t.emit("</")
                t.transition(newState: .ScriptDataEscaped)
            }
            break
        case .ScriptDataEscapedEndTagName:
            try TokeniserState.handleDataEndTag(t, r, .ScriptDataEscaped)
            break
        case .ScriptDataDoubleEscapeStart:
            TokeniserState.handleDataDoubleEscapeTag(t, r, .ScriptDataDoubleEscaped, .ScriptDataEscaped)
            break
        case .ScriptDataDoubleEscaped:
            let c = r.current
            switch (c) {
            case "-":
                t.emit(c)
                t.advanceTransition(newState: .ScriptDataDoubleEscapedDash)
                break
            case UnicodeScalar.LessThan:
                t.emit(c)
                t.advanceTransition(newState: .ScriptDataDoubleEscapedLessthanSign)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                r.advance()
                t.emit(TokeniserStateVars.replacementChar)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.transition(newState: .Data)
                break
            default:
                let data = r.consume(toAny: ["-", UnicodeScalar.LessThan, TokeniserStateVars.nullScalar])
                t.emit(data)
            }
            break
        case .ScriptDataDoubleEscapedDash:
            let c = r.consume()
            switch (c) {
            case "-":
                t.emit(c)
                t.transition(newState: .ScriptDataDoubleEscapedDashDash)
                break
            case UnicodeScalar.LessThan:
                t.emit(c)
                t.transition(newState: .ScriptDataDoubleEscapedLessthanSign)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.emit(TokeniserStateVars.replacementChar)
                t.transition(newState: .ScriptDataDoubleEscaped)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.transition(newState: .Data)
                break
            default:
                t.emit(c)
                t.transition(newState: .ScriptDataDoubleEscaped)
            }
            break
        case .ScriptDataDoubleEscapedDashDash:
            let c = r.consume()
            switch (c) {
            case "-":
                t.emit(c)
                break
            case UnicodeScalar.LessThan:
                t.emit(c)
                t.transition(newState: .ScriptDataDoubleEscapedLessthanSign)
                break
            case ">":
                t.emit(c)
                t.transition(newState: .ScriptData)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.emit(TokeniserStateVars.replacementChar)
                t.transition(newState: .ScriptDataDoubleEscaped)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.transition(newState: .Data)
                break
            default:
                t.emit(c)
                t.transition(newState: .ScriptDataDoubleEscaped)
            }
            break
        case .ScriptDataDoubleEscapedLessthanSign:
            if (r.matches(char: "/")) {
                t.emit("/")
                t.createTempBuffer()
                t.advanceTransition(newState: .ScriptDataDoubleEscapeEnd)
            } else {
                t.transition(newState: .ScriptDataDoubleEscaped)
            }
            break
        case .ScriptDataDoubleEscapeEnd:
            TokeniserState.handleDataDoubleEscapeTag(t, r, .ScriptDataEscaped, .ScriptDataDoubleEscaped)
            break
        case .BeforeAttributeName:
            // from tagname <xxx
            let c = r.consume()
            switch (c) {
            case "\t":
                t.transition(newState: .SelfClosingStartTag)
                break
            case "\n":
                t.transition(newState: .SelfClosingStartTag)
                break
            case "\r":
                t.transition(newState: .SelfClosingStartTag)
                break
            case UnicodeScalar.BackslashF:
                t.transition(newState: .SelfClosingStartTag)
                break
            case " ":
            break // ignore whitespace
            case "/":
                t.transition(newState: .SelfClosingStartTag)
                break
            case ">":
                t.emitTagPending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.tagPending?.newAttribute()
                r.unconsume()
                t.transition(newState: .AttributeName)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.transition(newState: .Data)
                break
            case "\"":
                t.error(state: self)
                t.tagPending?.newAttribute()
                t.tagPending?.append(attributeName: c.string)
                t.transition(newState: .AttributeName)
                break
            case "'":
                t.error(state: self)
                t.tagPending?.newAttribute()
                t.tagPending?.append(attributeName: c.string)
                t.transition(newState: .AttributeName)
                break
            case UnicodeScalar.LessThan:
                t.error(state: self)
                t.tagPending?.newAttribute()
                t.tagPending?.append(attributeName: c.string)
                t.transition(newState: .AttributeName)
                break
            case "=":
                t.error(state: self)
                t.tagPending?.newAttribute()
                t.tagPending?.append(attributeName: c.string)
                t.transition(newState: .AttributeName)
                break
            default: // A-Z, anything else
                t.tagPending?.newAttribute()
                r.unconsume()
                t.transition(newState: .AttributeName)
            }
            break
        case .AttributeName:
            let name = r.consume(toAny: TokeniserStateVars.attributeNameCharsSorted)
            
            t.tagPending?.append(attributeName: name)
            
            let c = r.consume()
            switch (c) {
            case "\t":
                t.transition(newState: .AfterAttributeName)
                break
            case "\n":
                t.transition(newState: .AfterAttributeName)
                break
            case "\r":
                t.transition(newState: .AfterAttributeName)
                break
            case UnicodeScalar.BackslashF:
                t.transition(newState: .AfterAttributeName)
                break
            case " ":
                t.transition(newState: .AfterAttributeName)
                break
            case "/":
                t.transition(newState: .SelfClosingStartTag)
                break
            case "=":
                t.transition(newState: .BeforeAttributeValue)
                break
            case ">":
                t.emitTagPending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                r.advance()
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.transition(newState: .Data)
                break
            case "\"":
                t.error(state: self)
                t.tagPending?.append(attributeName: c.string)
            case "'":
                t.error(state: self)
                t.tagPending?.append(attributeName: c.string)
            case UnicodeScalar.LessThan:
                t.error(state: self)
                t.tagPending?.append(attributeName: c.string)
            // no default, as covered in consumeToAny
            default:
                break
            }
            break
        case .AfterAttributeName:
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                // ignore
                break
            case "/":
                t.transition(newState: .SelfClosingStartTag)
                break
            case "=":
                t.transition(newState: .BeforeAttributeValue)
                break
            case ">":
                t.emitTagPending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.tagPending?.append(attributeName: TokeniserStateVars.replacementChar.string)
                t.transition(newState: .AttributeName)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.transition(newState: .Data)
                break
            case "\"", "'", UnicodeScalar.LessThan:
                t.error(state: self)
                t.tagPending?.newAttribute()
                t.tagPending?.append(attributeName: c.string)
                t.transition(newState: .AttributeName)
                break
            default: // A-Z, anything else
                t.tagPending?.newAttribute()
                r.unconsume()
                t.transition(newState: .AttributeName)
            }
            break
        case .BeforeAttributeValue:
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                // ignore
                break
            case "\"":
                t.transition(newState: .AttributeValue_doubleQuoted)
                break
            case UnicodeScalar.Ampersand:
                r.unconsume()
                t.transition(newState: .AttributeValue_unquoted)
                break
            case "'":
                t.transition(newState: .AttributeValue_singleQuoted)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.tagPending?.append(attributeValue: TokeniserStateVars.replacementChar.string)
                t.transition(newState: .AttributeValue_unquoted)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.emitTagPending()
                t.transition(newState: .Data)
                break
            case ">":
                t.error(state: self)
                t.emitTagPending()
                t.transition(newState: .Data)
                break
            case UnicodeScalar.LessThan, "=", "`":
                t.error(state: self)
                t.tagPending?.append(attributeValue: c.string)
                t.transition(newState: .AttributeValue_unquoted)
                break
            default:
                r.unconsume()
                t.transition(newState: .AttributeValue_unquoted)
            }
            break
        case .AttributeValue_doubleQuoted:
            let value = r.consume(to: "\"")
            if (value.unicodeScalars.count > 0) {
                t.tagPending?.append(attributeValue: value)
            } else {
                t.tagPending?.hasEmptyAttributeValue = true
            }
            
            let c = r.consume()
            switch (c) {
            case "\"":
                t.transition(newState: .AfterAttributeValue_quoted)
                break
            case UnicodeScalar.Ampersand:
                
                let ref = t.consumeCharacterReference(additionalAllowedCharacter: "\"", inAttributes: true)
                if !ref.isEmpty {
                    t.tagPending?.append(attributeValue: String(ref))
                } else {
                    t.tagPending?.append(attributeValue: UnicodeScalar.Ampersand.string)
                }
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.tagPending?.append(attributeValue: TokeniserStateVars.replacementChar.string)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.transition(newState: .Data)
                break
            // no default, handled in consume to any above
            default:
                break
            }
            break
        case .AttributeValue_singleQuoted:
            let value = r.consume(toAny: TokeniserStateVars.attributeSingleValueCharsSorted)
            if (value.unicodeScalars.count > 0) {
                t.tagPending?.append(attributeValue: value)
            } else {
                t.tagPending?.hasEmptyAttributeValue = true
            }
            
            let c = r.consume()
            switch (c) {
            case "'":
                t.transition(newState: .AfterAttributeValue_quoted)
                break
            case UnicodeScalar.Ampersand:
                
                let ref = t.consumeCharacterReference(additionalAllowedCharacter: "'", inAttributes: true)
                if !ref.isEmpty {
                    t.tagPending?.append(attributeValue: String(ref))
                } else {
                    t.tagPending?.append(attributeValue: UnicodeScalar.Ampersand.string)
                }
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.tagPending?.append(attributeValue: TokeniserStateVars.replacementChar.string)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.transition(newState: .Data)
                break
            // no default, handled in consume to any above
            default:
                break
            }
            break
        case .AttributeValue_unquoted:
            let value = r.consume(toAny: TokeniserStateVars.attributeValueUnquoted)
            if (value.unicodeScalars.count > 0) {
                t.tagPending?.append(attributeValue: value)
            }
            
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                t.transition(newState: .BeforeAttributeName)
                break
            case UnicodeScalar.Ampersand:
                let ref = t.consumeCharacterReference(additionalAllowedCharacter: ">", inAttributes: true)
                if !ref.isEmpty {
                    t.tagPending?.append(attributeValue: String(ref))
                } else {
                    t.tagPending?.append(attributeValue: UnicodeScalar.Ampersand.string)
                }
                break
            case ">":
                t.emitTagPending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.tagPending?.append(attributeValue: TokeniserStateVars.replacementChar.string)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.transition(newState: .Data)
                break
            case "\"", "'", UnicodeScalar.LessThan, "=", "`":
                t.error(state: self)
                t.tagPending?.append(attributeValue: c.string)
                break
            // no default, handled in consume to any above
            default:
                break
            }
            break
        case .AfterAttributeValue_quoted:
            // CharacterReferenceInAttributeValue state handled inline
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                t.transition(newState: .BeforeAttributeName)
                break
            case "/":
                t.transition(newState: .SelfClosingStartTag)
                break
            case ">":
                t.emitTagPending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.transition(newState: .Data)
                break
            default:
                t.error(state: self)
                r.unconsume()
                t.transition(newState: .BeforeAttributeName)
            }
            break
        case .SelfClosingStartTag:
            let c = r.consume()
            switch (c) {
            case ">":
                t.tagPending?.selfClosing = true
                t.emitTagPending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.transition(newState: .Data)
                break
            default:
                t.error(state: self)
                r.unconsume()
                t.transition(newState: .BeforeAttributeName)
            }
            break
        case .BogusComment:
            // todo: handle bogus comment starting from eof. when does that trigger?
            // rewind to capture character that lead us here
            r.unconsume()
            let comment: Token.Comment = Token.Comment()
            comment.bogus = true
            comment.data.append(r.consume(to: ">"))
            // todo: replace nullChar with replaceChar
            t.emit(comment)
            t.advanceTransition(newState: .Data)
            break
        case .MarkupDeclarationOpen:
            if (r.matchesConsume(sequence: "--")) {
                t.createCommentPending()
                t.transition(newState: .CommentStart)
            } else if (r.matchesConsumeIgnoreCase(sequence: "DOCTYPE")) {
                t.transition(newState: .Doctype)
            } else if (r.matchesConsume(sequence: "[CDATA[")) {
                // todo: should actually check current namepspace, and only non-html allows cdata. until namespace
                // is implemented properly, keep handling as cdata
                //} else if (!t.currentNodeInHtmlNS() && r.matchesConsume(sequence: "[CDATA[")) {
                t.transition(newState: .CdataSection)
            } else {
                t.error(state: self)
                t.advanceTransition(newState: .BogusComment) // advance so self character gets in bogus comment data's rewind
            }
            break
        case .CommentStart:
            let c = r.consume()
            switch (c) {
            case "-":
                t.transition(newState: .CommentStartDash)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.commentPending.data.append(TokeniserStateVars.replacementChar)
                t.transition(newState: .Comment)
                break
            case ">":
                t.error(state: self)
                t.emitCommentPending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.emitCommentPending()
                t.transition(newState: .Data)
                break
            default:
                t.commentPending.data.append(c.string)
                t.transition(newState: .Comment)
            }
            break
        case .CommentStartDash:
            let c = r.consume()
            switch (c) {
            case "-":
                t.transition(newState: .CommentStartDash)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.commentPending.data.append(TokeniserStateVars.replacementChar)
                t.transition(newState: .Comment)
                break
            case ">":
                t.error(state: self)
                t.emitCommentPending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.emitCommentPending()
                t.transition(newState: .Data)
                break
            default:
                t.commentPending.data.append(c)
                t.transition(newState: .Comment)
            }
            break
        case .Comment:
            let c = r.current
            switch (c) {
            case "-":
                t.advanceTransition(newState: .CommentEndDash)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                r.advance()
                t.commentPending.data.append(TokeniserStateVars.replacementChar)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.emitCommentPending()
                t.transition(newState: .Data)
                break
            default:
                t.commentPending.data.append(r.consume(toAny: ["-", TokeniserStateVars.nullScalar]))
            }
            break
        case .CommentEndDash:
            let c = r.consume()
            switch (c) {
            case "-":
                t.transition(newState: .CommentEnd)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.commentPending.data += "-" + TokeniserStateVars.replacementChar.string
                t.transition(newState: .Comment)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.emitCommentPending()
                t.transition(newState: .Data)
                break
            default:
                t.commentPending.data += "-" + c.string
                t.transition(newState: .Comment)
            }
            break
        case .CommentEnd:
            let c = r.consume()
            switch (c) {
            case ">":
                t.emitCommentPending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.commentPending.data += "--" + TokeniserStateVars.replacementChar.string
                t.transition(newState: .Comment)
                break
            case "!":
                t.error(state: self)
                t.transition(newState: .CommentEndBang)
                break
            case "-":
                t.error(state: self)
                t.commentPending.data.append("-")
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.emitCommentPending()
                t.transition(newState: .Data)
                break
            default:
                t.error(state: self)
                t.commentPending.data += "--" + c.string
                t.transition(newState: .Comment)
            }
            break
        case .CommentEndBang:
            let c = r.consume()
            switch (c) {
            case "-":
                t.commentPending.data.append("--!")
                t.transition(newState: .CommentEndDash)
                break
            case ">":
                t.emitCommentPending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.commentPending.data += "--!" + TokeniserStateVars.replacementChar.string
                t.transition(newState: .Comment)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.emitCommentPending()
                t.transition(newState: .Data)
                break
            default:
                t.commentPending.data += "--!" + c.string
                t.transition(newState: .Comment)
            }
            break
        case .Doctype:
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                t.transition(newState: .BeforeDoctypeName)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
            // note: fall through to > case
            case ">": // catch invalid <!DOCTYPE>
                t.error(state: self)
                t.createDocTypePending()
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.error(state: self)
                t.transition(newState: .BeforeDoctypeName)
            }
            break
        case .BeforeDoctypeName:
            if (r.matchesLetter()) {
                t.createDocTypePending()
                t.transition(newState: .DoctypeName)
                return
            }
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
            break // ignore whitespace
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.createDocTypePending()
                t.doctypePending.name.append(TokeniserStateVars.replacementChar)
                t.transition(newState: .DoctypeName)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.createDocTypePending()
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.createDocTypePending()
                t.doctypePending.name.append(c)
                t.transition(newState: .DoctypeName)
            }
            break
        case .DoctypeName:
            if (r.matchesLetter()) {
                let name = r.consumeLetterSequence()
                t.doctypePending.name.append(name)
                return
            }
            let c = r.consume()
            switch (c) {
            case ">":
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                t.transition(newState: .AfterDoctypeName)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.doctypePending.name.append(TokeniserStateVars.replacementChar)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.doctypePending.name.append(c)
            }
            break
        case .AfterDoctypeName:
            if (r.isEmpty) {
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                return
            }
            if r.matches(any: ["\t", "\n", "\r", UnicodeScalar.BackslashF, " "]) {
                r.advance() // ignore whitespace
            } else if (r.matches(char: ">")) {
                t.emitDocTypePending()
                t.advanceTransition(newState: .Data)
            } else if (r.matchesConsumeIgnoreCase(sequence: DocumentType.PUBLIC_KEY)) {
                t.doctypePending.pubSysKey = DocumentType.PUBLIC_KEY
                t.transition(newState: .AfterDoctypePublicKeyword)
            } else if (r.matchesConsumeIgnoreCase(sequence: DocumentType.SYSTEM_KEY)) {
                t.doctypePending.pubSysKey = DocumentType.SYSTEM_KEY;
                t.transition(newState: .AfterDoctypeSystemKeyword)
            } else {
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.advanceTransition(newState: .BogusDoctype)
            }
            break
        case .AfterDoctypePublicKeyword:
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                t.transition(newState: .BeforeDoctypePublicIdentifier)
                break
            case "\"":
                t.error(state: self)
                // set public id to empty string
                t.transition(newState: .DoctypePublicIdentifier_doubleQuoted)
                break
            case "'":
                t.error(state: self)
                // set public id to empty string
                t.transition(newState: .DoctypePublicIdentifier_singleQuoted)
                break
            case ">":
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.transition(newState: .BogusDoctype)
            }
            break
        case .BeforeDoctypePublicIdentifier:
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                break
            case "\"":
                // set public id to empty string
                t.transition(newState: .DoctypePublicIdentifier_doubleQuoted)
                break
            case "'":
                // set public id to empty string
                t.transition(newState: .DoctypePublicIdentifier_singleQuoted)
                break
            case ">":
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.transition(newState: .BogusDoctype)
            }
            break
        case .DoctypePublicIdentifier_doubleQuoted:
            let c = r.consume()
            switch (c) {
            case "\"":
                t.transition(newState: .AfterDoctypePublicIdentifier)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.doctypePending.publicIdentifier.append(TokeniserStateVars.replacementChar)
                break
            case ">":
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.doctypePending.publicIdentifier.append(c)
            }
            break
        case .DoctypePublicIdentifier_singleQuoted:
            let c = r.consume()
            switch (c) {
            case "'":
                t.transition(newState: .AfterDoctypePublicIdentifier)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.doctypePending.publicIdentifier.append(TokeniserStateVars.replacementChar)
                break
            case ">":
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.doctypePending.publicIdentifier.append(c)
            }
            break
        case .AfterDoctypePublicIdentifier:
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                t.transition(newState: .BetweenDoctypePublicAndSystemIdentifiers)
                break
            case ">":
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case "\"":
                t.error(state: self)
                // system id empty
                t.transition(newState: .DoctypeSystemIdentifier_doubleQuoted)
                break
            case "'":
                t.error(state: self)
                // system id empty
                t.transition(newState: .DoctypeSystemIdentifier_singleQuoted)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.transition(newState: .BogusDoctype)
            }
            break
        case .BetweenDoctypePublicAndSystemIdentifiers:
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                break
            case ">":
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case "\"":
                t.error(state: self)
                // system id empty
                t.transition(newState: .DoctypeSystemIdentifier_doubleQuoted)
                break
            case "'":
                t.error(state: self)
                // system id empty
                t.transition(newState: .DoctypeSystemIdentifier_singleQuoted)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.transition(newState: .BogusDoctype)
            }
            break
        case .AfterDoctypeSystemKeyword:
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                t.transition(newState: .BeforeDoctypeSystemIdentifier)
                break
            case ">":
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case "\"":
                t.error(state: self)
                // system id empty
                t.transition(newState: .DoctypeSystemIdentifier_doubleQuoted)
                break
            case "'":
                t.error(state: self)
                // system id empty
                t.transition(newState: .DoctypeSystemIdentifier_singleQuoted)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
            }
            break
        case .BeforeDoctypeSystemIdentifier:
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                break
            case "\"":
                // set system id to empty string
                t.transition(newState: .DoctypeSystemIdentifier_doubleQuoted)
                break
            case "'":
                // set public id to empty string
                t.transition(newState: .DoctypeSystemIdentifier_singleQuoted)
                break
            case ">":
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.transition(newState: .BogusDoctype)
            }
            break
        case .DoctypeSystemIdentifier_doubleQuoted:
            let c = r.consume()
            switch (c) {
            case "\"":
                t.transition(newState: .AfterDoctypeSystemIdentifier)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.doctypePending.systemIdentifier.append(TokeniserStateVars.replacementChar)
                break
            case ">":
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.doctypePending.systemIdentifier.append(c)
            }
            break
        case .DoctypeSystemIdentifier_singleQuoted:
            let c = r.consume()
            switch (c) {
            case "'":
                t.transition(newState: .AfterDoctypeSystemIdentifier)
                break
            case TokeniserStateVars.nullScalar:
                t.error(state: self)
                t.doctypePending.systemIdentifier.append(TokeniserStateVars.replacementChar)
                break
            case ">":
                t.error(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.doctypePending.systemIdentifier.append(c)
            }
            break
        case .AfterDoctypeSystemIdentifier:
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                break
            case ">":
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.eofError(state: self)
                t.doctypePending.forceQuirks = true
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                t.error(state: self)
                t.transition(newState: .BogusDoctype)
                // NOT force quirks
            }
            break
        case .BogusDoctype:
            let c = r.consume()
            switch (c) {
            case ">":
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            case TokeniserStateVars.eof:
                t.emitDocTypePending()
                t.transition(newState: .Data)
                break
            default:
                // ignore char
                break
            }
            break
        case .CdataSection:
            let data = r.consume(to: "]]>")
            t.emit(data)
            _ = r.matchesConsume(sequence: "]]>")
            t.transition(newState: .Data)
            break
        }
    }
    
    /**
     * Handles RawtextEndTagName, ScriptDataEndTagName, and ScriptDataEscapedEndTagName. Same body impl, just
     * different else exit transitions.
     */
    private static func handleDataEndTag(_ t: Tokeniser, _ r: CharacterReader, _ elseTransition: TokeniserState)throws {
        if (r.matchesLetter()) {
            let name = r.consumeLetterSequence()
            t.tagPending?.append(tagName: name)
            t.dataBuffer.append(name)
            return
        }
        
        var needsExitTransition = false
        if (t.isAppropriateEndTagToken && !r.isEmpty) {
            let c = r.consume()
            switch (c) {
            case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ":
                t.transition(newState: BeforeAttributeName)
                break
            case "/":
                t.transition(newState: SelfClosingStartTag)
                break
            case ">":
                t.emitTagPending()
                t.transition(newState: Data)
                break
            default:
                t.dataBuffer.append(c)
                needsExitTransition = true
            }
        } else {
            needsExitTransition = true
        }
        
        if (needsExitTransition) {
            t.emit("</" + t.dataBuffer)
            t.transition(newState: elseTransition)
        }
    }
    
    private static func readData(_ t: Tokeniser, _ r: CharacterReader, _ current: TokeniserState, _ advance: TokeniserState)throws {
        switch (r.current) {
        case UnicodeScalar.LessThan:
            t.advanceTransition(newState: advance)
            break
        case TokeniserStateVars.nullScalar:
            t.error(state: current)
            r.advance()
            t.emit(TokeniserStateVars.replacementChar)
            break
        case TokeniserStateVars.eof:
            t.emit(Token.EOF())
            break
        default:
            let data = r.consume(toAny: [UnicodeScalar.LessThan, TokeniserStateVars.nullScalar])
            t.emit(data)
            break
        }
    }
    
    private static func readCharRef(_ t: Tokeniser, _ advance: TokeniserState)throws {
        let c = t.consumeCharacterReference(additionalAllowedCharacter: nil, inAttributes: false)
        if (c.isEmpty) {
            t.emit(UnicodeScalar.Ampersand)
        } else {
            t.emit(c)
        }
        t.transition(newState: advance)
    }
    
    private static func readEndTag(_ t: Tokeniser, _ r: CharacterReader, _ a: TokeniserState, _ b: TokeniserState) {
        if (r.matchesLetter()) {
            _ = t.createTagPending(start: false)
            t.transition(newState: a)
        } else {
            t.emit("</")
            t.transition(newState: b)
        }
    }
    
    private static func handleDataDoubleEscapeTag(_ t: Tokeniser, _ r: CharacterReader, _ primary: TokeniserState, _ fallback: TokeniserState) {
        if (r.matchesLetter()) {
            let name = r.consumeLetterSequence()
            t.dataBuffer.append(name)
            t.emit(name)
            return
        }
        
        let c = r.consume()
        switch (c) {
        case "\t", "\n", "\r", UnicodeScalar.BackslashF, " ", "/", ">":
            if (t.dataBuffer == "script") {
                t.transition(newState: primary)
            } else {
                t.transition(newState: fallback)
            }
            t.emit(c)
            break
        default:
            r.unconsume()
            t.transition(newState: fallback)
        }
    }
}
