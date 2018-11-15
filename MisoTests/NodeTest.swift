//
//  NodeTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 22/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class NodeTest: XCTestCase {
    
    func testHandlesBaseUri() {
        let tag = Tag.valueOf(tagName: "a")
        let attributes = Attributes()
        attributes.put(string: "/foo", forKey: "relHref")
        attributes.put(string: "http://bar/qux", forKey: "absHref")
        
        let noBase = Element(tag: tag, baseUri: nil, attributes: attributes)
        XCTAssertEqual(nil, noBase.absUrl(forAttributeKey: "relHref")) // with no base, should NOT fallback to href attrib, whatever it is
        XCTAssertEqual("http://bar/qux", noBase.absUrl(forAttributeKey: "absHref")) // no base but valid attrib, return attrib
        
        let withBase = Element(tag: tag, baseUri: "http://foo/", attributes: attributes)
        XCTAssertEqual("http://foo/foo", withBase.absUrl(forAttributeKey: "relHref")) // with no base, should NOT fallback to href attrib, whatever it is
        XCTAssertEqual("http://bar/qux", withBase.absUrl(forAttributeKey: "absHref")) // href is abs, so returns that
        XCTAssertEqual(nil, withBase.absUrl(forAttributeKey: "noval"))
        
        let dodgyBase = Element(tag: tag, baseUri: "wtf://no-such-protocol/", attributes: attributes)
        XCTAssertEqual("http://bar/qux", dodgyBase.absUrl(forAttributeKey: "absHref")) // base fails, but href good, so get that
        XCTAssertEqual(nil, dodgyBase.absUrl(forAttributeKey: "relHref")) // base fails, only rel href, so return nothing
    }
    
    func testSetBaseUriIsRecursive() {
        let doc = Miso.parse(html: "<div><p></p></div>")
        let baseUri = "https://google.com"
        doc.baseUri = baseUri
        
        XCTAssertEqual(baseUri, doc.baseUri)
        XCTAssertEqual(baseUri, doc.select("div").first?.baseUri)
        XCTAssertEqual(baseUri, doc.select("p").first?.baseUri)
    }
    
    func testHandlesAbsPrefix() {
        let doc = Miso.parse(html: "<a href=\"/foo\">Hello</a>", baseUri: "https://google.com/")
        let a = doc.select("a").first
        
        XCTAssertEqual("/foo", a?.attr("href"))
        XCTAssertEqual("https://google.com/foo", a?.attr("abs:href"))
        XCTAssert(a?.has(attr: "abs:href") ?? false)
    }
    
    func testHandlesAbsOnImage() {
        let doc = Miso.parse(html: "<p><img src=\"/rez/osi_logo.png\" /></p>", baseUri: "https://google.com/")
        let img = doc.select("img").first
        XCTAssertEqual("https://google.com/rez/osi_logo.png", img?.attr("abs:src"))
        XCTAssertEqual(img?.absUrl(forAttributeKey: "src"), img?.attr("abs:src"))
    }
    
    func testHandlesAbsPrefixOnHasAttr() {
        // 1: no abs url; 2: has abs url
        let doc = Miso.parse(html: "<a id=1 href='/foo'>One</a> <a id=2 href='https://google.com/'>Two</a>")
        let one = doc.select("#1")[0]
        let two = doc.select("#2")[0]
        
        XCTAssertFalse(one.has(attr: "abs:href"))
        XCTAssert(one.has(attr: "href"))
        XCTAssertEqual(nil, one.absUrl(forAttributeKey: "href"))
        
        XCTAssert(two.has(attr: "abs:href"))
        XCTAssert(two.has(attr: "href"))
        XCTAssertEqual("https://google.com/", two.absUrl(forAttributeKey: "href"))
    }
    
    func testLiteralAbsPrefix() {
        // if there is a literal attribute "abs:xxx", don't try and make absolute.
        let doc = Miso.parse(html: "<a abs:href='odd'>One</a>")
        let element = doc.select("a")[0]
        XCTAssert(element.has(attr: "abs:href"))
        XCTAssertEqual("odd", element.attr("abs:href"))
    }
    
    func testHandleAbsOnFileUris() {
        let doc = Miso.parse(html: "<a href='password'>One/a><a href='/var/log/messages'>Two</a>", baseUri: "file:/etc/")
        let one = doc.select("a")[0]
        XCTAssertEqual("file:///etc/password", one.absUrl(forAttributeKey: "href"))
        
        let two = doc.select("a")[1]
        XCTAssertEqual("file:///var/log/messages", two.absUrl(forAttributeKey: "href"))
    }
    
    func testhHandleAbsOnLocalhostFileUris() {
        let doc = Miso.parse(html: "<a href='password'>One/a><a href='/var/log/messages'>Two</a>", baseUri: "file://localhost/etc/")
        let one = doc.select("a")[0]
        
        XCTAssertEqual("file://localhost/etc/password", one.absUrl(forAttributeKey: "href"))
    }
    
    func testHandlesAbsOnProtocolessAbsoluteUris() {
        let doc1 = Miso.parse(html: "<a href='//example.net/foo'>One</a>", baseUri: "http://example.com/")
        let doc2 = Miso.parse(html: "<a href='//example.net/foo'>One</a>", baseUri: "https://example.com/")
    
        let one = doc1.select("a")[0]
        let two = doc2.select("a")[0]
    
        XCTAssertEqual("http://example.net/foo", one.absUrl(forAttributeKey: "href"))
        XCTAssertEqual("https://example.net/foo", two.absUrl(forAttributeKey: "href"))
    
        let doc3 = Miso.parse(html: "<img src=//www.google.com/images/errors/logo_sm.gif alt=Google>", baseUri: "https://google.com")
        XCTAssertEqual("https://www.google.com/images/errors/logo_sm.gif", doc3.select("img").attr("abs:src"))
    }
    
    func testAbsHandlesRelativeQuery() {
        let doc = Miso.parse(html: "<a href='?foo'>One</a> <a href='bar.html?foo'>Two</a>", baseUri: "https://jsoup.org/path/file?bar")
        
        let a1 = doc.select("a").first
        XCTAssertEqual("https://jsoup.org/path/file?foo", a1?.absUrl(forAttributeKey: "href"))
        
        let a2 = doc.select("a")[1]
        XCTAssertEqual("https://jsoup.org/path/bar.html?foo", a2.absUrl(forAttributeKey: "href"))
    }
    
    func testAbsHandlesDotFromIndex() {
        let doc = Miso.parse(html: "<a href='./one/two.html'>One</a>", baseUri: "http://example.com")
        let a1 = doc.select("a").first
        XCTAssertEqual("http://example.com/one/two.html", a1?.absUrl(forAttributeKey: "href"))
    }
    
    func testRemove() {
        let doc = Miso.parse(html: "<p>One <span>two</span> three</p>")
        let p = doc.select("p").first
        p?.childNodes[0].removeFromParent()
        
        XCTAssertEqual("two three", p?.text)
        XCTAssertEqual("<span>two</span> three", p?.html.strippedNewLines)
    }
    
    func testReplace() {
        let doc = Miso.parse(html: "<p>One <span>two</span> three</p>")
        let p = doc.select("p").first
        let insert = doc.create(element: "em").text(replaceWith: "foo")
        p?.childNodes[1].replace(with: insert)
        
        XCTAssertEqual("One <em>foo</em> three", p?.html)
    }
    
    func testOwnerDocument() {
        let doc = Miso.parse(html: "<p>Hello")
        let p = doc.select("p").first
        XCTAssertTrue(p?.ownerDocument == doc)
        XCTAssertTrue(doc.ownerDocument == doc)
        XCTAssertNil(doc.parentNode)
    }
    
    func testRoot() {
        let doc = Miso.parse(html: "<div><p>Hello")
        let p = doc.select("p").first
        let root = p?.root
        XCTAssertEqual(doc, root)
        XCTAssertNil(root?.parentNode)
        XCTAssertEqual(doc.root, doc)
        XCTAssertEqual(doc.root, doc.ownerDocument)
        
        let standAlone = Element(tag: Tag.valueOf(tagName: "p"), baseUri: nil)
        XCTAssertNil(standAlone.parentNode)
        XCTAssertEqual(standAlone.root, standAlone)
        XCTAssertNil(standAlone.ownerDocument)
    }
    
    func testBefore() {
        let doc = Miso.parse(html: "<p>One <b>two</b> three</p>")
        let newNode = Element(tag: Tag.valueOf(tagName: "em"), baseUri: nil)
        newNode.append(text: "four")
        
        doc.select("b").first?.insertBefore(node: newNode)
        XCTAssertEqual("<p>One <em>four</em><b>two</b> three</p>", doc.body?.html)
        
        doc.select("b").first?.insertBefore(html: "<i>five</i>")
        XCTAssertEqual("<p>One <em>four</em><i>five</i><b>two</b> three</p>", doc.body?.html)
    }
    
    func testAfter() {
        let doc = Miso.parse(html: "<p>One <b>two</b> three</p>")
        let newNode = Element(tag: Tag.valueOf(tagName: "em"), baseUri: nil)
        newNode.append(text: "four")
        
        doc.select("b").first?.insertAfter(node: newNode)
        XCTAssertEqual("<p>One <b>two</b><em>four</em> three</p>", doc.body?.html)
        
        doc.select("b").first?.insertAfter(html: "<i>five</i>")
        XCTAssertEqual("<p>One <b>two</b><i>five</i><em>four</em> three</p>", doc.body?.html)
    }
    
    func testUnwrap() {
        let doc = Miso.parse(html: "<div>One <span>Two <b>Three</b></span> Four</div>")
        let span = doc.select("span").first
        let twoText = span?.childNodes[0]
        let node = span?.unwrap()
        
        XCTAssertEqual("<div>One Two <b>Three</b> Four</div>", doc.body?.html.strippedNewLines)
        XCTAssertTrue(node is TextNode)
        XCTAssertEqual("Two ", (node as? TextNode)?.text)
        XCTAssertEqual(node, twoText)
        XCTAssertEqual(node?.parentNode, doc.select("div").first)
    }
    
    func testUnwrapNoChildren() {
        let doc = Miso.parse(html: "<div>One <span></span> Two</div>")
        let span = doc.select("span").first
        let node = span?.unwrap()
        XCTAssertEqual("<div>One  Two</div>", doc.body?.html.strippedNewLines)
        XCTAssertNil(node)
    }
    
    func testTraverse() {
        let doc = Miso.parse(html: "<div><p>Hello</p></div><div>There</div>")
        let accum = StringBuilder()
        doc.select("div").first?.traverse(nodeVisitor: NodeVisitor(
            head: { node, depth in accum.append("<"+node.nodeName + ">") },
            tail: { node, depth in accum.append("</"+node.nodeName + ">") }
            )
        )

        XCTAssertEqual("<div><p><#text></#text></p></div>", accum.stringValue)
    }
    
    func testOrphanNodeReturnsNilForSiblingElements() {
        let node = Element(tag: Tag.valueOf(tagName: "p"), baseUri: nil)
        let el = Element(tag: Tag.valueOf(tagName: "p"), baseUri: nil)
        
        XCTAssertNil(node.siblingIndex)
        XCTAssertEqual(0, node.siblingNodes.count)
        
        XCTAssertNil(node.previousSibling)
        XCTAssertNil(node.nextSibling)
        
        XCTAssertEqual(0, el.siblingElements.count)
        XCTAssertNil(el.previousSiblingElement)
        XCTAssertNil(el.nextSiblingElement)
    }
    
}
