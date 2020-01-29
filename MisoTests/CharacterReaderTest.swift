//
//  CharacterReaderTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 24/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class CharacterReaderTest: XCTestCase {
    
    func testConsume() {
        let reader = CharacterReader(input: "one")
        XCTAssertEqual(0, reader.pos)
        XCTAssertEqual("o", reader.current)
        XCTAssertEqual("o", reader.consume())
        XCTAssertEqual(1, reader.pos)
        XCTAssertEqual("n", reader.current)
        XCTAssertEqual(1, reader.pos)
        XCTAssertEqual("n", reader.consume())
        XCTAssertEqual("e", reader.consume())
        
        XCTAssert(reader.isEmpty)
        XCTAssertEqual(CharacterReader.EOF, reader.consume())
        XCTAssert(reader.isEmpty)
        XCTAssertEqual(CharacterReader.EOF, reader.consume())
    }
    
    func testUnconsume() {
        let reader = CharacterReader(input: "one")
        XCTAssertEqual("o", reader.consume())
        XCTAssertEqual("n", reader.current)
        reader.unconsume()
        XCTAssertEqual("o", reader.current)
        
        XCTAssertEqual("o", reader.consume())
        XCTAssertEqual("n", reader.consume())
        XCTAssertEqual("e", reader.consume())
        
        XCTAssert(reader.isEmpty)
        reader.unconsume()
        XCTAssertFalse(reader.isEmpty)
        XCTAssertEqual("e", reader.current)
        XCTAssertEqual("e", reader.consume())
        XCTAssert(reader.isEmpty)
    }
    
    func testMark() {
        let reader = CharacterReader(input: "one")
        reader.consume()
        reader.mark()
        
        XCTAssertEqual("n", reader.consume())
        XCTAssertEqual("e", reader.consume())
        XCTAssert(reader.isEmpty)
        
        reader.rewindToMark()
        
        XCTAssertEqual("n", reader.consume())
    }
    
    func testConsumeToEnd() {
        let input = "one two three"
        let reader = CharacterReader(input: input)
        
        XCTAssertEqual(input, reader.consumeToEnd())
        XCTAssert(reader.isEmpty)
    }
    
    func testNextIndexOfChar() {
        let input = "blah blah"
        let reader = CharacterReader(input: input)
        
        XCTAssertEqual(nil, reader.nextIndex(ofCharacter: "x"))
        XCTAssertEqual(input.index(input.startIndex, offsetBy: 3), reader.nextIndex(ofCharacter: "h"))
        let pulled = reader.consume(to: "h")
        XCTAssertEqual("bla", pulled)
        reader.consume()
        
        XCTAssertEqual(input.index(reader.index, offsetBy: 2), reader.nextIndex(ofCharacter: "l"))
        XCTAssertEqual(" blah", reader.consumeToEnd())
        
        XCTAssertEqual(nil, reader.nextIndex(ofCharacter: "x"))
    }
    
    func testNextIndexOfString() {
        let input = "One Two something Two Three Four"
        let reader = CharacterReader(input: input)
        
        XCTAssertEqual(nil, reader.nextIndex(of: "Foo"))
        XCTAssertEqual(input.index(input.startIndex, offsetBy: 4), reader.nextIndex(of: "Two"))
        XCTAssertEqual("One Two ", reader.consume(to: "something"))
        XCTAssertEqual(input.index(reader.index, offsetBy: 10), reader.nextIndex(of: "Two"))
        XCTAssertEqual("something Two Three Four", reader.consumeToEnd())
        XCTAssertEqual(nil, reader.nextIndex(of: "Two"))
    }
    
    func testNextIndexOfUnmatched() {
        let reader = CharacterReader(input: "<[[one]]")
        XCTAssertEqual(nil, reader.nextIndex(of: "]]>"))
    }
    
    func testConsumeToChar() {
        let reader = CharacterReader(input: "One Two Three")
        
        let T = "T".unicodeScalars[0]
        
        XCTAssertEqual("One ", reader.consume(to: T))
        XCTAssertEqual("", reader.consume(to: T))
        XCTAssertEqual("T", reader.consume())
        XCTAssertEqual("wo ", reader.consume(to: T))
        XCTAssertEqual("T", reader.consume())
        XCTAssertEqual("hree", reader.consume(to: T))
    }
    
    func testConsumeToString() {
        let reader = CharacterReader(input: "One Two Two Four")
        XCTAssertEqual("One ", reader.consume(to: "Two"))
        XCTAssertEqual("T", reader.consume())
        XCTAssertEqual("wo ", reader.consume(to: "Two"))
        XCTAssertEqual("T", reader.consume())
        XCTAssertEqual("wo Four", reader.consume(to: "Qux"))
    }
    
    func testAdvance() {
        let reader = CharacterReader(input: "One Two Three")
        XCTAssertEqual("O", reader.consume())
        reader.advance()
        XCTAssertEqual("e", reader.consume())
    }
    
    func testConsumeToAny() {
        let reader = CharacterReader(input: "One &bar; qux")
        XCTAssertEqual("One ", reader.consume(toAny: ["&", ";"]))
        XCTAssert(reader.matches(char: "&"))
        XCTAssert(reader.matches(string: "&bar;"))
        XCTAssertEqual("&", reader.consume())
        XCTAssertEqual("bar", reader.consume(toAny: ["&", ";"]))
        XCTAssertEqual(";", reader.consume())
        XCTAssertEqual(" qux", reader.consume(toAny: ["&", ";"]))
    }
    
    func testConsumeLetterSequence() {
        let reader = CharacterReader(input: "One &bar; qux")
        XCTAssertEqual("One", reader.consumeLetterSequence())
        XCTAssertEqual(" &", reader.consume(to: "bar;"))
        XCTAssertEqual("bar", reader.consumeLetterSequence())
        XCTAssertEqual("; qux", reader.consumeToEnd())
    }
    
    func testConsumeLetterThenDigitSequence() {
        let reader = CharacterReader(input: "One12 Two &bar; qux")
        XCTAssertEqual("One12", reader.consumeLetterThenDigitSequence())
        XCTAssertEqual(" ", reader.consume())
        XCTAssertEqual("Two", reader.consumeLetterThenDigitSequence())
        XCTAssertEqual(" &bar; qux", reader.consumeToEnd())
    }
    
    func testMatches() {
        let reader = CharacterReader(input: "One Two Three")
        XCTAssert(reader.matches(string: "O"))
        XCTAssert(reader.matches(string: "One Two Three"))
        XCTAssert(reader.matches(string: "One"))
        XCTAssertFalse(reader.matches(string: "one"))
        XCTAssertEqual("O", reader.consume())
        XCTAssertFalse(reader.matches(string: "One"))
        XCTAssert(reader.matches(string: "ne Two Three"))
        XCTAssertFalse(reader.matches(string: "ne Two Three Four"))
        XCTAssertEqual("ne Two Three", reader.consumeToEnd())
        XCTAssertFalse(reader.matches(string: "ne"))
    }
    
    func testMatchesIgnoreCase() {
        let reader = CharacterReader(input: "One Two Three")
        XCTAssert(reader.matchesIgnoreCase(string: "O"))
        XCTAssert(reader.matchesIgnoreCase(string: "o"))
        XCTAssert(reader.matches(string: "O"))
        XCTAssertFalse(reader.matches(string: "o"))
        XCTAssert(reader.matchesIgnoreCase(string: "One Two Three"))
        XCTAssert(reader.matchesIgnoreCase(string: "ONE two THREE"))
        XCTAssert(reader.matchesIgnoreCase(string: "One"))
        XCTAssert(reader.matchesIgnoreCase(string: "one"))
        XCTAssertEqual("O", reader.consume())
        XCTAssertFalse(reader.matchesIgnoreCase(string: "One"))
        XCTAssert(reader.matchesIgnoreCase(string: "NE Two Three"))
        XCTAssertFalse(reader.matchesIgnoreCase(string: "ne two three four"))
        XCTAssertEqual("ne Two Three", reader.consumeToEnd())
        XCTAssertFalse(reader.matchesIgnoreCase(string: "ne"))
    }
    
    func testContainsIgnoreCase() {
        let reader = CharacterReader(input: "One TWO three")
        XCTAssert(reader.containsIgnoreCase(sequence: "two"))
        XCTAssert(reader.containsIgnoreCase(sequence: "three"))
        XCTAssert(reader.containsIgnoreCase(sequence: "one"))
    }
    
    func testMatchesAny() {
        let scan: [UnicodeScalar] = [" ", "\n", "\t"]
        let reader = CharacterReader(input: "One\nTwo\tThree")
        
        XCTAssertFalse(reader.matches(any: scan))
        XCTAssertEqual("One", reader.consume(toAny: scan))
        XCTAssert(reader.matches(any: scan))
        XCTAssertEqual("\n", reader.consume())
        XCTAssertFalse(reader.matches(any: scan))
    }
}
