//
//  EntititesTest.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 21/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import SwiftySoup

class EntititesTest: XCTestCase {
    
    func testEscape() {
        let text = "Hello &<> Å å π 新 there ¾ © »"
        let escapedAscii = Entities.escape(string: text, outputSettings: build(OutputSettings()) {
            $0.charset = .ascii
            $0.escapeMode = .base
        })
        let escapedAsciiFull = Entities.escape(string: text, outputSettings: build(OutputSettings()) {
            $0.charset = .ascii
            $0.escapeMode = .full
        })
        let escapedAsciiXhtml = Entities.escape(string: text, outputSettings: build(OutputSettings()) {
            $0.charset = .ascii
            $0.escapeMode = .xhtml
        })
        let escapedUtfFull = Entities.escape(string: text, outputSettings: build(OutputSettings()) {
            $0.charset = .utf8
            $0.escapeMode = .full
        })
        let escapedUtfMin = Entities.escape(string: text, outputSettings: build(OutputSettings()) {
            $0.charset = .utf8
            $0.escapeMode = .xhtml
        })
        
        XCTAssertEqual("Hello &amp;&lt;&gt; &Aring; &aring; &#x3c0; &#x65b0; there &frac34; &COPY; &raquo;", escapedAscii)
        XCTAssertEqual("Hello &amp;&lt;&gt; &Aring; &aring; &pi; &#x65b0; there &frac34; &COPY; &raquo;", escapedAsciiFull)
        XCTAssertEqual("Hello &amp;&lt;&gt; &#xc5; &#xe5; &#x3c0; &#x65b0; there &#xbe; &#xa9; &#xbb;", escapedAsciiXhtml)
        XCTAssertEqual("Hello &amp;&lt;&gt; Å å π 新 there ¾ © »", escapedUtfFull)
        XCTAssertEqual("Hello &amp;&lt;&gt; Å å π 新 there ¾ © »", escapedUtfMin)
        // odd that it's defined as aring in base but angst in full
        
        // round trip
        XCTAssertEqual(text, Entities.unescape(escapedAscii))
        XCTAssertEqual(text, Entities.unescape(escapedAsciiFull))
        XCTAssertEqual(text, Entities.unescape(escapedAsciiXhtml))
        XCTAssertEqual(text, Entities.unescape(escapedUtfFull))
        XCTAssertEqual(text, Entities.unescape(escapedUtfMin))
    }
    
    func testEscapedSupplementary() {
        let text = "𝕙"
        let escapedAscii = Entities.escape(string: text, outputSettings: build(OutputSettings()) { $0.charset = .ascii; $0.escapeMode = .base })
        XCTAssertEqual("&#x1d559;", escapedAscii)
        let escapedAsciiFull = Entities.escape(string: text, outputSettings: build(OutputSettings()) { $0.charset = .ascii; $0.escapeMode = .full })
        XCTAssertEqual("&hopf;", escapedAsciiFull)
        let escapedUtf = Entities.escape(string: text, outputSettings: build(OutputSettings()) { $0.charset = .utf8; $0.escapeMode = .full })
        XCTAssertEqual(text, escapedUtf)
    }
    
    func testUnescapeMultiChars() {
        let text = "&NestedGreaterGreater; &nGg; &nGt; &nGtv; &Gt; &gg;" // gg is not combo, but 8811 could conflict with NestedGreaterGreater or others
        let un = "≫ ⋙̸ ≫⃒ ≫̸ ≫ ≫"
        XCTAssertEqual(un, Entities.unescape(text))
        let escaped = Entities.escape(string: un, outputSettings: build(OutputSettings()) { $0.charset = .ascii; $0.escapeMode = .full })
        XCTAssertEqual("&Gt; &Gg;&#x338; &Gt;&#x20d2; &Gt;&#x338; &Gt; &Gt;", escaped)
        XCTAssertEqual(un, Entities.unescape(escaped))
    }
    
    func testXhtml() {
        XCTAssertEqual("38", Entities.EscapeMode.xhtml.codepoint(forName: "amp"))
        XCTAssertEqual("62", Entities.EscapeMode.xhtml.codepoint(forName: "gt"))
        XCTAssertEqual("60", Entities.EscapeMode.xhtml.codepoint(forName: "lt"))
        XCTAssertEqual("34", Entities.EscapeMode.xhtml.codepoint(forName: "quot"))
        
        XCTAssertEqual("amp", Entities.EscapeMode.xhtml.name(forCodepoint: "38"))
        XCTAssertEqual("gt", Entities.EscapeMode.xhtml.name(forCodepoint: "62"))
        XCTAssertEqual("lt", Entities.EscapeMode.xhtml.name(forCodepoint: "60"))
        XCTAssertEqual("quot", Entities.EscapeMode.xhtml.name(forCodepoint: "34"))
    }
    
    func testGetByName() {
        XCTAssertEqual("≫⃒", Entities.entity(byName: "nGt"))
        XCTAssertEqual("fj", Entities.entity(byName: "fjlig"))
        XCTAssertEqual("≫", Entities.entity(byName: "gg"))
        XCTAssertEqual("©", Entities.entity(byName: "copy"))
    }
    
    func testEscapeSupplementaryCharacter() {
        let text = String(Character(UnicodeScalar(135361)!))
        let escapedAscii = Entities.escape(string: text, outputSettings: build(OutputSettings()) { $0.charset = .ascii; $0.escapeMode = .base })
        XCTAssertEqual("&#x210c1;", escapedAscii)
        let escapedUtf = Entities.escape(string: text, outputSettings: build(OutputSettings()) { $0.charset = .utf8; $0.escapeMode = .base })
        XCTAssertEqual(text, escapedUtf)
    }
    
    func testNotMissingMultis() {
        let text = "&nparsl;"
        let un = "\u{2AFD}\u{20E5}"
        XCTAssertEqual(un, Entities.unescape(text))
    }
    
    func testNotMissingSupplementals() {
        let text = "&npolint; &qfr;"
        let un = "⨔ 𝔮" // 𝔮
        XCTAssertEqual(un, Entities.unescape(text))
    }
    
    func testUnescape() {
        let text = "Hello &AElig; &amp;&LT&gt; &reg &angst; &angst &#960; &#960 &#x65B0; there &! &frac34; &copy; &COPY;"
        XCTAssertEqual("Hello Æ &<> ® Å &angst π π 新 there &! ¾ © ©", Entities.unescape(text))
        
        XCTAssertEqual("&0987654321; &unknown", Entities.unescape("&0987654321; &unknown"))
    }
    
    func testStrictUnescape() { // for attributes, enforce strict unescaping (must look like &#xxx , not just &#xxx)
        let text = "Hello &amp= &amp;"
        XCTAssertEqual("Hello &amp= &", Entities.unescape(string: text, strict: true))
        XCTAssertEqual("Hello &= &", Entities.unescape(text))
        XCTAssertEqual("Hello &= &", Entities.unescape(string: text, strict: false))
    }
    
    
    func testCaseSensitive() {
        let unescaped = "Ü ü & &"
        XCTAssertEqual("&Uuml; &uuml; &amp; &amp;",
                       Entities.escape(string: unescaped, outputSettings: build(OutputSettings()) { $0.charset = .ascii; $0.escapeMode = .full }))
        
        let escaped = "&Uuml; &uuml; &amp; &AMP"
        XCTAssertEqual("Ü ü & &", Entities.unescape(escaped))
    }
    
    func testQuoteReplacements() {
        let escaped = "&#92 &#36"
        let unescaped = "\\ $"
        
        XCTAssertEqual(unescaped, Entities.unescape(escaped))
    }
    
    func testLetterDigitEntities() {
        let html = "<p>&sup1;&sup2;&sup3;&frac14;&frac12;&frac34;</p>"
        let doc = SwiftySoup.parse(html: html)
        doc.outputSettings.charset = .ascii
        let p = doc.select("p").first
        XCTAssertEqual("&sup1;&sup2;&sup3;&frac14;&frac12;&frac34;", p?.html)
        XCTAssertEqual("¹²³¼½¾", p?.text)
        doc.outputSettings.charset = .utf8
        XCTAssertEqual("¹²³¼½¾", p?.html)
    }
    
    func testNoSpuriousDecodes() {
        let string = "http://www.foo.com?a=1&num_rooms=1&children=0&int=VA&b=2"
        XCTAssertEqual(string, Entities.unescape(string))
    }
    
    func testEscapesGtInXmlAttributesButNotInHtml() {
        // https://github.com/jhy/jsoup/issues/528 - < is OK in HTML attribute values, but not in XML
        
        
        let docHtml = "<a title='<p>One</p>'>One</a>"
        let doc = SwiftySoup.parse(html: docHtml)
        let element = doc.select("a").first
        
        doc.outputSettings.escapeMode = .base
        XCTAssertEqual("<a title=\"<p>One</p>\">One</a>", element?.outerHTML)
        
        doc.outputSettings.escapeMode = .xhtml
        XCTAssertEqual("<a title=\"&lt;p>One&lt;/p>\">One</a>", element?.outerHTML)
    }
    
}
