//
//  XPathTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 17/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class XPathTest: XCTestCase {
    
    func testTag() {
        let document = Parser.xmlParser.parseInput(html: "<p><a href=\"http://test.com\">Link</a></p>", baseUri: nil)
        
        let p = document.xpath("p")
        let a = document.xpath("a") // Is not immediate child
        let div = document.xpath("div") // Not in xml
        
        XCTAssertEqual(1, p.count)
        XCTAssertEqual(0, a.count)
        XCTAssertEqual(0, div.count)
    }
    
    func testAny() {
        let document = Parser.xmlParser.parseInput(html: "<p></p><a href=\"http://test.com\">Link</a>", baseUri: nil)
        
        let any = document.xpath("*")
        XCTAssertEqual(2, any.count)
        
        let none = any[0].xpath("*")
        XCTAssertEqual(0, none.count)
        
        let onlyOne = any[1].xpath("*")
        XCTAssertEqual(1, onlyOne.count) // TextNode "Link"
    }
    
    func testChildAt() {
        let document = Parser.xmlParser.parseInput(html: "<p></p><a href=\"http://test.com\">Link</a>", baseUri: nil)
        
        let first = document.xpath("./[0]")
        XCTAssertEqual(1, first.count)
        XCTAssertEqual("p", first[0].nodeName)
        
        let last = document.xpath("./[-1]")
        XCTAssertEqual(1, last.count)
        XCTAssertEqual("a", last[0].nodeName)
    }
    
    func testAnyChildren() {
        let document = Parser.xmlParser.parseInput(html: "<p><a href=\"http://test.com\">Link</a></p>", baseUri: nil)
        
        let anyChildren = document.xpath("//")
        XCTAssertEqual(3, anyChildren.count)
        
        let anyChildrenOfA = document.xpath("p//")
        
        XCTAssertEqual(2, anyChildrenOfA.count)
        XCTAssertEqual("#text", anyChildrenOfA.last?.nodeName)
    }
    
    func testChildNavigation() {
        let document = Parser.xmlParser.parseInput(html: "<p><a href=\"http://test.com\">Link</a></p>", baseUri: nil)
        
        let p = document.xpath("p")
        XCTAssertEqual(1, p.count)
        XCTAssertEqual("p", p[0].nodeName)
    }
    
    func testParentNavigation() {
        let document = Parser.xmlParser.parseInput(html: "<p><a href=\"http://test.com\">Link</a></p>", baseUri: nil)
        
        let a = document.xpath("p/a/../a")
        XCTAssertEqual(1, a.count)
        XCTAssertEqual("a", a[0].nodeName)
    }
    
    func testParentOutOfDocument() {
        let document = Parser.xmlParser.parseInput(html: "<p><a href=\"http://test.com\">Link</a></p>", baseUri: nil)
        
        let p = document.xpath("../../../../p")
        XCTAssertEqual(0, p.count)
    }
    
    func testHasAttributeNamed() {
        let document = Parser.xmlParser.parseInput(html: "<p><a href=\"http://test.com\">Link</a></p>", baseUri: nil)
        
        let a = document.xpath("//a[@href]")
        XCTAssertEqual(1, a.count)
        
        let a2 = document.xpath("//a[@rel]")
        XCTAssertEqual(0, a2.count)
    }
    
    func testHasAttributeWithValueSingleQuote() {
        let document = Parser.xmlParser.parseInput(html: "<p><a href='http://test.com'>Link</a></p>", baseUri: nil)
        
        let aSingle = document.xpath("//a[@href='http://test.com']")
        XCTAssertEqual(1, aSingle.count)
        
        let aDouble = document.xpath("//a[@href=\"http://test.com\"]")
        XCTAssertEqual(1, aDouble.count)
        
        let aInvalidSingle = document.xpath("//a[@rel='no']")
        XCTAssertEqual(0, aInvalidSingle.count)
        
        let aInvalidDouble = document.xpath("//a[@rel=\"no\"]")
        XCTAssertEqual(0, aInvalidDouble.count)
    }
    
    func testHasAttributeWithValueDoubleQuote() {
        let document = Parser.xmlParser.parseInput(html: "<p><a href=\"http://test.com\">Link</a></p>", baseUri: nil)
        
        let aSingle = document.xpath("//a[@href='http://test.com']")
        XCTAssertEqual(1, aSingle.count)
        
        let aDouble = document.xpath("//a[@href=\"http://test.com\"]")
        XCTAssertEqual(1, aDouble.count)
        
        let aInvalidSingle = document.xpath("//a[@rel='no']")
        XCTAssertEqual(0, aInvalidSingle.count)
        
        let aInvalidDouble = document.xpath("//a[@rel=\"no\"]")
        XCTAssertEqual(0, aInvalidDouble.count)
    }
    
    func testHasChildrenNamed() {
        let document = Parser.xmlParser.parseInput(html: "<p><a href=\"http://test.com\">Link</a></p>", baseUri: nil)
        
        let p = document.xpath("p[a]")
        XCTAssertEqual(1, p.count)
        
        let p2 = document.xpath("p[p]")
        XCTAssertEqual(0, p2.count)
    }
    
    func testHasChildrenWithTextValueSingleQuote() {
        let document = Parser.xmlParser.parseInput(html: "<p><a href='http://test.com'>Link</a></p>", baseUri: nil)
        
        let pSingle = document.xpath("p[a='Link']")
        XCTAssertEqual(1, pSingle.count)
        
        let pDouble = document.xpath("p[a=\"Link\"]")
        XCTAssertEqual(1, pDouble.count)
        
        let pInvalidSingle = document.xpath("p[a='LINK']")
        XCTAssertEqual(0, pInvalidSingle.count)
        
        let pInvalidDouble = document.xpath("p[a=\"LINK\"]")
        XCTAssertEqual(0, pInvalidDouble.count)
    }
    
    func testHasChildrenWithTextValueDoubleQuote() {
        let document = Parser.xmlParser.parseInput(html: "<p><a href=\"http://test.com\">Link</a></p>", baseUri: nil)
        
        let pSingle = document.xpath("p[a='Link']")
        XCTAssertEqual(1, pSingle.count)
        
        let pDouble = document.xpath("p[a=\"Link\"]")
        XCTAssertEqual(1, pDouble.count)
        
        let pInvalidSingle = document.xpath("p[a='LINK']")
        XCTAssertEqual(0, pInvalidSingle.count)
        
        let pInvalidDouble = document.xpath("p[a=\"LINK\"]")
        XCTAssertEqual(0, pInvalidDouble.count)
    }
    
}
