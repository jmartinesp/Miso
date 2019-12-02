//
//  Tokeniser.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

final class Tokeniser {
    public static let REPLACEMENT_CHAR: UnicodeScalar = "\u{FFFD}"
    public static let NOT_CHAR_REFS: [UnicodeScalar] = ["\t", "\n", "\r", "\u{000C}", " ", "<", "&"]
    
    private let reader: CharacterReader // html input
    private let errors: ParseErrorList // errors found while tokenising
    
    private(set) var state = TokeniserState.Data // current tokenisation state
    private var emitPending: Token? // the token we are about to emit on next read
    private var isEmitPending: Bool = false
    
    private var charsString: String? = nil
    private var charsBuilder = ""
    var dataBuffer = ""
    
    var tagPending: Token.Tag?
    var startPending = Token.StartTag()
    var endPending = Token.EndTag()
    var charPending = Token.Character()
    var doctypePending = Token.DocType()
    var commentPending = Token.Comment()
    
    private var lastStartTag: String? // the last start tag emitted, to test appropriate end tag
    var selfClosingFlagAcknowledged = true
    
    init(reader: CharacterReader, errors: ParseErrorList) {
        self.reader = reader
        self.errors = errors
    }
    
    func read() -> Token {
        if !selfClosingFlagAcknowledged {
            error(message: "Self closing flag not acknowledged")
            selfClosingFlagAcknowledged = true
        }
        
        while !isEmitPending {
            do {
                try state.read(self, reader)
            } catch {
                self.error(message: "Could not parse token at state: \(state)")
            }
        }
        
        // if emit is pending, a non-character token was found: return any chars in buffer, and leave token for next read:
        if !charsBuilder.isEmpty {
            let copy = charsBuilder
            charsBuilder.removeAll()
            charsString = nil
            charPending.data = copy
            return charPending
        } else if charsString != nil {
            charPending.data = charsString
            charsString = nil
            return charPending
        } else {
            isEmitPending = false
            return emitPending!
        }
    }
    
    func emit(_ token: Token) {
        guard !isEmitPending else { error(message: "There is an unread token pending!"); return }
        
        emitPending = token
        isEmitPending = true
        
        if let startTag = token as? Token.StartTag {
            lastStartTag = startTag.tagName
            
            if startTag.selfClosing {
                selfClosingFlagAcknowledged = false
            }
        } else if let endTag = token as? Token.EndTag {
            if !endTag.attributes.isEmpty {
                error(message: "Attributes incorrectly present on end tag")
            }
        }
    }
    
    func emit(_ text: String) {
        // buffer strings up until last string token found, to emit only one token for a run of character refs etc.
        // does not set isEmitPending; read checks that
        
        if charsString == nil {
            charsString = text
        } else {
            if charsBuilder.isEmpty { // switching to string builder as more than one emit before read
                charsBuilder.append(charsString!)
            }
            charsBuilder.append(text)
        }
    }
    
    func emit(_ chars: [UnicodeScalar]) {
        emit(String(String.UnicodeScalarView(chars)))
    }
    
    func emit(_ char: UnicodeScalar) {
        emit(char.string)
    }
    
    func transition(newState: TokeniserState) {
        self.state = newState
    }
    
    func advanceTransition(newState: TokeniserState) {
        reader.advance()
        self.state = newState
    }
    
    var codePointHolder: [UnicodeScalar] = [UnicodeScalar(0)!]
    var multipointHolder = [UnicodeScalar(0)!, UnicodeScalar(0)!]
    func consumeCharacterReference(additionalAllowedCharacter: UnicodeScalar?, inAttributes: Bool) -> [UnicodeScalar] {
        guard !reader.isEmpty,
            !(additionalAllowedCharacter != nil && additionalAllowedCharacter == reader.current),
            !reader.matches(any: Tokeniser.NOT_CHAR_REFS)
            else { return [] }
        
        var codeRef = codePointHolder
        reader.mark()
        
        if reader.matchesConsume(sequence: "#") {  // numbered
            let hexScalars = [UnicodeScalar("X"), UnicodeScalar("x")]
            let isHexMode = hexScalars.contains(reader.current)
            
            let numRef = isHexMode ? reader.consumeHexSequence() : reader.consumeDigitSequence()
            
            if numRef.isEmpty {
                characterReferenceError(message: "numeric reference with no numerals")
                reader.rewindToMark()
                return []
            }
            
            if !reader.matchesConsume(sequence: ";") {
                characterReferenceError(message: "missing semicolon")
            }
            
            var charval = -1
            let base = isHexMode ? 16 : 10
            charval = Int(numRef, radix: base)!
            
            if charval == -1 || (charval >= 0xD800 && charval <= 0xDFFF) || charval > 0x10FFFF {
                characterReferenceError(message: "character outside of valid range")
                codeRef[0] = Tokeniser.REPLACEMENT_CHAR
                return codeRef
            } else {
                // todo: implement number replacement table
                // todo: check for extra illegal unicode points as parse errors
                codeRef[0] = UnicodeScalar(charval)!
                return codeRef
            }
            
        } else { // named
            // get as many letters as possible, and look for matching entities
            let nameRef = reader.consumeLetterThenDigitSequence()
            let looksLegit = reader.matches(char: ";")
            // found if a base named entity without a ;, or an extended entity with the ;.
            let found = Entities.isBaseNamedEntity(nameRef) || (Entities.isNamedEntity(nameRef) && looksLegit)
            
            if !found {
                reader.rewindToMark()
                if looksLegit { // named with semicolon
                    characterReferenceError(message: "invalid named reference '\(nameRef)'")
                }
                return []
            }
            
            if inAttributes && (reader.matchesLetter() || reader.matchesDigit() || reader.matches(any: ["=", "-", "_"])) {
                // don't want that to match
                reader.rewindToMark()
                return []
            }
            
            if !reader.matchesConsume(sequence: ";") {
                characterReferenceError(message: "missing semicolon")
            }
            
            let numChars = Entities.codepoints(forName: nameRef, codepoints: &multipointHolder)
            if numChars == 1 {
                codeRef[0] = multipointHolder[0]
                return codeRef
            } else if numChars == 2 {
                return Array(multipointHolder)
            } else {
                characterReferenceError(message: "Unexpected characters returned for " + nameRef)
                return []
            }
        }
    }
    
    func createTagPending(start: Bool) -> Token.Tag {
        tagPending = start ? startPending.reset() as! Token.Tag : endPending.reset() as! Token.Tag
        return tagPending!
    }
    
    func emitTagPending() {
        if tagPending != nil {
            tagPending!.finalizeTag()
            emit(tagPending!)
        }
    }
    
    func createCommentPending() {
        commentPending.reset()
    }
    
    func emitCommentPending() {
        emit(commentPending)
    }
    
    func createDocTypePending() {
        doctypePending.reset()
    }
    
    func emitDocTypePending() {
        emit(doctypePending)
    }
    
    func createTempBuffer() {
        dataBuffer.removeAll()
    }
    
    var isAppropriateEndTagToken: Bool {
        return lastStartTag != nil && tagPending?.tagName?.lowercased() == lastStartTag?.lowercased()
    }
    
    var appropriateEndTagName: String? {
        return lastStartTag
    }
    
    var currentNodeInHtmlNS: Bool {
        // todo: implement namespaces correctly
        return true
        // Element currentNode = currentNode();
        // return currentNode != null && currentNode.namespace().equals("HTML");
    }
    
    /**
     * Utility method to consume reader and unescape entities found within.
     * @param inAttribute
     * @return unescaped string from reader
     */
    func unescapeEntities(inAttributes: Bool) -> String {
        let accum = StringBuilder()
        
        while !reader.isEmpty {
            accum += reader.consume(to: "&")
            if reader.matches(char: "&") {
                reader.consume()
                
                let scalars = consumeCharacterReference(additionalAllowedCharacter: nil, inAttributes: inAttributes)
                if scalars.isEmpty {
                    accum += "&"
                } else {
                    for s in scalars {
                        accum += s.string
                    }
                }
            }
        }
        
        return accum.stringValue
    }
    
    func error(state: TokeniserState) {
        if errors.canAddError {
            errors.append(ParseError(pos: reader.pos, message: "Unexpected character '\(reader.current.string)' in input state [\(state)]"))
        }
    }
    
    func eofError(state: TokeniserState) {
        if (errors.canAddError) {
            errors.append(ParseError(pos: reader.pos, message: "Unexpectedly reached end of file (EOF) in input state [\(state)]"))
        }
    }
    
    private func characterReferenceError(message: String) {
        if errors.canAddError {
            errors.append(ParseError(pos: reader.pos, message: "Invalid character reference: \(message)"))
        }
    }
    
    private func error(message: String) {
        if errors.canAddError {
            errors.append(ParseError(pos: reader.pos, message: message))
        }
    }
    
}
