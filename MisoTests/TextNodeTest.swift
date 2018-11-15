//
//  TextNodeTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 24/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class TextNodeTest: XCTestCase {
    
    func testBlank() {
        let one = TextNode(text: "", baseUri: nil)
        let two = TextNode(text: "     ", baseUri: nil)
        let three = TextNode(text: "   \n\n ", baseUri: nil)
        let four = TextNode(text: "Hello", baseUri: nil)
        let five = TextNode(text: "  \nHello ", baseUri: nil)
        
        XCTAssert(one.isBlank)
        XCTAssert(two.isBlank)
        XCTAssert(three.isBlank)
        XCTAssertFalse(four.isBlank)
        XCTAssertFalse(five.isBlank)
    }
    
    func testTextBean() {
        let doc = Miso.parse(html: "<p>One <span>two &</span> three &</p>")
        let p = doc.select("p")[0]
        
        let span = p.select("span")[0]
        XCTAssertEqual("two &", span.text)
        
        let spanText = span.childNodes.first as? TextNode
        XCTAssertEqual("two &", spanText?.text)
        
        let textNode = p.childNodes[2] as? TextNode
        XCTAssertEqual(" three &", textNode?.text)
        
        textNode?.text(replaceWith: " POW!")
        XCTAssertEqual("One <span>two &amp;</span> POW!", p.html.strippedNewLines)
        
        textNode?.attr("text", setValue: "kablam &")
        XCTAssertEqual("kablam &", textNode?.text)
        XCTAssertEqual("One <span>two &amp;</span>kablam &amp;", p.html.strippedNewLines)
    }
    
    func testSplitText() {
        let doc = Miso.parse(html: "<div>Hello there</div>")
        let div = doc.select("div").first
        let textNode = div?.childNodes.first as? TextNode
        let tail = textNode?.splitText(atOffset: 6)
        XCTAssertEqual("Hello ", textNode?.wholeText)
        XCTAssertEqual("there", tail?.wholeText)
        tail?.text(replaceWith: "there!")
        XCTAssertEqual("Hello there!", div?.text)
        XCTAssertEqual(textNode?.parentNode, tail?.parentNode)
    }
    
    func testSplitAndEmbolden() {
        let doc = Miso.parse(html: "<div>Hello there</div>")
        let div = doc.select("div").first
        let textNode = div?.childNodes.first as? TextNode
        let tail = textNode?.splitText(atOffset: 6)
        tail?.wrap(html: "<b></b>")
        
        XCTAssertEqual("Hello <b>there</b>", div?.html.strippedNewLines) // not great that we get \n<b>there there... must correct
    }
    
    func testWithSupplementaryCharacter() {
        let text = UnicodeScalar(135361)!.string
        let doc = Miso.parse(html: text)
        let textNode = doc.body?.textNodes.first
        XCTAssertEqual(text, textNode?.outerHTML.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
}
