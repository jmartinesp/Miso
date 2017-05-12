//
//  TokenQueueTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 27/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class TokenQueueTest: XCTestCase {
    
    func testChompBalanced() {
        let tokenQueue = TokenQueue(query: ":contains(one (two) three) four")
        let pre = tokenQueue.consume(to: "(")
        let guts = try! tokenQueue.chompBalanced(open: "(", close: ")")
        let remainder = tokenQueue.remainder()
        
        XCTAssertEqual(":contains", pre)
        XCTAssertEqual("one (two) three", guts)
        XCTAssertEqual(" four", remainder)
    }
    
    func testChompEscapedBalanced() {
        let tokenQueue = TokenQueue(query: ":contains(one (two) \\( \\) \\) three) four")
        let pre = tokenQueue.consume(to: "(")
        let guts = try! tokenQueue.chompBalanced(open: "(", close: ")")
        let remainder = tokenQueue.remainder()
        
        XCTAssertEqual(":contains", pre)
        XCTAssertEqual("one (two) \\( \\) \\) three", guts)
        XCTAssertEqual(" four", remainder)
    }
    
    func testChompBalancedMatchesAsMuchAsPossible() {
        let tokenQueue = TokenQueue(query: "unbalanced(something(or another)) else")
        tokenQueue.consume(to: "(")
        let match = try! tokenQueue.chompBalanced(open: "(", close: ")")
        XCTAssertEqual("something(or another)", match)
    }
    
    func testUnescape() {
        XCTAssertEqual("one ( ) \\", TokenQueue.unescape("one \\( \\) \\\\"))
    }
    
    func testChompToIgnoreCase() {
        var tokenQueue = TokenQueue(query: "<textarea>one < two </TEXTarea>")
        var data = tokenQueue.chomp(to: "</textarea", ignoreCase: true)
        XCTAssertEqual("<textarea>one < two ", data)
        
        tokenQueue = TokenQueue(query: "<textarea> one two < three </oops>")
        data = tokenQueue.chomp(to: "</textarea", ignoreCase: true)
        XCTAssertEqual("<textarea> one two < three </oops>", data)
    }
    
    func testAddFirst() {
        let tokenQueue = TokenQueue(query: "One Two")
        tokenQueue.consumeWord()
        tokenQueue.add(first: "Three")
        XCTAssertEqual("Three Two", tokenQueue.remainder())
    }
    
}
