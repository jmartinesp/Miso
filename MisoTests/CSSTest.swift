//
//  CSSTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 30/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class CSSTest: XCTestCase {
    
    private var _htmlString: String!
    var htmlString: String {
        if _htmlString == nil {
            let sb = StringBuilder(string: "<html><head></head><body>")
            
            sb.append("<div id='pseudo'>")
            for i in (1...10) {
                sb.append(String(format: "<p>%d</p>", i))
            }
            sb.append("</div>")
            
            sb.append("<div id='type'>")
            for i in (1...10) {
                sb.append(String(format: "<p>%d</p>",i))
                sb.append(String(format: "<span>%d</span>",i))
                sb.append(String(format: "<em>%d</em>",i))
                sb.append(String(format: "<svg>%d</svg>",i))
            }
            sb.append("</div>")
            
            sb.append("<span id='onlySpan'><br /></span>")
            sb.append("<p class='empty'><!-- Comment only is still empty! --></p>")
            
            sb.append("<div id='only'>")
            sb.append("Some text before the <em>only</em> child in this div")
            sb.append("</div>")
            
            sb.append("</body></html>")
            _htmlString = sb.stringValue
        }
        return _htmlString
    }
    
    var document: Document!
    
    override func setUp() {
        super.setUp()
        document = Miso.parse(html: htmlString)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFirstChild() {
        check(document.select("#pseudo :first-child"), "1")
        check(document.select("html:first-child"))
    }
    
    func testLastChild() {
        check(document.select("#pseudo :last-child"), "10")
        check(document.select("html:last-child"))
    }
    
    func testNthChildSimple() {
        for i in (1...10) {
            check(document.select("#pseudo :nth-child(\(i))"), "\(i)")
        }
    }
    
    func testNthOfTypeUnknown() {
        for i in (1...10) {
            check(document.select("#type svg:nth-of-type(\(i))"), "\(i)")
        }
    }
    
    func testNthLastChild() {
        for i in (1...10) {
            check(document.select("#pseudo :nth-last-child(\(i))"), "\(11-i)")
        }
    }
    
    func testNthOfTypeSimple() {
        for i in (1...10) {
            check(document.select("#type p:nth-of-type(\(i))"), "\(i)")
        }
    }
    
    func testNthLastOfTypeSimple() {
        for i in (1...10) {
            check(document.select("#type :nth-last-of-type(\(i))"), "\(11-i)", "\(11-i)", "\(11-i)", "\(11-i)")
        }
    }
    
    func testNthChildAdvanced() {
        check(document.select("#pseudo :nth-child(-5)"))
        check(document.select("#pseudo :nth-child(odd)"), "1", "3", "5", "7", "9")
        check(document.select("#pseudo :nth-child(2n-1)"), "1", "3", "5", "7", "9")
        check(document.select("#pseudo :nth-child(2n+1)"), "1", "3", "5", "7", "9")
        check(document.select("#pseudo :nth-child(2n+3)"), "3", "5", "7", "9")
        check(document.select("#pseudo :nth-child(even)"), "2", "4", "6", "8", "10")
        check(document.select("#pseudo :nth-child(2n)"), "2", "4", "6", "8", "10")
        check(document.select("#pseudo :nth-child(3n-1)"), "2", "5", "8")
        check(document.select("#pseudo :nth-child(-2n+5)"), "1", "3", "5")
        check(document.select("#pseudo :nth-child(+5)"), "5")
    }
    
    func testNthOfTypeAdvanced() {
        check(document.select("#type :nth-of-type(-5)"))
        check(document.select("#type p:nth-of-type(odd)"), "1", "3", "5", "7", "9")
        check(document.select("#type em:nth-of-type(2n-1)"), "1", "3", "5", "7", "9")
        check(document.select("#type p:nth-of-type(2n+1)"), "1", "3", "5", "7", "9")
        check(document.select("#type span:nth-of-type(2n+3)"), "3", "5", "7", "9")
        check(document.select("#type p:nth-of-type(even)"), "2", "4", "6", "8", "10")
        check(document.select("#type p:nth-of-type(2n)"), "2", "4", "6", "8", "10")
        check(document.select("#type p:nth-of-type(3n-1)"), "2", "5", "8")
        check(document.select("#type p:nth-of-type(-2n+5)"), "1", "3", "5")
        check(document.select("#type :nth-of-type(+5)"), "5", "5", "5", "5")
    }
    
    func testNthLastChildAdvanced() {
        check(document.select("#pseudo :nth-last-child(-5)"))
        check(document.select("#pseudo :nth-last-child(odd)"), "2", "4", "6", "8", "10")
        check(document.select("#pseudo :nth-last-child(2n-1)"), "2", "4", "6", "8", "10")
        check(document.select("#pseudo :nth-last-child(2n+1)"), "2", "4", "6", "8", "10")
        check(document.select("#pseudo :nth-last-child(2n+3)"), "2", "4", "6", "8")
        check(document.select("#pseudo :nth-last-child(even)"), "1", "3", "5", "7", "9")
        check(document.select("#pseudo :nth-last-child(2n)"), "1", "3", "5", "7", "9")
        check(document.select("#pseudo :nth-last-child(3n-1)"), "3", "6", "9")
        
        check(document.select("#pseudo :nth-last-child(-2n+5)"), "6", "8", "10")
        check(document.select("#pseudo :nth-last-child(+5)"), "6")
    }
    
    func testNthLastOfTypeAdvanced() {
        check(document.select("#type :nth-last-of-type(-5)"))
        check(document.select("#type p:nth-last-of-type(odd)"), "2", "4", "6", "8", "10")
        check(document.select("#type em:nth-last-of-type(2n-1)"), "2", "4", "6", "8", "10")
        check(document.select("#type p:nth-last-of-type(2n+1)"), "2", "4", "6", "8", "10")
        check(document.select("#type span:nth-last-of-type(2n+3)"), "2", "4", "6", "8")
        check(document.select("#type p:nth-last-of-type(even)"), "1", "3", "5", "7", "9")
        check(document.select("#type p:nth-last-of-type(2n)"), "1", "3", "5", "7", "9")
        check(document.select("#type p:nth-last-of-type(3n-1)"), "3", "6", "9")
        
        check(document.select("#type span:nth-last-of-type(-2n+5)"), "6", "8", "10")
        check(document.select("#type :nth-last-of-type(+5)"), "6", "6", "6", "6")
    }
    
    func testFirstOfType() {
        check(document.select("div:not(#only) :first-of-type"), "1", "1", "1", "1", "1")
    }
    
    func testLastOfType() {
        check(document.select("div:not(#only) :last-of-type"), "10", "10", "10", "10", "10")
    }
    
    func testEmpty() {
        let sel = document.select(":empty")
        XCTAssertEqual(3, sel.count)
        XCTAssertEqual("head", sel[0].tagName)
        XCTAssertEqual("br", sel[1].tagName)
        XCTAssertEqual("p", sel[2].tagName)
    }
    
    func testOnlyChild() {
        let sel = document.select("span :only-child")
        XCTAssertEqual(1, sel.count)
        XCTAssertEqual("br", sel[0].tagName)
        
        check(document.select("#only :only-child"), "only")
    }
    
    func testOnlyOfType() {
        let sel = document.select(":only-of-type")
        XCTAssertEqual(6, sel.count)
        XCTAssertEqual("head", sel[0].tagName)
        XCTAssertEqual("body", sel[1].tagName)
        XCTAssertEqual("span", sel[2].tagName)
        XCTAssertEqual("br", sel[3].tagName)
        XCTAssertEqual("p", sel[4].tagName)
        XCTAssert(sel[4].hasClass("empty"))
        XCTAssertEqual("em", sel[5].tagName)
    }
    
    private func check(_ elements: Elements, _ expectedContext: String...) {
        XCTAssertEqual(elements.count, expectedContext.count)
        for i in (0..<expectedContext.count) {
            XCTAssertEqual(expectedContext[i], elements[i].ownText)
        }
    }
    
}
