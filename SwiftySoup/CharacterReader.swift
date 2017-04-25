//
//  CharacterReader.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public class CharacterReader: CustomStringConvertible {

    public static let empty = ""
    public static let EOF: UnicodeScalar = "\u{FFFF}"
    public static let tagnameDelimiters: [UnicodeScalar] = [UnicodeScalar.Tabulation, UnicodeScalar.NewLine,
                                                            UnicodeScalar.BackslashR, UnicodeScalar.BackslashF,
                                                            UnicodeScalar.Space, UnicodeScalar.Slash,
                                                            UnicodeScalar.GreaterThan, TokeniserStateVars.nullScalar]
    
    let maxCacheLength = 12
    
    let rawInput: String
    
    public let input: [UnicodeScalar]
    
    var pos = 0
    private var _mark = 0
    public var count: Int {
        return input.count
    }
    
    var stringCache = [String?](repeating: nil, count: 512)
    
    public init(input: String) {
        self.rawInput = input
        self.input = Array(input.unicodeScalars)
    }
    
    public var isEmpty: Bool {
        return pos >= count
    }
    
    public var current: UnicodeScalar { return pos >= count ? CharacterReader.EOF : input[pos] }
    
    @discardableResult
    func consume() -> UnicodeScalar {
        let val = current
        advance()
        return val
    }
    
    func unconsume() {
        pos -= 1
    }
    
    func advance() {
        pos += 1
    }
    
    func mark() {
        _mark = pos
    }
    
    func rewindToMark() {
        pos = _mark
    }
    
    func consumeAsString() -> String {
        let start = pos
        pos += 1
        return input[start].string
    }
    
    func nextIndex(ofCharacter char: UnicodeScalar) -> Int? {
        if let newPos = (pos..<count).first(where: { input[$0] == char }) {
            return newPos - pos
        }
        return nil
    }
    
    private func rangeEquals(_ range: CountableRange<Int>, scalar: String.UnicodeScalarView) -> Bool {
        guard !scalar.isEmpty else { return false }
                
        for i in range {
            if input[i] != scalar[i - range.lowerBound] {
              return false
            }
        }

        return true
    }
    
    func nextIndex(ofCharacters characters: String.UnicodeScalarView) -> Int? {
        guard !isEmpty && !characters.isEmpty && pos < (count - characters.count) else { return nil }
        
        for i in (pos..<(count - characters.count)) {
            if rangeEquals((i..<i+characters.count), scalar: characters) {
                return i - pos
            }
        }
        return nil
    }
    
    func nextIndex(of string: String) -> Int? {        
        let scalars = string.unicodeScalars
        
        return nextIndex(ofCharacters: scalars)
    }
    
    func consume(to char: UnicodeScalar) -> String {
        if let offset = nextIndex(ofCharacter: char) {
            let consumed = cacheString(start: pos, count: offset)
            pos += offset
            return consumed
        }
        return consumeToEnd()
    }

    func consume(to string: String) -> String {
        if let offset = nextIndex(ofCharacters: string.unicodeScalars) {
            let consumed = cacheString(start: pos, count: offset)
            pos += offset
            return consumed
        }
        return consumeToEnd()
    }
    
    func consume(toAny characters: [UnicodeScalar]) -> String {
        let start = pos
        if let index = (start..<count).first(where: { characters.contains(input[$0]) }), index >= pos {
            pos = index
            return cacheString(start: start, count: pos - start)
        } else {
            return consumeToEnd()
        }
    }
    
    func consumeData() -> String {
        let start = pos
        
        if let index = (start..<count).first(where: {
            let c = input[$0]
            return c == UnicodeScalar.Ampersand || c == UnicodeScalar.LessThan || c == TokeniserStateVars.nullScalar
        }), index > start {
            pos = index
            return cacheString(start: start, count: (pos - start))
        }
        
        return consumeToEnd()
    }
    
    func consumeTagName() -> String {
        let start = pos
        
        if let index = (start..<count).first(where: {
            let c = input[$0]
            return CharacterReader.tagnameDelimiters.contains(c)
        }), index > pos {
            pos = index
            return cacheString(start: start, count: pos - start)
        }
        
        return CharacterReader.empty
    }
    
    func consumeToEnd() -> String {
        let start = pos
        pos = count
        return cacheString(start: start, count: pos - start)
    }
    
    func consumeLetterSequence() -> String {
        let start = pos
        for i in (start..<count) {
            if CharacterSet.letters.contains(input[i]) {
                pos += 1
            } else {
                break
            }
        }
        return cacheString(start: start, count: pos-start)
    }
    
    func consumeLetterThenDigitSequence() -> String {
        let start = pos
        for i in (start..<count) {
            if CharacterSet.letters.contains(input[i]) {
                pos += 1
            } else {
                break
            }
        }
        
        let startDigit = pos
        for i in (startDigit..<count) {
            if CharacterSet.decimalDigits.contains(input[i]) {
                pos += 1
            } else {
                break
            }
        }
        return cacheString(start: start, count: pos-start)
    }
    
    func consumeHexSequence() -> String {
        let start = pos
        
        for i in (start..<count) {
            if hexadecimalCharacterSet.contains(input[i]) {
                pos += 1
            } else {
                break
            }
        }
        
        return cacheString(start: start, count: pos-start)
    }
    
    func consumeDigitSequence() -> String {
        let start = pos
        
        for i in (start..<count) {
            if CharacterSet.decimalDigits.contains(input[i]) {
                pos += 1
            } else {
                break
            }
        }
        
        return cacheString(start: start, count: pos-start)
    }
    
    func matches(char: UnicodeScalar) -> Bool {
        return current == char
    }
    
    func matches(string: String) -> Bool {
        let length = string.unicodeScalars.count
        
        guard (count - pos) >= length else { return false }
        
        return rangeEquals(pos..<(pos + length), scalar: string.unicodeScalars)
    }
    
    func matchesIgnoreCase(string: String) -> Bool {
        let length = string.unicodeScalars.count
        
        guard (count - pos) >= length else { return false }
        
        let lowercasedString = string.lowercased()
        let lowercasedInput = rawInput.lowercased()
        
        return String(lowercasedInput.unicodeScalars[pos..<(pos + length)]) == lowercasedString
    }
    
    func matches(any characters: [UnicodeScalar]) -> Bool {
        return characters.contains(current)
    }
    
    func matchesLetter() -> Bool {
        guard !isEmpty else { return false }
        return CharacterSet.letters.contains(input[pos])
    }
    
    func matchesDigit() -> Bool {
        guard !isEmpty else { return false }
        return CharacterSet.decimalDigits.contains(input[pos])
    }
    
    func matchesConsume(sequence: String) -> Bool {
        if matches(string: sequence) {
            pos += sequence.unicodeScalars.count
            return true
        } else {
            return false
        }
    }
    
    func matchesConsumeIgnoreCase(sequence: String) -> Bool {
        if matchesIgnoreCase(string: sequence) {
            pos += sequence.unicodeScalars.count
            return true
        } else {
            return false
        }
    }
    
    func containsIgnoreCase(sequence: String) -> Bool {
        return rawInput.lowercased().contains(sequence.lowercased())
    }
    
    public var description: String {
        return input[pos..<count].joined()
    }
    
    func cacheString(start: Int, count: Int) -> String {
        return input[start..<(start + count)].joined()
        
        /*if count > maxCacheLength {
            return String(input[start..<(start + count)])
        }
        
        var hash = 0
        var offset = start
        
        for _ in 0..<count {
            hash = (hash * 31) + Int(input[offset].value)
            offset += 1
        }
        
        let index = hash & (stringCache.count - 1)
        if let cached = stringCache[index], cached.unicodeScalars == input[start..<(start + count)] {
            return cached
        } else {
            let string = input[start..<(start + count)].joined()
            stringCache[index] = string
            return string
        }*/
    }
    
}

extension String.UnicodeScalarView {
    subscript(range: Range<Int>) -> String.UnicodeScalarView {
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        let result = self.prefix(upTo: end).suffix(range.count)
        
        return result
    }
    
    subscript(index: Int) -> UnicodeScalar {
        let scalarIndex = self.index(self.startIndex, offsetBy: index)
        return self[scalarIndex]
    }
}

extension String.CharacterView {
    subscript(range: Range<Int>) -> String.CharacterView {
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        return self.prefix(upTo: end).suffix(range.count)
    }
    
    subscript(index: Int) -> Character {
        return self.prefix(index+1).last!
    }
}

var hexadecimalCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
