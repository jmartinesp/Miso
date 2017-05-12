//
//  TagTests.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 25/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class TagTest: XCTestCase {
    
    func testIsCaseSensitive() {
        let P = Tag(tagName: "P")
        let p = Tag(tagName: "p")
        XCTAssertNotEqual(P, p)
    }
    
    func testCanBeInsensitive() {
        let P = Tag.valueOf(tagName: "P", settings: ParseSettings.htmlDefault)
        let p = Tag.valueOf(tagName: "p", settings: ParseSettings.htmlDefault)
        XCTAssertEqual(P, p)
    }
    
    func testTrims() {
        let p1 = Tag.valueOf(tagName: "p")
        let p2 = Tag.valueOf(tagName: "   p   ")
        XCTAssertEqual(p1, p2)
    }
    
    func testEquality() {
        let p1 = Tag.valueOf(tagName: "p")
        let p2 = Tag.valueOf(tagName: "p")
        XCTAssertEqual(p1, p2)
        XCTAssert(p1 === p2)
    }
    
    func testDivSemantics() {
        let div = Tag.valueOf(tagName: "div")
        
        XCTAssert(div.isBlock)
        XCTAssert(div.formatAsBlock)
    }
    
    func testPSemantics() {
        let p = Tag.valueOf(tagName: "p")
        
        XCTAssert(p.isBlock)
        XCTAssertFalse(p.formatAsBlock)
    }
    
    func testImgSemantics() {
        let img = Tag.valueOf(tagName: "img")
        
        XCTAssert(img.isInline)
        XCTAssert(img.isSelfClosing)
        XCTAssertFalse(img.isBlock)
    }
    
    func testDefaultSemantics() {
        let foo = Tag.valueOf(tagName: "FOO")
        let foo2 = Tag.valueOf(tagName: "FOO")
        
        XCTAssertEqual(foo, foo2)
        XCTAssert(foo.isInline)
        XCTAssert(foo.formatAsBlock)
    }
    
}
