//
//  AttributeParseText.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 24/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class AttributeParseText: XCTestCase {
    
    func testParsesRoughAttributeString() {
        let html = "<a id=\"123\" class=\"baz = 'bar'\" style = 'border: 2px'qux zim foo = 12 mux=18 />"
        // should be: <id=123>, <class=baz = 'bar'>, <qux=>, <zim=>, <foo=12>, <mux.=18>
        
        let element = Miso.parse(html: html).elements(byTag: "a")[0]
        let attributes = element.attributes
        XCTAssertEqual(7, attributes.count)
        XCTAssertEqual("123", attributes.get(byTag: "id")?.value)
        XCTAssertEqual("baz = 'bar'", attributes.get(byTag: "class")?.value)
        XCTAssertEqual("border: 2px", attributes.get(byTag: "style")?.value)
        XCTAssertEqual("", attributes.get(byTag: "qux")?.value)
        XCTAssertEqual("", attributes.get(byTag: "zim")?.value)
        XCTAssertEqual("12", attributes.get(byTag: "foo")?.value)
        XCTAssertEqual("18", attributes.get(byTag: "mux")?.value)
    }
    
    func testHandlesNewLinesAndReturns() {
        let html = "<a\r\nfoo='bar\r\nqux'\r\nbar\r\n=\r\ntwo>One</a>"
        let element = Miso.parse(html: html).elements(byTag: "a").first
        
        XCTAssertEqual(2, element?.attributes.count)
        XCTAssertEqual("bar\r\nqux", element?.attr("foo"))
        XCTAssertEqual("two", element?.attr("bar"))
    }
    
    func testParsesEmptyString() {
        let html = "<a />"
        let element = Miso.parse(html: html).elements(byTag: "a").first
        let attributes = element?.attributes
        XCTAssertEqual(0, attributes?.count)
    }
    
    func testCanStartWithEq() {
        let html = "<a =empty />"
        let element = Miso.parse(html: html).elements(byTag: "a").first
        let attributes = element?.attributes
        XCTAssertEqual(1, attributes?.count)
        XCTAssert(attributes!.hasKeyIgnoreCase(key: "=empty"))
        XCTAssertEqual("", attributes?.get(byTag: "=empty")?.value)
    }
    
    func testStrictAttributeUnescapes() {
        let html = "<a id=1 href='?foo=bar&mid&lt=true'>One</a> <a id=2 href='?foo=bar&lt;qux&lg=1'>Two</a>"
        let elements = Miso.parse(html: html).elements(byTag: "a")
        XCTAssertEqual("?foo=bar&mid&lt=true", elements.first?.attr("href"))
        XCTAssertEqual("?foo=bar<qux&lg=1", elements.last?.attr("href"))
    }
    
    func testMoreAttributeUnescapes() {
        let html = "<a href='&wr_id=123&mid-size=true&ok=&wr'>Check</a>"
        let elements = Miso.parse(html: html).elements(byTag: "a")
        XCTAssertEqual("&wr_id=123&mid-size=true&ok=&wr", elements.first?.attr("href"))
    }
    
    func testParsesBooleanAttributes() {
        let html = "<a normal=\"123\" boolean empty=\"\"></a>"
        let element = Miso.parse(html: html).elements(byTag: "a").first
        let attributes = element?.attributes
        
        XCTAssertEqual("123", element?.attr("normal"))
        XCTAssertEqual("", element?.attr("boolean"))
        XCTAssertEqual("", element?.attr("empty"))
        
        XCTAssertEqual(3, attributes?.count)
        
        // Assuming the list order always follows the parsed html
        XCTAssertFalse(attributes?.orderedValues[0] is BooleanAttribute)
        XCTAssert(attributes?.orderedValues[1] is BooleanAttribute)
        XCTAssertFalse(attributes?.orderedValues[2] is BooleanAttribute)
    }
    
    func testDropsSlashFromAttributeName() {
        let html = "<img /onerror='doMyJob'/>"
        var doc = Miso.parse(html: html)
        
        XCTAssertFalse(doc.select("img[onerror]").isEmpty)
        XCTAssertEqual("<img onerror=\"doMyJob\">", doc.body?.html)
        
        doc = Miso.parse(html: html, baseUri: nil, parser: Parser.xmlParser)
        XCTAssertEqual("<img onerror=\"doMyJob\" />", doc.html)
    }
}
