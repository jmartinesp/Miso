//
//  CleanerTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 28/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class CleanerTest: XCTestCase {
    
    func testSimpleBehavior() {
        var html = "<div><p class=foo><a href='http://evil.com'>Hello <b id=bar>there</b>!</a></div>"
        var cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.simpleText)
        
        XCTAssertEqual("Hello <b>there</b>!", cleanHTML.strippedNewLines)
        
        html = "Hello <b>there</b>!"
        cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.simpleText)
        
        XCTAssertEqual("Hello <b>there</b>!", cleanHTML.strippedNewLines)
    }
    
    func testBasicBehavior() {
        let html = "<div><p><a href='javascript:sendAllMoney()'>Dodgy</a> <A HREF='HTTP://nice.com'>Nice</a></p><blockquote>Hello</blockquote>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.basic)
        
        XCTAssertEqual("<p><a rel=\"nofollow\">Dodgy</a> <a href=\"http://nice.com\" rel=\"nofollow\">Nice</a></p><blockquote>Hello</blockquote>", cleanHTML.strippedNewLines)
    }
    
    func testBasicWithImages() {
        let html = "<div><p><img src='http://example.com/' alt=Image></p><p><img src='ftp://ftp.example.com'></p></div>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.basicWithImages)
        
        XCTAssertEqual("<p><img src=\"http://example.com/\" alt=\"Image\"></p><p><img></p>", cleanHTML.strippedNewLines)
    }
    
    func testRelaxed() {
        let html = "<h1>Head</h1><table><tr><td>One<td>Two</td></tr></table>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.relaxed)
        
        XCTAssertEqual("<h1>Head</h1><table><tbody><tr><td>One</td><td>Two</td></tr></tbody></table>", cleanHTML.strippedNewLines)
    }
    
    func testRemoveTags() {
        let html = "<div><p><A HREF='HTTP://nice.com'>Nice</a></p><blockquote>Hello</blockquote>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.basic.remove(tags: "a"))
        
        XCTAssertEqual("<p>Nice</p><blockquote>Hello</blockquote>", cleanHTML.strippedNewLines)
    }
    
    func testRemoveAttrs() {
        let html = "<div><p>Nice</p><blockquote cite='http://example.com/quotations'>Hello</blockquote>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.basic.remove(from: "blockquote", attributes: "cite"))
        
        XCTAssertEqual("<p>Nice</p><blockquote>Hello</blockquote>", cleanHTML.strippedNewLines)
    }
    
    func testRemoveEnforcedAttrs() {
        let html = "<div><p><A HREF='HTTP://nice.com'>Nice</a></p><blockquote>Hello</blockquote>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.basic.remove(from: "a", attrEnforced: "rel"))
        
        XCTAssertEqual("<p><a href=\"http://nice.com\">Nice</a></p><blockquote>Hello</blockquote>", cleanHTML.strippedNewLines)
    }
    
    func testRemoveProtocols() {
        let html = "<p>Contact me <a href='mailto:info@example.com'>here</a></p>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.basic.remove(from: "a", attr: "href", protocols: "ftp", "mailto"))
        
        XCTAssertEqual("<p>Contact me <a rel=\"nofollow\">here</a></p>", cleanHTML.strippedNewLines)
    }
    
    func testDropComments() {
        let html = "<p>Hello<!-- no --></p>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.relaxed)
        
        XCTAssertEqual("<p>Hello</p>", cleanHTML)
    }
    
    func testDropXMLProc() {
        let html = "<?import namespace=\"xss\"><p>Hello</p>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.relaxed)
        XCTAssertEqual("<p>Hello</p>", cleanHTML)
    }
    
    func testDropScript() {
        let html = "<SCRIPT SRC=//ha.ckers.org/.j><SCRIPT>alert(/XSS/.source)</SCRIPT>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.relaxed)
        XCTAssertEqual("", cleanHTML)
    }
    
    func testDropImageScript() {
        let html = "<IMG SRC=\"javascript:alert('XSS')\">"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.relaxed)
        XCTAssertEqual("<img>", cleanHTML)
    }
    
    func testCleanJavascriptHref() {
        let html = "<A HREF=\"javascript:document.location='http://www.google.com/'\">XSS</A>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.relaxed)
        XCTAssertEqual("<a>XSS</a>", cleanHTML)
    }
    
    func testCleanAnchorProtocol() {
        let validAnchor = "<a href=\"#valid\">Valid anchor</a>";
        let invalidAnchor = "<a href=\"#anchor with spaces\">Invalid anchor</a>";
        
        // A Whitelist that does not allow anchors will strip them out.
        var cleanHTML = Miso.clean(bodyHtml: validAnchor, whitelist: Whitelist.relaxed)
        XCTAssertEqual("<a>Valid anchor</a>", cleanHTML)
        
        cleanHTML = Miso.clean(bodyHtml: invalidAnchor, whitelist: Whitelist.relaxed)
        XCTAssertEqual("<a>Invalid anchor</a>", cleanHTML)
        
        // A Whitelist that allows them will keep them.
        let relaxedWithAnchor = Whitelist.relaxed.add(to: "a", attr: "href", protocols: "#")
        
        cleanHTML = Miso.clean(bodyHtml: validAnchor, whitelist: relaxedWithAnchor)
        XCTAssertEqual(validAnchor, cleanHTML)
        
        // An invalid anchor is never valid.
        cleanHTML = Miso.clean(bodyHtml: invalidAnchor, whitelist: relaxedWithAnchor)
        XCTAssertEqual("<a>Invalid anchor</a>", cleanHTML)
    }
    
    func testDropUnknownTags() {
        let html = "<p><custom foo=true>Test</custom></p>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.relaxed)
        XCTAssertEqual("<p>Test</p>", cleanHTML)
    }
    
    func testHandlesEmptyAttributes() {
        let html = "<img alt=\"\" src= unknown=''>"
        let cleanHTML = Miso.clean(bodyHtml: html, whitelist: Whitelist.basicWithImages)
        XCTAssertEqual("<img alt=\"\">", cleanHTML)
    }
    
    func testIsValidBodyHTML() {
        let ok = "<p>Test <b><a href='http://example.com/' rel='nofollow'>OK</a></b></p>"
        let ok1 = "<p>Test <b><a href='http://example.com/'>OK</a></b></p>" // missing enforced is OK because still needs run thru cleaner
        let nok1 = "<p><script></script>Not <b>OK</b></p>"
        let nok2 = "<p align=right>Test Not <b>OK</b></p>"
        let nok3 = "<!-- comment --><p>Not OK</p>" // comments and the like will be cleaned
        let nok4 = "<html><head>Foo</head><body><b>OK</b></body></html>" // not body html
        let nok5 = "<p>Test <b><a href='http://example.com/' rel='nofollowme'>OK</a></b></p>"
        let nok6 = "<p>Test <b><a href='http://example.com/'>OK</b></p>" // missing close tag
        let nok7 = "</div>What"
        XCTAssert(Miso.isValid(bodyHtml: ok, whitelist: Whitelist.basic))
        XCTAssert(Miso.isValid(bodyHtml: ok1, whitelist:  Whitelist.basic));
        XCTAssertFalse(Miso.isValid(bodyHtml: nok1, whitelist: Whitelist.basic))
        XCTAssertFalse(Miso.isValid(bodyHtml: nok2, whitelist: Whitelist.basic))
        XCTAssertFalse(Miso.isValid(bodyHtml: nok3, whitelist: Whitelist.basic))
        XCTAssertFalse(Miso.isValid(bodyHtml: nok4, whitelist: Whitelist.basic))
        XCTAssertFalse(Miso.isValid(bodyHtml: nok5, whitelist: Whitelist.basic))
        XCTAssertFalse(Miso.isValid(bodyHtml: nok6, whitelist: Whitelist.basic))
        XCTAssertFalse(Miso.isValid(bodyHtml: ok, whitelist: Whitelist.none))
        XCTAssertFalse(Miso.isValid(bodyHtml: nok7, whitelist: Whitelist.basic))
    }
    
    func testIsValidDocument() {
        let ok = "<html><head></head><body><p>Hello</p></body><html>"
        let nok = "<html><head><script>woops</script><title>Hello</title></head><body><p>Hello</p></body><html>"
        
        let relaxed = Whitelist.relaxed
        let cleaner = Cleaner(whitelist: relaxed)
        let okDoc = Miso.parse(html: ok)
        XCTAssert(cleaner.isValid(document: okDoc))
        XCTAssertFalse(cleaner.isValid(document: Miso.parse(html: nok)))
        XCTAssertFalse(Cleaner(whitelist: Whitelist.none).isValid(document: okDoc))
    }
    
    func testResolvesRelativeLinks() {
        let html = "<a href='/foo'>Link</a><img src='/bar'>"
        let clean = Miso.clean(bodyHtml: html, whitelist: Whitelist.basicWithImages, baseUri: "http://example.com/")
        XCTAssertEqual("<a href=\"http://example.com/foo\" rel=\"nofollow\">Link</a>\n<img src=\"http://example.com/bar\">", clean)
    }
    
    func testPreservesRelativeLinksIfConfigured() {
        let html = "<a href='/foo'>Link</a><img src='/bar'> <img src='javascript:alert()'>"
        let clean = Miso.clean(bodyHtml: html, whitelist: Whitelist.basicWithImages.preserveRelativeLinks(true), baseUri: "http://example.com/")
        XCTAssertEqual("<a href=\"/foo\" rel=\"nofollow\">Link</a>\n<img src=\"/bar\"> \n<img>", clean)
    }
    
    func testDropsUnresolvableRelativeLinks() {
        let html = "<a href='/foo'>Link</a>";
        let clean = Miso.clean(bodyHtml: html, whitelist: Whitelist.basic)
        XCTAssertEqual("<a rel=\"nofollow\">Link</a>", clean)
    }
    
    func testHandlesCustomProtocols() {
        let html = "<img src='cid:12345' /> <img src='data:gzzt' />"
        let dropped = Miso.clean(bodyHtml: html, whitelist: Whitelist.basicWithImages)
        XCTAssertEqual("<img> \n<img>", dropped)
        
        let preserved = Miso.clean(bodyHtml: html, whitelist: Whitelist.basicWithImages.add(to: "img", attr: "src", protocols: "cid", "data"))
        XCTAssertEqual("<img src=\"cid:12345\"> \n<img src=\"data:gzzt\">", preserved)
    }
    
    func testHandlesAllPseudoTag() {
        let html = "<p class='foo' src='bar'><a class='qux'>link</a></p>"
        let whitelist = Whitelist()
            .add(to: ":all", attributes: "class")
            .add(to: "p", attributes: "style")
            .add(tags: "p", "a")
        
        let clean = Miso.clean(bodyHtml: html, whitelist: whitelist)
        XCTAssertEqual("<p class=\"foo\"><a class=\"qux\">link</a></p>", clean)
    }
    
    func testAddsTagOnAttributesIfNotSet() {
        let html = "<p class='foo' src='bar'>One</p>"
        let whitelist = Whitelist().add(to: "p", attributes: "class")
        // ^^ whitelist does not have explicit tag add for p, inferred from add attributes.
        let clean = Miso.clean(bodyHtml: html, whitelist: whitelist)
        XCTAssertEqual("<p class=\"foo\">One</p>", clean)
    }
    
    func testSupplyOutputSettings() {
        // test that one can override the default document output settings
        let os = build(OutputSettings()) {
            $0.prettyPrint = false
            $0.escapeMode = .full
            $0.charset = .ascii
        }
        
        let html = "<div><p>&bernou;</p></div>";
        let customOut = Miso.clean(bodyHtml: html, whitelist: Whitelist.relaxed, outputSettings: os, baseUri: "http://foo.com/")
        let defaultOut = Miso.clean(bodyHtml: html, whitelist: Whitelist.relaxed, baseUri: "http://foo.com/")
        XCTAssertNotEqual(defaultOut, customOut)
        
        XCTAssertEqual("<div><p>&Bernoullis;</p></div>", customOut) // entities now prefers shorted names if aliased
        XCTAssertEqual("<div>\n" +
            " <p>ℬ</p>\n" +
            "</div>", defaultOut)
        
        os.charset = .ascii
        os.escapeMode = .base
        let customOut2 = Miso.clean(bodyHtml: html, whitelist: Whitelist.relaxed, outputSettings: os, baseUri: "http://foo.com/")
        XCTAssertEqual("<div><p>&#x212c;</p></div>", customOut2)
    }
    
    func testHandlesFramesets() {
        let dirty = "<html><head><script></script><noscript></noscript></head><frameset><frame src=\"foo\" /><frame src=\"foo\" /></frameset></html>"
        let clean = Miso.clean(bodyHtml: dirty, whitelist: Whitelist.basic)
        XCTAssertEqual("", clean) // nothing good can come out of that
        
        let dirtyDoc = Miso.parse(html: dirty)
        let cleanDoc = Cleaner(whitelist: Whitelist.basic).clean(document: dirtyDoc)
        XCTAssertNotNil(cleanDoc)
        XCTAssertEqual(0, cleanDoc.body?.childNodes.count)
    }
    
    func testCleansInternationalText() {
        XCTAssertEqual("привет", Miso.clean(bodyHtml: "привет", whitelist: Whitelist.none))
    }
    
    func testScriptTagInWhiteList() {
        let whitelist = Whitelist.relaxed
        _ = whitelist.add(tags: "script")
        XCTAssert(Miso.isValid(bodyHtml: "Hello<script>alert('Doh')</script>World !", whitelist: whitelist))
    }
    
    func testHandlesControlCharactersAfterTagName() {
        let html = "<a/\06>"
        let clean = Miso.clean(bodyHtml: html, whitelist: Whitelist.basic)
        XCTAssertEqual("<a rel=\"nofollow\"></a>", clean)
    }
}
