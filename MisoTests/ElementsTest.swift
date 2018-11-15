//
//  ElementsTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 2/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class ElementsTest: XCTestCase {
    
    func testFilter() {
        let h = "<p>Excl</p><div class=headline><p>Hello</p><p>There</p></div><div class=headline><h1>Headline</h1></div>"
        let doc = Miso.parse(html: h)
        let els = doc.select(".headline").select("p")
        XCTAssertEqual(2, els.count)
        XCTAssertEqual("Hello", els[0].text)
        XCTAssertEqual("There", els[1].text)
    }
    
    func testAttributes() {
        let h = "<p title=foo><p title=bar><p class=foo><p class=bar>"
        let doc = Miso.parse(html: h)
        let withTitle = doc.select("p[title]")
        XCTAssertEqual(2, withTitle.count)
        XCTAssert(withTitle.has(attr: "title"))
        XCTAssertFalse(withTitle.has(attr: "class"))
        XCTAssertEqual("foo", withTitle.attr("title"))
        
        withTitle.remove(attr: "title")
        XCTAssertEqual(2, withTitle.count) // existing Elements are not reevaluated
        XCTAssertEqual(0, doc.select("p[title]").count)
        
        let ps = doc.select("p").attr("style", setValue: "classy")
        XCTAssertEqual(4, ps.count)
        XCTAssertEqual("classy", ps.last?.attr("style"))
        XCTAssertEqual("bar", ps.last?.attr("class"))
    }
    
    func testHasAttr() {
        let doc = Miso.parse(html: "<p title=foo><p title=bar><p class=foo><p class=bar>")
        let ps = doc.select("p")
        XCTAssert(ps.has(attr: "class"))
        XCTAssertFalse(ps.has(attr: "style"))
    }
    
    func testHasAbsAttr() {
        let doc = Miso.parse(html: "<a id=1 href='/foo'>One</a> <a id=2 href='https://jsoup.org'>Two</a>")
        let one = doc.select("#1")
        let two = doc.select("#2")
        let both = doc.select("a")
        XCTAssertFalse(one.has(attr: "abs:href"))
        XCTAssert(two.has(attr: "abs:href"))
        XCTAssert(both.has(attr: "abs:href")) // hits on #2
    }
    
    func testAttr() {
        let doc = Miso.parse(html: "<p title=foo><p title=bar><p class=foo><p class=bar>")
        let classVal = doc.select("p").attr("class")
        XCTAssertEqual("foo", classVal)
    }
    
    func testAbsAttr() {
        let doc = Miso.parse(html: "<a id=1 href='/foo'>One</a> <a id=2 href='https://jsoup.org'>Two</a>")
        let one = doc.select("#1")
        let two = doc.select("#2")
        let both = doc.select("a")
        
        XCTAssertEqual(nil, one.attr("abs:href"))
        XCTAssertEqual("https://jsoup.org", two.attr("abs:href"))
        XCTAssertEqual("https://jsoup.org", both.attr("abs:href"))
    }
    
    func testClasses() {
        let doc = Miso.parse(html: "<div><p class='mellow yellow'></p><p class='red green'></p>")
        
        let els = doc.select("p")
        XCTAssert(els.hasClass("red"))
        XCTAssertFalse(els.hasClass("blue"))
        els.addClass("blue")
        els.removeClass("yellow")
        els.toggleClass("mellow")
        
        XCTAssertEqual("blue", els[0].className)
        XCTAssertEqual("red green blue mellow", els[1].className)
    }
    
    func testHasClassCaseInsensitive() {
        let els = Miso.parse(html: "<p Class=One>One <p class=Two>Two <p CLASS=THREE>THREE").select("p")
        let one = els[0]
        let two = els[1]
        let thr = els[2]
        
        XCTAssert(one.hasClass("One"))
        XCTAssert(one.hasClass("ONE"))
        
        XCTAssert(two.hasClass("TWO"))
        XCTAssert(two.hasClass("Two"))
        
        XCTAssert(thr.hasClass("ThreE"))
        XCTAssert(thr.hasClass("three"))
    }
    
    func testText() {
        let h = "<div><p>Hello<p>there<p>world</div>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("Hello there world", doc.select("div > *").text)
    }
    
    func testHasText() {
        let doc = Miso.parse(html: "<div><p>Hello</p></div><div><p></p></div>")
        let divs = doc.select("div")
        XCTAssert(divs.hasText)
        XCTAssertFalse(doc.select("div + div").hasText)
    }
    
    func testHtml() {
        let doc = Miso.parse(html: "<div><p>Hello</p></div><div><p>There</p></div>")
        let divs = doc.select("div")
        XCTAssertEqual("<p>Hello</p>\n<p>There</p>", divs.html)
    }
    
    func testOuterHtml() {
        let doc = Miso.parse(html: "<div><p>Hello</p></div><div><p>There</p></div>")
        let divs = doc.select("div")
        XCTAssertEqual("<div><p>Hello</p></div><div><p>There</p></div>", divs.outerHTML.strippedNewLines)
    }
    
    func testSetHtml() {
        let doc = Miso.parse(html: "<p>One</p><p>Two</p><p>Three</p>")
        let ps = doc.select("p")
                
        ps.prepend(html: "<b>Bold</b>").append(html: "<i>Ital</i>")
        XCTAssertEqual("<p><b>Bold</b>Two<i>Ital</i></p>", ps[1].outerHTML.strippedNewLines)
        
        ps.html(replaceWith: "<span>Gone</span>")
        XCTAssertEqual("<p><span>Gone</span></p>", ps[1].outerHTML.strippedNewLines)
    }
    
    func testVal() {
        let doc = Miso.parse(html: "<input value='one' /><textarea>two</textarea>")
        let els = doc.select("input, textarea")
        XCTAssertEqual(2, els.count)
        XCTAssertEqual("one", els.val)
        XCTAssertEqual("two", els.last?.val)
        
        els.val(replaceWith: "three")
        XCTAssertEqual("three", els.first?.val)
        XCTAssertEqual("three", els.last?.val)
        XCTAssertEqual("<textarea>three</textarea>", els.last?.outerHTML)
    }
    
    func testBefore() {
        let doc = Miso.parse(html: "<p>This <a>is</a> <a>jsoup</a>.</p>")
        doc.select("a").insertBefore(html: "<span>foo</span>")
        XCTAssertEqual("<p>This <span>foo</span><a>is</a> <span>foo</span><a>jsoup</a>.</p>", doc.body?.html.strippedNewLines)
    }
    
    func testAfter() {
        let doc = Miso.parse(html: "<p>This <a>is</a> <a>jsoup</a>.</p>")
        doc.select("a").insertAfter(html: "<span>foo</span>")
        XCTAssertEqual("<p>This <a>is</a><span>foo</span> <a>jsoup</a><span>foo</span>.</p>", doc.body?.html.strippedNewLines)
    }
    
    func testWrap() {
        let h = "<p><b>This</b> is <b>jsoup</b></p>"
        let doc = Miso.parse(html: h)
        doc.select("b").wrap(html: "<i></i>")
        XCTAssertEqual("<p><i><b>This</b></i> is <i><b>jsoup</b></i></p>", doc.body?.html)
    }
    
    func testWrapDiv() {
        let h = "<p><b>This</b> is <b>jsoup</b>.</p> <p>How do you like it?</p>"
        let doc = Miso.parse(html: h)
        doc.select("p").wrap(html: "<div></div>")
        XCTAssertEqual("<div><p><b>This</b> is <b>jsoup</b>.</p></div> <div><p>How do you like it?</p></div>",
                       doc.body?.html.strippedNewLines)
    }
    
    func testUnwrap() {
        let h = "<div><font>One</font> <font><a href=\"/\">Two</a></font></div"
        let doc = Miso.parse(html: h)
        doc.select("font").unwrap()
        XCTAssertEqual("<div>One <a href=\"/\">Two</a></div>", doc.body?.html.strippedNewLines)
    }
    
    func testUnwrapP() {
        let h = "<p><a>One</a> Two</p> Three <i>Four</i> <p>Fix <i>Six</i></p>"
        let doc = Miso.parse(html: h)
        doc.select("p").unwrap()
        XCTAssertEqual("<a>One</a> Two Three <i>Four</i> Fix <i>Six</i>", doc.body?.html.strippedNewLines)
    }
    
    func testUnwrapKeepsSpace() {
        let h = "<p>One <span>two</span> <span>three</span> four</p>"
        let doc = Miso.parse(html: h)
        doc.select("span").unwrap()
        XCTAssertEqual("<p>One two three four</p>", doc.body?.html)
    }
    
    func testEmpty() {
        let doc = Miso.parse(html: "<div><p>Hello <b>there</b></p> <p>now!</p></div>")
        doc.outputSettings.prettyPrint = false
        
        doc.select("p").removeAllChildren()
        XCTAssertEqual("<div><p></p> <p></p></div>", doc.body?.html)
    }
    
    func testRemove() {
        let doc = Miso.parse(html: "<div><p>Hello <b>there</b></p> jsoup <p>now!</p></div>")
        doc.outputSettings.prettyPrint = false
        
        doc.select("p").removeFromParent()
        XCTAssertEqual("<div> jsoup </div>", doc.body?.html)
    }
    
    func testEq() {
        let h = "<p>Hello<p>there<p>world"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("there", doc.select("p").subElements(at: 1).text)
        XCTAssertEqual("there", doc.select("p")[1].text)
    }
    
    func testIs() {
        let h = "<p>Hello<p title=foo>there<p>world"
        let doc = Miso.parse(html: h)
        let ps = doc.select("p")
        XCTAssert(ps.matches("[title=foo]"))
        XCTAssertFalse(ps.matches("[title=bar]"))
    }
    
    func testParents() {
        let doc = Miso.parse(html: "<div><p>Hello</p></div><p>There</p>")
        let parents = doc.select("p").parents
        
        XCTAssertEqual(3, parents.count)
        XCTAssertEqual("div", parents[0].tagName)
        XCTAssertEqual("body", parents[1].tagName)
        XCTAssertEqual("html", parents[2].tagName)
    }
    
    func testNot() {
        let doc = Miso.parse(html: "<div id=1><p>One</p></div> <div id=2><p><span>Two</span></p></div>")
        
        let div1 = doc.select("div").not(":has(p > span)")
        XCTAssertEqual(1, div1.count)
        XCTAssertEqual("1", div1.first?.id)
        
        let div2 = doc.select("div").not("#1")
        XCTAssertEqual(1, div2.count)
        XCTAssertEqual("2", div2.first?.id)
    }
    
    func testTagNameSet() {
        let doc = Miso.parse(html: "<p>Hello <i>there</i> <i>now</i></p>")
        doc.select("i").tagName(replaceWith: "em")
        
        XCTAssertEqual("<p>Hello <em>there</em> <em>now</em></p>", doc.body?.html)
    }
    
    func testTraverse() {
        let doc = Miso.parse(html: "<div><p>Hello</p></div><div>There</div>")
        let accum = StringBuilder()
        _ = doc.select("div").traverse(nodeVisitor: NodeVisitor(head: { node, depth in
            accum.append("<" + node.nodeName + ">")
        }, tail: { node, depth in
            accum.append("</" + node.nodeName + ">")
        }))
        XCTAssertEqual("<div><p><#text></#text></p></div><div><#text></#text></div>", accum.stringValue)
    }
    
    func testForms() {
        let doc = Miso.parse(html: "<form id=1><input name=q></form><div /><form id=2><input name=f></form>")
        let els = doc.select("*")
        XCTAssertEqual(9, els.count)
        
        let forms = els.forms
        XCTAssertEqual(2, forms.count)
        XCTAssertEqual("1", forms[0].id)
        XCTAssertEqual("2", forms[1].id)
    }
    
    func testClassWithHyphen() {
        let doc = Miso.parse(html: "<p class='tab-nav'>Check</p>")
        let els = doc.elements(byClass: "tab-nav")
        XCTAssertEqual(1, els.count)
        XCTAssertEqual("Check", els.text)
    }
    
    func testSiblings() {
        let doc = Miso.parse(html: "<div><p>1<p>2<p>3<p>4<p>5<p>6</div><div><p>7<p>8<p>9<p>10<p>11<p>12</div>")
        
        let els = doc.select("p:eq(3)") // gets p4 and p10
        XCTAssertEqual(2, els.count)
        
        let next = els.next
        XCTAssertEqual(2, next.count)
        XCTAssertEqual("5", next.first?.text)
        XCTAssertEqual("11", next.last?.text)
        
        XCTAssertEqual(0, els.next("p:contains(6)").count)
        let nextF = els.next("p:contains(5)")
        XCTAssertEqual(1, nextF.count)
        XCTAssertEqual("5", nextF.first?.text)
        
        let nextA = els.nextForAll
        XCTAssertEqual(4, nextA.count)
        XCTAssertEqual("5", nextA.first?.text)
        XCTAssertEqual("12", nextA.last?.text)
        
        let nextAF = els.nextForAll("p:contains(6)")
        XCTAssertEqual(1, nextAF.count)
        XCTAssertEqual("6", nextAF.first?.text)
        
        let prev = els.previous
        XCTAssertEqual(2, prev.count)
        XCTAssertEqual("3", prev.first?.text)
        XCTAssertEqual("9", prev.last?.text)
        
        XCTAssertEqual(0, els.previous("p:contains(1)").count)
        let prevF = els.previous("p:contains(3)")
        XCTAssertEqual(1, prevF.count)
        XCTAssertEqual("3", prevF.first?.text)
        
        let prevA = els.previousForAll
        XCTAssertEqual(6, prevA.count)
        XCTAssertEqual("3", prevA.first?.text)
        XCTAssertEqual("7", prevA.last?.text)
        
        let prevAF = els.previousForAll("p:contains(1)")
        XCTAssertEqual(1, prevAF.count)
        XCTAssertEqual("1", prevAF.first?.text)
    }
    
    func testEachText() {
        let doc = Miso.parse(html: "<div><p>1<p>2<p>3<p>4<p>5<p>6</div><div><p>7<p>8<p>9<p>10<p>11<p>12<p></p></div>")
        let divText = doc.select("div").texts
        XCTAssertEqual(2, divText.count)
        XCTAssertEqual("1 2 3 4 5 6", divText[0])
        XCTAssertEqual("7 8 9 10 11 12", divText[1])
        
        let pText = doc.select("p").texts
        let ps = doc.select("p")
        XCTAssertEqual(13, ps.count)
        XCTAssertEqual(12, pText.count) // not 13, as last doesn't have text
        XCTAssertEqual("1", pText[0])
        XCTAssertEqual("2", pText[1])
        XCTAssertEqual("5", pText[4])
        XCTAssertEqual("7", pText[6])
        XCTAssertEqual("12", pText[11])
    }
    
    func testEachAttr() {
        let doc = Miso.parse(html: "<div><a href='/foo'>1</a><a href='http://example.com/bar'>2</a><a href=''>3</a><a>4</a>",
                                   baseUri: "http://example.com")
        
        let hrefAttrs = doc.select("a").attrs("href")
        XCTAssertEqual(3, hrefAttrs.count)
        XCTAssertEqual("/foo", hrefAttrs[0])
        XCTAssertEqual("http://example.com/bar", hrefAttrs[1])
        XCTAssertEqual("", hrefAttrs[2])
        XCTAssertEqual(4, doc.select("a").count)
        
        let absAttrs = doc.select("a").attrs("abs:href")
        XCTAssertEqual(3, absAttrs.count)
        XCTAssertEqual(3, absAttrs.count)
        XCTAssertEqual("http://example.com/foo", absAttrs[0])
        XCTAssertEqual("http://example.com/bar", absAttrs[1])
        XCTAssertEqual("http://example.com", absAttrs[2])
    }
    
}
