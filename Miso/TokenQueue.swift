//
//  TokenQueue.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 12/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

open class TokenQueue {
    
    private static let zero = UnicodeScalar(0)!
    static let ESC: UnicodeScalar = "\\"
    
    private let queue = StringBuilder()
    private var pos = 0
    
    public init(query: String) {
        self.queue.append(query)
    }
    
    open var isEmpty: Bool {
        return remainingLength == 0
    }
    
    open var remainingLength: Int {
        return queue.count - pos
    }
    
    open func peek() -> UnicodeScalar {
        return isEmpty ? UnicodeScalar(0) : queue[pos]
    }
    
    open func add(first char: UnicodeScalar) {
        add(first: char.string)
    }
    
    open func add(first string: String) {
        queue.insert(pos, string)
        //pos = 0
    }
    
    open func matches(text: String) -> Bool {
        let end = pos + text.unicodeScalars.count
        guard queue.count >= end else { return false }
        
        return queue[pos..<end] == text
    }
    
    /**
     Tests if the next characters match any of the sequences. Case insensitive.
     @param seq list of strings to case insensitively check for
     @return true of any matched, false if none did
     */
    open func matches(any texts: [String]) -> Bool {
        for text in texts {
            if queue[pos..<queue.count].lowercased().hasPrefix(text.lowercased()) {
                return true
            }
        }
        return false
    }
    
    open func matches(any chars: [UnicodeScalar]) -> Bool {
        for char in chars {
            if queue[pos] == char {
                return true
            }
        }
        return false
    }
    
    open func matchesStartTag() -> Bool {
        // micro opt for matching "<x"
        return remainingLength > 1 && queue[pos] == "<" && queue[pos+1].isLetter
    }
    
    /**
     * Tests if the queue matches the sequence (as with match), and if they do, removes the matched string from the
     * queue.
     * @param seq String to search for, and if found, remove from queue.
     * @return true if found and removed, false if not found.
     */
    open func matchAndChomp(text: String) -> Bool {
        if matches(text: text) {
            pos += text.unicodeScalars.count
            return true
        }
        return false
    }
    
    open func matchesWhitespace() -> Bool {
        return !isEmpty && queue[pos].isWhitespace
    }
    
    open func matchesWord() -> Bool {
        return !isEmpty && queue[pos].isLetterOrDigit
    }
    
    open func advance() {
        if !isEmpty { pos += 1 }
    }
    
    @discardableResult
    open func consume() -> UnicodeScalar {
        let char = queue[pos]
        pos += 1
        return char
    }
    
    /**
     * Consumes the supplied sequence of the queue. If the queue does not start with the supplied sequence, will
     * throw an illegal state exception -- but you should be running match() against that condition.
     <p>
     Case insensitive.
     * @param seq sequence to remove from head of queue.
     */
    open func consume(text: String) {
        if !matches(text: text) {
            // TODO maybe throw?
            fatalError("Queue did not match expected sequence")
        }
        
        let count = text.unicodeScalars.count
        
        if count > remainingLength {
            // TODO maybe throw?
            fatalError("Queue not long enough to consume sequence")
        }
        
        pos += count
    }
    
    @discardableResult
    open func consume(to text: String, ignoreCase: Bool = false) -> String {
        let text = ignoreCase ? text.lowercased() : text
        let queue = ignoreCase ? self.queue.stringValue.lowercased() : self.queue.stringValue
        
        if let offset = queue.index(of: text, since: pos) {
            let consumed = queue[pos..<offset]
            pos += consumed.unicodeScalars.count
            return consumed
        } else {
            return remainder()
        }
    }
    
    @discardableResult
    open func consume(toAny strings: [String]) -> String {
        let start = pos
        while !isEmpty && !matches(any: strings) {
            pos += 1
        }
        return queue[start..<pos]
    }
    
    /**
     * Pulls a string off the queue (like consumeTo), and then pulls off the matched string (but does not return it).
     * <p>
     * If the queue runs out of characters before finding the seq, will return as much as it can (and queue will go
     * isEmpty() == true).
     * @param seq String to match up to, and not include in return, and to pull off queue. <b>Case sensitive.</b>
     * @return Data matched from queue.
     */
    @discardableResult
    open func chomp(to text: String, ignoreCase: Bool = false) -> String {
        let data = consume(to: text, ignoreCase: ignoreCase)
        _ = matchAndChomp(text: text)
        return data
    }
    
    /**
     * Pulls a balanced string off the queue. E.g. if queue is "(one (two) three) four", (,) will return "one (two) three",
     * and leave " four" on the queue. Unbalanced openers and closers can be quoted (with ' or ") or escaped (with \). Those escapes will be left
     * in the returned string, which is suitable for regexes (where we need to preserve the escape), but unsuitable for
     * contains text strings; use unescape for that.
     * @param open opener
     * @param close closer
     * @return data matched from the queue
     */
    @discardableResult
    open func chompBalanced(open: UnicodeScalar, close: UnicodeScalar) throws -> String {
        
        var start = -1
        var end = -1
        var depth = 0
        var last = TokenQueue.zero
        var inQuote = false
        
        repeat {
            if isEmpty { break }
            let char = consume()
            
            if last.value == 0 || last != TokenQueue.ESC {
                if (char == "\'" || char == "\"") && char != open {
                    inQuote = !inQuote
                }
                if inQuote {
                    continue
                }
                
                if char == open {
                    depth += 1
                    if start == -1 {
                        start = pos
                    }
                } else if char == close {
                    depth -= 1
                }
            }
            
            if depth > 0 && last.value != 0 {
                end = pos // don't include the outer match pair in the return
            }
            
            last = char
            
        } while (depth > 0)
            
        let out = end >= 0 ? queue[start..<end] : ""
        if depth > 0 {
            throw SelectorParseException(message: "Did not find balanced maker at " + out)
        }
        return out
    }
    
    public static func unescape(_ string: String) -> String {
        let accum = StringBuilder()
        var last = TokenQueue.zero
        
        for scalar in string.unicodeScalars {
            if scalar == TokenQueue.ESC {
                if last != TokenQueue.zero && last == TokenQueue.ESC {
                    accum += scalar.string
                }
            } else {
                accum += scalar.string
            }
            last = scalar
        }
        
        return accum.stringValue
    }
    
    @discardableResult
    open func consumeWhitespace() -> Bool {
        var found = false
        while self.matchesWhitespace() {
            found = true
            pos += 1
        }
        
        return found
    }
    
    @discardableResult
    open func consumeWord() -> String {
        let start = pos
        while !isEmpty && self.matchesWord() {
            pos += 1
        }
        
        return queue[start..<pos]
    }
    
    @discardableResult
    open func consumeTagName() -> String {
        let start = pos
        while !isEmpty && self.matchesWord() || matches(any: [":", "_", "-"]) {
            pos += 1
        }
        
        return queue[start..<pos]
    }
    
    @discardableResult
    open func consumeElementSelector() -> String {
        let start = pos
        while !isEmpty && self.matchesWord() || matches(any: ["*|", "|", "_", "-"]) {
            pos += 1
        }
        
        return queue[start..<pos]
    }
    
    /**
     Consume a CSS identifier (ID or class) off the queue (letter, digit, -, _)
     http://www.w3.org/TR/CSS2/syndata.html#value-def-identifier
     @return identifier
     */
    @discardableResult
    open func consumeCSSIdentifier() -> String {
        let start = pos
        while !isEmpty && self.matchesWord() || matches(any: ["_", "-"]) {
            pos += 1
        }
        
        return queue[start..<pos]
    }
    
    @discardableResult
    open func consumeAttributeKey() -> String {
        let start = pos
        while !self.isEmpty && self.matchesWord() || matches(any: [":", "_", "-"]) {
            pos += 1
        }
        
        return queue[start..<pos]
    }
    
    /**
     Consume and return whatever is left on the queue.
     @return remained of queue.
     */
    open func remainder() -> String {
        let remainder = queue[pos..<queue.count]
        pos = queue.count
        return remainder
    }
}
