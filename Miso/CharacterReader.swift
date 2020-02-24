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
    
    public static let hexadecimalCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        
    let rawInput: String
    
    public var input: String.UnicodeScalarView
    
    var pos: Int { return input.distance(from: input.startIndex, to: index) }
    var markIndex: String.UnicodeScalarView.Index
    var index: String.UnicodeScalarView.Index
    
    var overflow = 0
    public var count: Int {
        return input.count
    }
    
    public init(input: String) {
        self.rawInput = input
        self.input = input.unicodeScalars
        self.index = self.input.startIndex
        self.markIndex = self.index
    }
    
    public var isEmpty: Bool {
        return index == input.endIndex
    }
    
    public var current: UnicodeScalar { return index == input.endIndex ? CharacterReader.EOF : input[index] }
    
    @discardableResult
    func consume() -> UnicodeScalar {
        let val = current
        advance()
        return val
    }
    
    func unconsume() {
        guard overflow == 0 && index > input.startIndex else {
            if overflow > 0 { overflow -= 1 }
            return
        }
        index = input.index(before: index)
    }
    
    func advance() {
        guard index < input.endIndex else {
            overflow += 1
            return
        }
        index = input.index(after: index)
    }
    
    func mark() {
        markIndex = index
    }
    
    func rewindToMark() {
        index = markIndex
    }
    
    func consumeAsString() -> String {
        let start = index
        advance()
        return input[start].string
    }
    
    func nextIndex(ofCharacter char: UnicodeScalar) -> String.UnicodeScalarView.Index? {
        return input[index...].firstIndex(of: char)
    }
    
    private func rangeEquals(_ range: Range<String.UnicodeScalarView.Index>, scalar: String.UnicodeScalarView) -> Bool {
        let count = input.distance(from: range.lowerBound, to: range.upperBound)
        guard !scalar.isEmpty, count == scalar.count  else { return false }

        var indexA = range.lowerBound
        var indexB = scalar.startIndex
        for _ in 0..<count {
            if input[indexA] != scalar[indexB] {
              return false
            }
            indexA = input.index(after: indexA)
            indexB = scalar.index(after: indexB)
        }

        return true
    }
    
    func nextIndex(of character: UnicodeScalar) -> String.UnicodeScalarView.Index? {
        return input[index...].firstIndex(of: character)
    }
    
    func nextIndex(ofCharacters characters: String.UnicodeScalarView) -> String.UnicodeScalarView.Index? {
        guard count >= characters.count else { return nil }
        let upperLimit = input.index(input.endIndex, offsetBy: -characters.count)
        guard !isEmpty && !characters.isEmpty && upperLimit >= index else { return nil }
        
        var i = index
        while i <= upperLimit {
            let end = input.index(i, offsetBy: characters.count)
            if rangeEquals((i..<end), scalar: characters) {
                return i
            } else {
                i = input.index(after: i)
            }
        }
        return nil
    }
    
    func nextIndex(of string: String) -> String.UnicodeScalarView.Index? {
        let scalars = string.unicodeScalars
        
        return nextIndex(ofCharacters: scalars)
    }
    
    func consume(to char: UnicodeScalar) -> String {
        if let offset = nextIndex(ofCharacter: char) {
            let consumed = cacheString(range: index..<offset)
            index = offset
            return consumed
        }
        return consumeToEnd()
    }

    func consume(to string: String) -> String {
        if let offset = nextIndex(ofCharacters: string.unicodeScalars) {
            let consumed = cacheString(range: index..<offset)
            index = offset
            return consumed
        }
        return consumeToEnd()
    }
    
    func consume(toAny characters: [UnicodeScalar]) -> String {
        let start = index
        var i = index
        while i < input.endIndex {
            if characters.contains(input[i]) {
                index = i
                return cacheString(range: start..<i)
            }
            i = input.index(after: i)
        }
        return consumeToEnd()
    }
    
    func consume(toAnySorted characters: [UnicodeScalar]) -> String {
        let start = index
        var i = index
        while i < input.endIndex {
            if characters.binarySearch(value: input[i]) != nil {
                index = i
                return cacheString(range: start..<i)
            }
            i = input.index(after: i)
        }
        return consumeToEnd()
    }
    
    func consumeData() -> String {
        let start = index
        var i = index
        while i < input.endIndex {
            let c = input[i]
            if c == UnicodeScalar.Ampersand || c == UnicodeScalar.LessThan || c == TokeniserStateVars.nullScalar {
                index = i
                return cacheString(range: start..<i)
            }
            i = input.index(after: i)
        }
        
        return consumeToEnd()
    }
    
    func consumeRawData() -> String {
        let start = index
        var i = index
        while i < input.endIndex {
            let c = input[i]
            if c == UnicodeScalar.LessThan || c == TokeniserStateVars.nullScalar {
                index = i
                return cacheString(range: start..<i)
            }
            i = input.index(after: i)
        }
        
        return consumeToEnd()
    }
    
    func consumeTagName() -> String {
        let start = index
        var i = index
        while i < input.endIndex {
            let c = input[i]
            if CharacterReader.tagnameDelimiters.contains(c) {
                index = i
                return cacheString(range: start..<i)
            }
            i = input.index(after: i)
        }
        
        return CharacterReader.empty
    }
    
    func consumeToEnd() -> String {
        let start = index
        index = input.endIndex
        return cacheString(range: start..<index)
    }
    
    func consumeLetterSequence() -> String {
        let start = index
        while index < input.endIndex {
            if CharacterSet.letters.contains(input[index]) {
                advance()
            } else {
                break
            }
        }
        return cacheString(range: start..<index)
    }
    
    func consumeLetterThenDigitSequence() -> String {
        let start = index
        while index < input.endIndex {
            if CharacterSet.letters.contains(input[index]) {
                advance()
            } else {
                break
            }
        }
        
        while index < input.endIndex {
            if CharacterSet.decimalDigits.contains(input[index]) {
                advance()
            } else {
                break
            }
        }
        return cacheString(range: start..<index)
    }
    
    func consumeHexSequence() -> String {
        advance()
        let start = index
        
        while index < input.endIndex {
            if Self.hexadecimalCharacterSet.contains(input[index]) {
                advance()
            } else {
                break
            }
        }
        
        return cacheString(range: start..<index)
    }
    
    func consumeDigitSequence() -> String {
        let start = index
        
        while index < input.endIndex {
            if CharacterSet.decimalDigits.contains(input[index]) {
                advance()
            } else {
                break
            }
        }
        
        return cacheString(range: start..<index)
    }
    
    func matches(char: UnicodeScalar) -> Bool {
        return current == char
    }
    
    func matches(string: String) -> Bool {
        return matches(string)
    }
    
    func matchesIgnoreCase(string: String) -> Bool {
        return matches(string, ignoreCase: true)
    }
        
    func matches(any characters: [UnicodeScalar]) -> Bool {
        return characters.contains(current)
    }
    
    private func matches(_ sequence: String, ignoreCase: Bool = false, consume: Bool = false) -> Bool {
        guard count >= sequence.count, input.index(input.startIndex, offsetBy: sequence.count) <= input.endIndex else { return false }
        var current = index
        let scalars = sequence.unicodeScalars
        for scalar in scalars {
            guard current < input.endIndex else { return false }
            if ignoreCase {
                guard input[current].uppercased == scalar.uppercased else { return false }
            } else {
                guard input[current] == scalar else { return false }
            }
            current = input.index(after: current)
        }
        if consume {
            index = current
        }
        return true
    }
    
    func matchesLetter() -> Bool {
        guard !isEmpty else { return false }
        return CharacterSet.letters.contains(input[index])
    }
    
    func matchesDigit() -> Bool {
        guard !isEmpty else { return false }
        return CharacterSet.decimalDigits.contains(input[index])
    }
    
    func matchesConsume(sequence: String) -> Bool {
        if matches(string: sequence) {
            index = input.index(index, offsetBy: sequence.unicodeScalars.count)
            return true
        } else {
            return false
        }
    }
    
    func matchesConsumeIgnoreCase(sequence: String) -> Bool {
        return matches(sequence, ignoreCase: true, consume: true)
    }
    
    func containsIgnoreCase(sequence: String) -> Bool {
        let scalars = sequence.unicodeScalars
        let length = scalars.count
        guard count >= length, input.index(input.endIndex, offsetBy: -length) >= index else { return false }
        
        var i = index
        while i < input.endIndex {
            var indexA = i
            var indexB = scalars.startIndex
            var matches = true
            for _ in 0..<length {
                guard input[indexA].uppercased == scalars[indexB].uppercased else {
                    matches = false
                    break
                }
                indexA = input.index(after: indexA)
                indexB = scalars.index(after: indexB)
            }
            if matches { return true }
            i = input.index(after: i)
        }
        return false
    }
    
    public var description: String {
        return String(input[index...])
    }
   
    func cacheString(range: Range<String.UnicodeScalarView.Index>) -> String {
        return String(input[range])
    }
    
}

extension String.UnicodeScalarView {
    subscript(range: Range<Int>) -> Substring.UnicodeScalarView {
        let start = self.index(startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        
        return self[start..<end]
    }
    
    subscript(index: Int) -> UnicodeScalar {
        let scalarIndex = self.index(self.startIndex, offsetBy: index)
        return self[scalarIndex]
    }
}

extension UnicodeScalar {
    
    var uppercased: UnicodeScalar {
        return String(self).uppercased().unicodeScalars[0]
    }
    
}
