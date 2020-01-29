//
//  HTMLParserTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 24/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class HTMLParserTest: XCTestCase {
    
    func testParsesSimpleDocument() {
        let html = "<html><head><title>First!</title></head><body><p>First post! <img src=\"foo.png\" /></p></body></html>"
        let doc = Miso.parse(html: html)
        // need a better way to verify these:
        let p = doc.body?.children[0]
        XCTAssertEqual("p", p?.tagName)
        let img = p?.children[0]
        XCTAssertEqual("foo.png", img?.attr("src"))
        XCTAssertEqual("img", img?.tagName)
    }
    
    func testParsesRoughAttributes() {
        let html = "<html><head><title>First!</title></head><body><p class=\"foo > bar\">First post! <img src=\"foo.png\" /></p></body></html>"
        let doc = Miso.parse(html: html)
        
        // need a better way to verify these:
        let p = doc.body?.children[0]
        XCTAssertEqual("p", p?.tagName)
        XCTAssertEqual("foo > bar", p?.attr("class"))
    }
    
    func testParsesQuiteRoughAttributes() {
        let html = "<p =a>One<a <p>Something</p>Else"
        // this gets a <p> with attr '=a' and an <a tag with an attribue named '<p'; and then auto-recreated
        var doc = Miso.parse(html: html)
        XCTAssertEqual("<p =a>One<a <p>Something</a></p>\n" +
            "<a <p>Else</a>", doc.body?.html)
        
        doc = Miso.parse(html: "<p .....>")
        XCTAssertEqual("<p .....></p>", doc.body?.html)
    }
    
    func testParsesComments() {
        let html = "<html><head></head><body><img src=foo><!-- <table><tr><td></table> --><p>Hello</p></body></html>"
        let doc = Miso.parse(html: html)
        
        let body = doc.body
        let comment = body?.childNodes[1] as? Comment // comment should not be sub of img, as it's an empty tag as? Comment
        XCTAssertEqual(" <table><tr><td></table> ", comment?.data)
        let p = body?.children[1]
        let text = p?.childNodes[0] as? TextNode
        XCTAssertEqual("Hello", text?.wholeText)
    }
    
    func testParsesUnterminatedComments() {
        let html = "<p>Hello<!-- <tr><td>"
        let doc = Miso.parse(html: html)
        let p = doc.elements(byTag: "p")[0]
        XCTAssertEqual("Hello", p.text)
        let text = p.childNodes[0] as? TextNode
        XCTAssertEqual("Hello", text?.wholeText)
        let comment = p.childNodes[1] as? Comment
        XCTAssertEqual(" <tr><td>", comment?.data)
    }
    
    func testDropsUnterminatedTag() {
        // jsoup used to parse this to <p>, but whatwg, webkit will drop.
        let h1 = "<p"
        var doc = Miso.parse(html: h1)
        XCTAssertEqual(0, doc.elements(byTag: "p").count)
        XCTAssertEqual("", doc.text)
        
        let h2 = "<div id=1<p id='2'"
        doc = Miso.parse(html: h2)
        XCTAssertEqual("", doc.text)
    }
    
    func testDropsUnterminatedAttribute() {
        // jsoup used to parse this to <p id="foo">, but whatwg, webkit will drop.
        let h1 = "<p id=\"foo"
        let doc = Miso.parse(html: h1)
        XCTAssertEqual("", doc.text)
    }
    
    func testParsesUnterminatedTextarea() {
        // don't parse right to end, but break on <p>
        let doc = Miso.parse(html: "<body><p><textarea>one<p>two")
        let t = doc.select("textarea").first
        XCTAssertEqual("one", t?.text)
        XCTAssertEqual("two", doc.select("p")[1].text)
    }
    
    func testParsesUnterminatedOption() {
        // bit weird this -- browsers and spec get stuck in select until there's a </select>
        let doc = Miso.parse(html: "<body><p><select><option>One<option>Two</p><p>Three</p>")
        let options = doc.select("option")
        XCTAssertEqual(2, options.count)
        XCTAssertEqual("One", options.first?.text)
        XCTAssertEqual("TwoThree", options.last?.text)
    }
    
    func testTestSpaceAfterTag() {
        let doc = Miso.parse(html: "<div > <a name=\"top\"></a ><p id=1 >Hello</p></div>")
        XCTAssertEqual("<div> <a name=\"top\"></a><p id=\"1\">Hello</p></div>", doc.body?.html.strippedNewLines)
    }
    
    func testCreatesDocumentStructure() {
        let html = "<meta name=keywords /><link rel=stylesheet /><title>jsoup</title><p>Hello world</p>"
        let doc = Miso.parse(html: html)
        let head = doc.head
        let body = doc.body
        
        XCTAssertEqual(1, doc.children.count); // root node: contains html node
        XCTAssertEqual(2, doc.children[0].children.count); // html node: head and body
        XCTAssertEqual(3, head?.children.count)
        XCTAssertEqual(1, body?.children.count)
        
        XCTAssertEqual("keywords", head?.elements(byTag: "meta")[0].attr("name"))
        XCTAssertEqual(0, body?.elements(byTag: "meta").count)
        XCTAssertEqual("jsoup", doc.title)
        XCTAssertEqual("Hello world", body?.text)
        XCTAssertEqual("Hello world", body?.children[0].text)
    }
    
    func testCreatesStructureFromBodySnippet() {
        // the bar baz stuff naturally goes into the body, but the 'foo' goes into root, and the normalisation routine
        // needs to move into the start of the body
        let html = "foo <b>bar</b> baz"
        let doc = Miso.parse(html: html)
        XCTAssertEqual("foo bar baz", doc.text)
        
    }
    
    func testHandlesEscapedData() {
        let html = "<div title='Surf &amp; Turf'>Reef &amp; Beef</div>"
        let doc = Miso.parse(html: html)
        let div = doc.elements(byTag: "div")[0]
        
        XCTAssertEqual("Surf & Turf", div.attr("title"))
        XCTAssertEqual("Reef & Beef", div.text)
    }
    
    func testHandlesDataOnlyTags() {
        let t = "<style>font-family: bold</style>"
        let tels = Miso.parse(html: t).elements(byTag: "style")
        XCTAssertEqual("font-family: bold", tels[0].data)
        XCTAssertEqual("", tels[0].text)
        
        let s = "<p>Hello</p><script>obj.insert('<a rel=\"none\" />');\ni++;</script><p>There</p>"
        let doc = Miso.parse(html: s)
        XCTAssertEqual("Hello There", doc.text)
        XCTAssertEqual("obj.insert('<a rel=\"none\" />');\ni++;", doc.data)
    }
    
    func testHandlesTextAfterData() {
        let h = "<html><body>pre <script>inner</script> aft</body></html>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<html><head></head><body>pre <script>inner</script> aft</body></html>", doc.html.strippedNewLines)
    }
    
    func testHandlesTextArea() {
        let doc = Miso.parse(html: "<textarea>Hello</textarea>")
        let els = doc.select("textarea")
        XCTAssertEqual("Hello", els.text)
        XCTAssertEqual("Hello", els.val)
    }
    
    func testPreservesSpaceInTextArea() {
        // preserve because the tag is marked as preserve white space
        let doc = Miso.parse(html: "<textarea>\n\tOne\n\tTwo\n\tThree\n</textarea>")
        let expect = "One\n\tTwo\n\tThree"; // the leading and trailing spaces are dropped as a convenience to authors
        let el = doc.select("textarea").first!
        XCTAssertEqual(expect, el.text)
        XCTAssertEqual(expect, el.val)
        XCTAssertEqual(expect, el.html)
        XCTAssertEqual("<textarea>\n\t" + expect + "\n</textarea>", el.outerHTML) // but preserved in round-trip html
    }
    
    func testPreservesSpaceInScript() {
        // preserve because it's content is a data node
        let doc = Miso.parse(html: "<script>\nOne\n\tTwo\n\tThree\n</script>")
        let expect = "\nOne\n\tTwo\n\tThree\n"
        let el = doc.select("script").first!
        XCTAssertEqual(expect, el.data)
        XCTAssertEqual("One\n\tTwo\n\tThree", el.html)
        XCTAssertEqual("<script>" + expect + "</script>", el.outerHTML)
    }
    
    func testDoesNotCreateImplicitLists() {
        // old jsoup used to wrap this in <ul>, but that's not to spec
        let h = "<li>Point one<li>Point two"
        let doc = Miso.parse(html: h)
        let ol = doc.select("ul"); // should NOT have created a default ul.
        XCTAssertEqual(0, ol.count)
        let lis = doc.select("li")
        XCTAssertEqual(2, lis.count)
        XCTAssertEqual("body", lis.first?.parentElement?.tagName)
        
        // no fiddling with non-implicit lists
        let h2 = "<ol><li><p>Point the first<li><p>Point the second"
        let doc2 = Miso.parse(html: h2)
        
        XCTAssertEqual(0, doc2.select("ul").count)
        XCTAssertEqual(1, doc2.select("ol").count)
        XCTAssertEqual(2, doc2.select("ol li").count)
        XCTAssertEqual(2, doc2.select("ol li p").count)
        XCTAssertEqual(1, doc2.select("ol li")[0].children.count); // one p in first li
    }
    
    func testDiscardsNakedTds() {
        // jsoup used to make this into an implicit table; but browsers make it into a text run
        let h = "<td>Hello<td><p>There<p>now"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("Hello<p>There</p><p>now</p>", doc.body?.html.strippedNewLines)
        // <tbody> is introduced if no implicitly creating table, but allows tr to be directly under table
    }
    
    func testHandlesNestedImplicitTable() {
        let doc = Miso.parse(html: "<table><td>1</td></tr> <td>2</td></tr> <td> <table><td>3</td> <td>4</td></table> <tr><td>5</table>")
        XCTAssertEqual("<table><tbody><tr><td>1</td></tr> <tr><td>2</td></tr> <tr><td> <table><tbody><tr><td>3</td> <td>4</td></tr></tbody></table> </td></tr><tr><td>5</td></tr></tbody></table>", doc.body?.html.strippedNewLines)
    }
    
    func testHandlesWhatWgExpensesTableExample() {
        // http://www.whatwg.org/specs/web-apps/current-work/multipage/tabular-data.html#examples-0
        let doc = Miso.parse(html: "<table> <colgroup> <col> <colgroup> <col> <col> <col> <thead> <tr> <th> <th>2008 <th>2007 <th>2006 <tbody> <tr> <th scope=rowgroup> Research and development <td> $ 1,109 <td> $ 782 <td> $ 712 <tr> <th scope=row> Percentage of net sales <td> 3.4% <td> 3.3% <td> 3.7% <tbody> <tr> <th scope=rowgroup> Selling, general, and administrative <td> $ 3,761 <td> $ 2,963 <td> $ 2,433 <tr> <th scope=row> Percentage of net sales <td> 11.6% <td> 12.3% <td> 12.6% </table>")
        XCTAssertEqual("<table> <colgroup> <col> </colgroup><colgroup> <col> <col> <col> </colgroup><thead> <tr> <th> </th><th>2008 </th><th>2007 </th><th>2006 </th></tr></thead><tbody> <tr> <th scope=\"rowgroup\"> Research and development </th><td> $ 1,109 </td><td> $ 782 </td><td> $ 712 </td></tr><tr> <th scope=\"row\"> Percentage of net sales </th><td> 3.4% </td><td> 3.3% </td><td> 3.7% </td></tr></tbody><tbody> <tr> <th scope=\"rowgroup\"> Selling, general, and administrative </th><td> $ 3,761 </td><td> $ 2,963 </td><td> $ 2,433 </td></tr><tr> <th scope=\"row\"> Percentage of net sales </th><td> 11.6% </td><td> 12.3% </td><td> 12.6% </td></tr></tbody></table>", doc.body?.html.strippedNewLines)
    }
    
    func testHandlesTbodyTable() {
        let doc = Miso.parse(html: "<html><head></head><body><table><tbody><tr><td>aaa</td><td>bbb</td></tr></tbody></table></body></html>")
        XCTAssertEqual("<table><tbody><tr><td>aaa</td><td>bbb</td></tr></tbody></table>", doc.body?.html.strippedNewLines)
    }
    
    func testHandlesImplicitCaptionClose() {
        let doc = Miso.parse(html: "<table><caption>A caption<td>One<td>Two")
        XCTAssertEqual("<table><caption>A caption</caption><tbody><tr><td>One</td><td>Two</td></tr></tbody></table>", doc.body?.html.strippedNewLines)
    }
    
    func testNoTableDirectInTable() {
        let doc = Miso.parse(html: "<table> <td>One <td><table><td>Two</table> <table><td>Three")
        XCTAssertEqual("<table> <tbody><tr><td>One </td><td><table><tbody><tr><td>Two</td></tr></tbody></table> <table><tbody><tr><td>Three</td></tr></tbody></table></td></tr></tbody></table>", doc.body?.html.strippedNewLines)
    }
    
    func testIgnoresDupeEndTrTag() {
        let doc = Miso.parse(html: "<table><tr><td>One</td><td><table><tr><td>Two</td></tr></tr></table></td><td>Three</td></tr></table>"); // two </tr></tr>, must ignore or will close table
        XCTAssertEqual("<table><tbody><tr><td>One</td><td><table><tbody><tr><td>Two</td></tr></tbody></table></td><td>Three</td></tr></tbody></table>",
                       doc.body?.html.strippedNewLines)
    }
    
    func testHandlesBaseTags() {
        // only listen to the first base href
        let h = "<a href=1>#</a><base href='/2/'><a href='3'>#</a><base href='http://bar'><a href=/4>#</a>"
        let doc = Miso.parse(html: h, baseUri: "http://foo/")
        XCTAssertEqual("http://foo/2/", doc.baseUri) // gets set once, so doc and descendants have first only
        
        let anchors = doc.elements(byTag: "a")
        XCTAssertEqual(3, anchors.count)
        
        XCTAssertEqual("http://foo/2/", anchors[0].baseUri)
        XCTAssertEqual("http://foo/2/", anchors[1].baseUri)
        XCTAssertEqual("http://foo/2/", anchors[2].baseUri)
        
        XCTAssertEqual("http://foo/2/1", anchors[0].absUrl(forAttributeKey: "href"))
        XCTAssertEqual("http://foo/2/3", anchors[1].absUrl(forAttributeKey: "href"))
        XCTAssertEqual("http://foo/4", anchors[2].absUrl(forAttributeKey: "href"))
    }
    
    func testHandlesProtocolRelativeUrl() {
        let base = "https://example.com/"
        let html = "<img src='//example.net/img.jpg'>"
        let doc = Miso.parse(html: html, baseUri: base)
        let el = doc.select("img").first
        XCTAssertEqual("https://example.net/img.jpg", el?.absUrl(forAttributeKey: "src"))
    }
    
    func testHandlesCdata() {
        // todo: as this is html namespace, should actually treat as bogus comment, not cdata. keep as cdata for now
        let h = "<div id=1><![CDATA[<html>\n<foo><&amp;]]></div>" // the &amp; in there should remain literal
        let doc = Miso.parse(html: h)
        let div = doc.element(byId: "1")
        XCTAssertEqual("<html> <foo><&amp;", div?.text)
        XCTAssertEqual(0, div?.children.count)
        XCTAssertEqual(1, div?.childNodes.count) // no elements, one text node
    }
    
    func testHandlesUnclosedCdataAtEOF() {
        // https://github.com/jhy/jsoup/issues/349 would crash, as character reader would try to seek past EOF
        let h = "<![CDATA[]]"
        let doc = Miso.parse(html: h)
        XCTAssertEqual(1, doc.body?.childNodes.count)
    }
    
    func testHandlesInvalidStartTags() {
        let h = "<div>Hello < There <&amp;></div>"; // parse to <div {#text=Hello < There <&>}>
        let doc = Miso.parse(html: h)
        XCTAssertEqual("Hello < There <&>", doc.select("div").first?.text)
    }
    
    func testHandlesUnknownTags() {
        let h = "<div><foo title=bar>Hello<foo title=qux>there</foo></div>"
        let doc = Miso.parse(html: h)
        let foos = doc.select("foo")
        XCTAssertEqual(2, foos.count)
        XCTAssertEqual("bar", foos.first?.attr("title"))
        XCTAssertEqual("qux", foos.last?.attr("title"))
        XCTAssertEqual("there", foos.last?.text)
    }
    
    func testHandlesUnknownInlineTags() {
        let h = "<p><cust>Test</cust></p><p><cust><cust>Test</cust></cust></p>"
        let doc = Miso.parse(bodyFragment: h)
        let out = doc.body?.html
        XCTAssertEqual(h, out?.strippedNewLines)
    }
    
    func testParsesBodyFragment() {
        let h = "<!-- comment --><p><a href='foo'>One</a></p>"
        let doc = Miso.parse(bodyFragment: h, baseUri: "http://example.com")
        XCTAssertEqual("<body><!-- comment --><p><a href=\"foo\">One</a></p></body>", doc.body?.outerHTML.strippedNewLines)
        XCTAssertEqual("http://example.com/foo", doc.select("a").first?.absUrl(forAttributeKey: "href"))
    }
    
    func testHandlesUnknownNamespaceTags() {
        // note that the first foo:bar should not really be allowed to be self closing, if parsed in html mode.
        let h = "<foo:bar id='1' /><abc:def id=2>Foo<p>Hello</p></abc:def><foo:bar>There</foo:bar>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<foo:bar id=\"1\" /><abc:def id=\"2\">Foo<p>Hello</p></abc:def><foo:bar>There</foo:bar>", doc.body?.html.strippedNewLines)
    }
    
    func testHandlesKnownEmptyBlocks() {
        // if a known tag, allow self closing outside of spec, but force an end tag. unknown tags can be self closing.
        let h = "<div id='1' /><script src='/foo' /><div id=2><img /><img></div><a id=3 /><i /><foo /><foo>One</foo> <hr /> hr text <hr> hr text two"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<div id=\"1\"></div><script src=\"/foo\"></script><div id=\"2\"><img><img></div><a id=\"3\"></a><i></i><foo /><foo>One</foo> <hr> hr text <hr> hr text two", doc.body?.html.strippedNewLines)
    }
    
    func testHandlesSolidusAtAttributeEnd() {
        // this test makes sure [<a href=/>link</a>] is parsed as [<a href="/">link</a>], not [<a href="" /><a>link</a>]
        let h = "<a href=/>link</a>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<a href=\"/\">link</a>", doc.body?.html)
    }
    
    func testHandlesMultiClosingBody() {
        let h = "<body><p>Hello</body><p>there</p></body></body></html><p>now"
        let doc = Miso.parse(html: h)
        XCTAssertEqual(3, doc.select("p").count)
        XCTAssertEqual(3, doc.body?.children.count)
    }
    
    func testHandlesUnclosedDefinitionLists() {
        // jsoup used to create a <dl>, but that's not to spec
        let h = "<dt>Foo<dd>Bar<dt>Qux<dd>Zug"
        let doc = Miso.parse(html: h)
        XCTAssertEqual(0, doc.select("dl").count); // no auto dl
        XCTAssertEqual(4, doc.select("dt, dd").count)
        let dts = doc.select("dt")
        XCTAssertEqual(2, dts.count)
        XCTAssertEqual("Zug", dts[1].nextSiblingElement?.text)
    }
    
    func testHandlesBlocksInDefinitions() {
        // per the spec, dt and dd are inline, but in practise are block
        let h = "<dl><dt><div id=1>Term</div></dt><dd><div id=2>Def</div></dd></dl>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("dt", doc.select("#1").first?.parentElement?.tagName)
        XCTAssertEqual("dd", doc.select("#2").first?.parentElement?.tagName)
        XCTAssertEqual("<dl><dt><div id=\"1\">Term</div></dt><dd><div id=\"2\">Def</div></dd></dl>", doc.body?.html.strippedNewLines)
    }
    
    func testHandlesFrames() {
        let h = "<html><head><script></script><noscript></noscript></head><frameset><frame src=foo></frame><frame src=foo></frameset></html>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<html><head><script></script><noscript></noscript></head><frameset><frame src=\"foo\"><frame src=\"foo\"></frameset></html>",
                       doc.html.strippedNewLines)
        // no body auto vivification
    }
    
    func testIgnoresContentAfterFrameset() {
        let h = "<html><head><title>One</title></head><frameset><frame /><frame /></frameset><table></table></html>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<html><head><title>One</title></head><frameset><frame><frame></frameset></html>", doc.html.strippedNewLines)
        // no body, no table. No crash!
    }
    
    func testHandlesJavadocFont() {
        let h = "<TD BGCOLOR=\"#EEEEFF\" CLASS=\"NavBarCell1\">    <A HREF=\"deprecated-list.html\"><FONT CLASS=\"NavBarFont1\"><B>Deprecated</B></FONT></A>&nbsp;</TD>"
        let doc = Miso.parse(html: h)
        let a = doc.select("a")[0]
        XCTAssertEqual("Deprecated", a.text)
        XCTAssertEqual("font", a.children[0].tagName)
        XCTAssertEqual("b", a.children[0].children[0].tagName)
    }
    
    func testHandlesBaseWithoutHref() {
        let h = "<head><base target='_blank'></head><body><a href=/foo>Test</a></body>"
        let doc = Miso.parse(html: h, baseUri: "http://example.com/")
        let a = doc.select("a")[0]
        XCTAssertEqual("/foo", a.attr("href"))
        XCTAssertEqual("http://example.com/foo", a.attr("abs:href"))
    }
    
    func testNormalisesDocument() {
        let h = "<!doctype html>One<html>Two<head>Three<link></head>Four<body>Five </body>Six </html>Seven "
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<!doctype html><html><head></head><body>OneTwoThree<link>FourFive Six Seven </body></html>",
                       doc.html.strippedNewLines)
    }
    
    func testNormalisesEmptyDocument() {
        let doc = Miso.parse(html: "")
        XCTAssertEqual("<html><head></head><body></body></html>", doc.html.strippedNewLines)
    }
    
    func testNormalisesHeadlessBody() {
        let doc = Miso.parse(html: "<html><body><span class=\"foo\">bar</span>")
        XCTAssertEqual("<html><head></head><body><span class=\"foo\">bar</span></body></html>",
                       doc.html.strippedNewLines)
    }
    
    func testNormalisedBodyAfterContent() {
        let doc = Miso.parse(html: "<font face=Arial><body class=name><div>One</div></body></font>")
        XCTAssertEqual("<html><head></head><body class=\"name\"><font face=\"Arial\"><div>One</div></font></body></html>",
                       doc.html.strippedNewLines)
    }
    
    func testFindsCharsetInMalformedMeta() {
        let h = "<meta http-equiv=Content-Type content=text/html; charset=gb2312>"
        // example cited for reason of html5's <meta charset> element
        let doc = Miso.parse(html: h)
        XCTAssertEqual("gb2312", doc.select("meta").attr("charset"))
    }
    
    func testTestHgroup() {
        // jsoup used to not allow hroup in h{n}, but that's not in spec, and browsers are OK
        let doc = Miso.parse(html: "<h1>Hello <h2>There <hgroup><h1>Another<h2>headline</hgroup> <hgroup><h1>More</h1><p>stuff</p></hgroup>")
        XCTAssertEqual("<h1>Hello </h1><h2>There <hgroup><h1>Another</h1><h2>headline</h2></hgroup> <hgroup><h1>More</h1><p>stuff</p></hgroup></h2>", doc.body?.html.strippedNewLines)
    }
    
    func testTestRelaxedTags() {
        let doc = Miso.parse(html: "<abc_def id=1>Hello</abc_def> <abc-def>There</abc-def>")
        XCTAssertEqual("<abc_def id=\"1\">Hello</abc_def> <abc-def>There</abc-def>", doc.body?.html.strippedNewLines)
    }
    
    func testTestHeaderContents() {
        // h* tags in browsers can handle any internal content other than other h*. which is not per any as? h1 .. h9
        // spec, which defines them as containing phrasing content only. so, reality over theory.
        let doc = Miso.parse(html: "<h1>Hello <div>There</div> now</h1> <h2>More <h3>Content</h3></h2>")
        XCTAssertEqual("<h1>Hello <div>There</div> now</h1> <h2>More </h2><h3>Content</h3>", doc.body?.html.strippedNewLines)
    }
    
    func testTestSpanContents() {
        // like h1 tags, the spec says SPAN is phrasing only, but browsers and publisher treat span as a block tag
        let doc = Miso.parse(html: "<span>Hello <div>there</div> <span>now</span></span>")
        XCTAssertEqual("<span>Hello <div>there</div> <span>now</span></span>", doc.body?.html.strippedNewLines)
    }
    
    func testTestNoImagesInNoScriptInHead() {
        // jsoup used to allow, but against spec if parsing with noscript
        let doc = Miso.parse(html: "<html><head><noscript><img src='foo'></noscript></head><body><p>Hello</p></body></html>")
        XCTAssertEqual("<html><head><noscript>&lt;img src=\"foo\"&gt;</noscript></head><body><p>Hello</p></body></html>", doc.html.strippedNewLines)
    }
    
    func testTestAFlowContents() {
        // html5 has <a> as either phrasing or block
        let doc = Miso.parse(html: "<a>Hello <div>there</div> <span>now</span></a>")
        XCTAssertEqual("<a>Hello <div>there</div> <span>now</span></a>", doc.body?.html.strippedNewLines)
    }
    
    func testTestFontFlowContents() {
        // html5 has no definition of <font>; often used as flow
        let doc = Miso.parse(html: "<font>Hello <div>there</div> <span>now</span></font>")
        XCTAssertEqual("<font>Hello <div>there</div> <span>now</span></font>", doc.body?.html.strippedNewLines)
    }
    
    func testHandlesMisnestedTagsBI() {
        // whatwg: <b><i></b></i>
        let h = "<p>1<b>2<i>3</b>4</i>5</p>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<p>1<b>2<i>3</i></b><i>4</i>5</p>", doc.body?.html)
        // adoption agency on </b>, reconstruction of formatters on 4.
    }
    
    func testHandlesMisnestedTagsBP() {
        //  whatwg: <b><p></b></p>
        let h = "<b>1<p>2</b>3</p>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<b>1</b>\n<p><b>2</b>3</p>", doc.body?.html)
    }
    
    func testHandlesUnexpectedMarkupInTables() {
        // whatwg - tests markers in active formatting (if they didn't work, would get in in table)
        // also tests foster parenting
        let h = "<table><b><tr><td>aaa</td></tr>bbb</table>ccc"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<b></b><b>bbb</b><table><tbody><tr><td>aaa</td></tr></tbody></table><b>ccc</b>", doc.body?.html.strippedNewLines)
    }
    
    func testHandlesUnclosedFormattingElements() {
        // whatwg: formatting elements get collected and applied, but excess elements are thrown away
        let h = "<!DOCTYPE html>\n" +
            "<p><b class=x><b class=x><b><b class=x><b class=x><b>X\n" +
            "<p>X\n" +
            "<p><b><b class=x><b>X\n" +
        "<p></b></b></b></b></b></b>X"
        let doc = Miso.parse(html: h)
        doc.outputSettings.indentAmount = 0
        let want = "<!doctype html>\n" +
            "<html>\n" +
            "<head></head>\n" +
            "<body>\n" +
            "<p><b class=\"x\"><b class=\"x\"><b><b class=\"x\"><b class=\"x\"><b>X </b></b></b></b></b></b></p>\n" +
            "<p><b class=\"x\"><b><b class=\"x\"><b class=\"x\"><b>X </b></b></b></b></b></p>\n" +
            "<p><b class=\"x\"><b><b class=\"x\"><b class=\"x\"><b><b><b class=\"x\"><b>X </b></b></b></b></b></b></b></b></p>\n" +
            "<p>X</p>\n" +
            "</body>\n" +
        "</html>"
        XCTAssertEqual(want, doc.html)
    }
    
    func testHandlesUnclosedAnchors() {
        let h = "<a href='http://example.com/'>Link<p>Error link</a>"
        let doc = Miso.parse(html: h)
        let want = "<a href=\"http://example.com/\">Link</a>\n<p><a href=\"http://example.com/\">Error link</a></p>"
        XCTAssertEqual(want, doc.body?.html)
    }
    
    func testReconstructFormattingElements() {
        // tests attributes and multi b
        let h = "<p><b class=one>One <i>Two <b>Three</p><p>Hello</p>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<p><b class=\"one\">One <i>Two <b>Three</b></i></b></p>\n<p><b class=\"one\"><i><b>Hello</b></i></b></p>", doc.body?.html)
    }
    
    func testReconstructFormattingElementsInTable() {
        // tests that tables get formatting markers -- the <b> applies outside the table and does not leak in,
        // and the <i> inside the table and does not leak out.
        let h = "<p><b>One</p> <table><tr><td><p><i>Three<p>Four</i></td></tr></table> <p>Five</p>"
        let doc = Miso.parse(html: h)
        let want = "<p><b>One</b></p>\n" +
            "<b> \n" +
            " <table>\n" +
            "  <tbody>\n" +
            "   <tr>\n" +
            "    <td><p><i>Three</i></p><p><i>Four</i></p></td>\n" +
            "   </tr>\n" +
            "  </tbody>\n" +
        " </table> <p>Five</p></b>"
        XCTAssertEqual(want, doc.body?.html)
    }
    
    func testCommentBeforeHtml() {
        let h = "<!-- comment --><!-- comment 2 --><p>One</p>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<!-- comment --><!-- comment 2 --><html><head></head><body><p>One</p></body></html>", doc.html.strippedNewLines)
    }
    
    func testEmptyTdTag() {
        let h = "<table><tr><td>One</td><td id='2' /></tr></table>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<td>One</td>\n<td id=\"2\"></td>", doc.select("tr").first?.html)
    }
    
    func testHandlesSolidusInA() {
        // test for bug #66
        let h = "<a class=lp href=/lib/14160711/>link text</a>"
        let doc = Miso.parse(html: h)
        let a = doc.select("a")[0]
        XCTAssertEqual("link text", a.text)
        XCTAssertEqual("/lib/14160711/", a.attr("href"))
    }
    
    func testHandlesSpanInTbody() {
        // test for bug 64
        let h = "<table><tbody><span class='1'><tr><td>One</td></tr><tr><td>Two</td></tr></span></tbody></table>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual(doc.select("span").first?.children.count, 0) // the span gets closed
        XCTAssertEqual(doc.select("table").count, 1) // only one table
    }
    
    func testHandlesUnclosedTitleAtEof() {
        XCTAssertEqual("Data", Miso.parse(html: "<title>Data").title)
        XCTAssertEqual("Data<", Miso.parse(html: "<title>Data<").title)
        XCTAssertEqual("Data</", Miso.parse(html: "<title>Data</").title)
        XCTAssertEqual("Data</t", Miso.parse(html: "<title>Data</t").title)
        XCTAssertEqual("Data</ti", Miso.parse(html: "<title>Data</ti").title)
        XCTAssertEqual("Data", Miso.parse(html: "<title>Data</title>").title)
        XCTAssertEqual("Data", Miso.parse(html: "<title>Data</title >").title)
    }
    
    func testHandlesUnclosedTitle() {
        let one = Miso.parse(html: "<title>One <b>Two <b>Three</TITLE><p>Test</p>"); // has title, so <b> is plain text
        XCTAssertEqual("One <b>Two <b>Three", one.title)
        XCTAssertEqual("Test", one.select("p").first?.text)
        
        let two = Miso.parse(html: "<title>One<b>Two <p>Test</p>"); // no title, so <b> causes </title> breakout
        XCTAssertEqual("One", two.title)
        XCTAssertEqual("<b>Two <p>Test</p></b>", two.body?.html)
    }
    
    func testHandlesUnclosedScriptAtEof() {
        XCTAssertEqual("Data", Miso.parse(html: "<script>Data").select("script").first?.data)
        XCTAssertEqual("Data<", Miso.parse(html: "<script>Data<").select("script").first?.data)
        XCTAssertEqual("Data</sc", Miso.parse(html: "<script>Data</sc").select("script").first?.data)
        XCTAssertEqual("Data</-sc", Miso.parse(html: "<script>Data</-sc").select("script").first?.data)
        XCTAssertEqual("Data</sc-", Miso.parse(html: "<script>Data</sc-").select("script").first?.data)
        XCTAssertEqual("Data</sc--", Miso.parse(html: "<script>Data</sc--").select("script").first?.data)
        XCTAssertEqual("Data", Miso.parse(html: "<script>Data</script>").select("script").first?.data)
        XCTAssertEqual("Data</script", Miso.parse(html: "<script>Data</script").select("script").first?.data)
        XCTAssertEqual("Data", Miso.parse(html: "<script>Data</script ").select("script").first?.data)
        XCTAssertEqual("Data", Miso.parse(html: "<script>Data</script n").select("script").first?.data)
        XCTAssertEqual("Data", Miso.parse(html: "<script>Data</script n=").select("script").first?.data)
        XCTAssertEqual("Data", Miso.parse(html: "<script>Data</script n=\"").select("script").first?.data)
        XCTAssertEqual("Data", Miso.parse(html: "<script>Data</script n=\"p").select("script").first?.data)
    }
    
    func testHandlesUnclosedRawtextAtEof() {
        XCTAssertEqual("Data", Miso.parse(html: "<style>Data").select("style").first?.data)
        XCTAssertEqual("Data</st", Miso.parse(html: "<style>Data</st").select("style").first?.data)
        XCTAssertEqual("Data", Miso.parse(html: "<style>Data</style>").select("style").first?.data)
        XCTAssertEqual("Data</style", Miso.parse(html: "<style>Data</style").select("style").first?.data)
        XCTAssertEqual("Data</-style", Miso.parse(html: "<style>Data</-style").select("style").first?.data)
        XCTAssertEqual("Data</style-", Miso.parse(html: "<style>Data</style-").select("style").first?.data)
        XCTAssertEqual("Data</style--", Miso.parse(html: "<style>Data</style--").select("style").first?.data)
    }
    
    func testNoImplicitFormForTextAreas() {
        // old jsoup parser would create implicit forms for form children like <textarea>, but no more
        let doc = Miso.parse(html: "<textarea>One</textarea>")
        XCTAssertEqual("<textarea>One</textarea>", doc.body?.html)
    }
    
    func testHandlesEscapedScript() {
        let doc = Miso.parse(html: "<script><!-- one <script>Blah</script> --></script>")
        XCTAssertEqual("<!-- one <script>Blah</script> -->", doc.select("script").first?.data)
    }
    
    func testHandles0CharacterAsText() {
        let doc = Miso.parse(html: "0<p>0</p>")
        XCTAssertEqual("0\n<p>0</p>", doc.body?.html)
    }
    
    func testHandlesNullInData() {
        let doc = Miso.parse(html: "<p id=\u{0000}>Blah \u{0000}</p>")
        XCTAssertEqual("<p id=\"\u{FFFD}\">Blah \u{0000}</p>", doc.body?.html) // replaced in attr, NOT replaced in data
    }
    
    func testHandlesNullInComments() {
        let doc = Miso.parse(html: "<body><!-- \u{0000} \u{0000} -->")
        XCTAssertEqual("<!-- \u{FFFD} \u{FFFD} -->", doc.body?.html)
    }
    
    func testHandlesNewlinesAndWhitespaceInTag() {
        let doc = Miso.parse(html: "<a \n href=\"one\" \r\n id=\"two\" \(UnicodeScalar.BackslashF) >")
        XCTAssertEqual("<a href=\"one\" id=\"two\"></a>", doc.body?.html)
    }
    
    func testHandlesWhitespaceInoDocType() {
        let html = "<!DOCTYPE html\r\n" +
            "      PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\r\n" +
        "      \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"
        let doc = Miso.parse(html: html)
        XCTAssertEqual("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">", doc.childNodes[0].outerHTML)
    }
    
    func testTracksErrorsWhenRequested() {
#if !os(Linux)
        let html = "<p>One</p href='no'><!DOCTYPE html>&arrgh;<font /><br /><foo"
        let parser = Parser.htmlParser.trackErrors(count: 500)
        _ = Miso.parse(html: html, baseUri: "http://example.com", parser: parser)
        
        let errors = parser.errors
        XCTAssertEqual(5, errors.count)
        XCTAssertEqual("20: Attributes incorrectly present on end tag", errors[0].localizedDescription)
        XCTAssertEqual("35: Unexpected token [Doctype] when in state [InBody]", errors[1].localizedDescription)
        XCTAssertEqual("36: Invalid character reference: invalid named reference 'arrgh'", errors[2].localizedDescription)
        XCTAssertEqual("50: Self closing flag not acknowledged", errors[3].localizedDescription)
        XCTAssertEqual("60: Unexpectedly reached end of file (EOF) in input state [TagName]", errors[4].localizedDescription)
#endif
    }
        
    func testTracksLimitedErrorsWhenRequested() {
#if !os(Linux)
        let html = "<p>One</p href='no'><!DOCTYPE html>&arrgh;<font /><br /><foo"
        let parser = Parser.htmlParser.trackErrors(count: 3)
        _ = parser.parseInput(html: html, baseUri: "http://example.com")
        
        let errors = parser.errors
        XCTAssertEqual(3, errors.count)
        XCTAssertEqual("20: Attributes incorrectly present on end tag", errors[0].localizedDescription)
        XCTAssertEqual("35: Unexpected token [Doctype] when in state [InBody]", errors[1].localizedDescription)
        XCTAssertEqual("36: Invalid character reference: invalid named reference 'arrgh'", errors[2].localizedDescription)
#endif
    }
    
    /*
     * Actually, this is no longer true
    func testNoErrorsByDefault() {
        let html = "<p>One</p href='no'>&arrgh;<font /><br /><foo"
        let parser = Parser.htmlParser
        let doc = Miso.parse(html: html, baseUri: "http://example.com", parser: parser)
        
        let errors = parser.errors
        XCTAssertEqual(0, errors.count)
    }*/
    
    func testHandlesCommentsInTable() {
        let html = "<table><tr><td>text</td><!-- Comment --></tr></table>"
        let node = Miso.parse(bodyFragment: html)
        XCTAssertEqual("<html><head></head><body><table><tbody><tr><td>text</td><!-- Comment --></tr></tbody></table></body></html>", node.outerHTML.strippedNewLines)
    }
    
    func testHandlesQuotesInCommentsInScripts() {
        let html = "<script>\n" +
        "  <!--\n" +
        "    document.write('</scr' + 'ipt>');\n" +
        "  // -->\n" +
        "</script>"
        let node = Miso.parse(bodyFragment: html)
        XCTAssertEqual("<script>\n" +
        "  <!--\n" +
        "    document.write('</scr' + 'ipt>');\n" +
        "  // -->\n" +
        "</script>", node.body?.html)
    }
    
    func testHandleNullContextInParseFragment() {
        let html = "<ol><li>One</li></ol><p>Two</p>"
        let nodes = Parser.parse(fragmentHTML: html, withContext: nil, baseUri: "http://example.com/")
        XCTAssertEqual(1, nodes.count) // returns <html> node (not document) -- no context means doc gets created
        XCTAssertEqual("html", nodes[0].nodeName)
        XCTAssertEqual("<html> <head></head> <body> <ol> <li>One</li> </ol> <p>Two</p> </body> </html>", nodes[0].outerHTML.normalizedWhitespace())
    }
    
    func testDoesNotFindShortestMatchingEntity() {
        // previous behaviour was to identify a possible entity, then chomp down the string until a match was found.
        // However in practise that lead to spurious matches against the author's intent. as? as defined in html5.
        let html = "One &clubsuite; &clubsuit;"
        let doc = Miso.parse(html: html)
        XCTAssertEqual("One &amp;clubsuite; ♣".normalizedWhitespace(), doc.body?.html)
    }
    
    func testRelaxedBaseEntityMatchAndStrictExtendedMatch() {
        // extended entities need a ; at the end to match, base does not
        let html = "&amp &quot &reg &icy &hopf &icy; &hopf;"
        let doc = Miso.parse(html: html)
        doc.outputSettings.escapeMode = .full
        doc.outputSettings.charset = .ascii // modifies output only to clarify test
        XCTAssertEqual("&amp; \" &REG; &amp;icy &amp;hopf &icy; 𝕙", doc.body?.html)
    }
    
    func testHandlesXmlDeclarationAsBogusComment() {
        let html = "<?xml encoding='UTF-8' ?><body>One</body>"
        let doc = Miso.parse(html: html)
        XCTAssertEqual("<!--?xml encoding='UTF-8' ?--> <html> <head></head> <body> One </body> </html>", doc.outerHTML.normalizedWhitespace())
    }
    
    func testHandlesTagsInTextarea() {
        let html = "<textarea><p>Jsoup</p></textarea>"
        let doc = Miso.parse(html: html)
        XCTAssertEqual("<textarea>&lt;p&gt;Jsoup&lt;/p&gt;</textarea>", doc.body?.html)
    }
    
    // form tests
    func testCreatesFormElements() {
        let html = "<body><form><input id=1><input id=2></form></body>"
        let doc = Miso.parse(html: html)
        let el = doc.select("form").first
        
        XCTAssertTrue(el is FormElement)
        let form = el as? FormElement
        let controls = form?.elements
        XCTAssertEqual(2, controls?.count)
        XCTAssertEqual("1", controls?[0].id)
        XCTAssertEqual("2", controls?[1].id)
    }
    
    func testAssociatedFormControlsWithDisjointForms() {
        // form gets closed, isn't parent of controls
        let html = "<table><tr><form><input type=hidden id=1><td><input type=text id=2></td><tr></table>"
        let doc = Miso.parse(html: html)
        let el = doc.select("form").first
        
        XCTAssertTrue(el is FormElement)
        let form = el as? FormElement
        let controls = form?.elements
        XCTAssertEqual(2, controls?.count)
        XCTAssertEqual("1", controls?[0].id)
        XCTAssertEqual("2", controls?[1].id)
    
        XCTAssertEqual("<table><tbody><tr><form></form><input type=\"hidden\" id=\"1\"><td><input type=\"text\" id=\"2\"></td></tr><tr></tr></tbody></table>", doc.body?.html.strippedNewLines)
    }
    
    func testHandlesInputInTable() {
        let h = "<body>\n" +
        "<input type=\"hidden\" name=\"a\" value=\"\">\n" +
        "<table>\n" +
        "<input type=\"hidden\" name=\"b\" value=\"\" />\n" +
        "</table>\n" +
        "</body>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual(1, doc.select("table input").count)
        XCTAssertEqual(2, doc.select("input").count)
    }
    
    func testConvertsImageToImg() {
        // image to img, unless in a svg. old html cruft.
        let h = "<body><image><svg><image /></svg></body>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("<img>\n<svg>\n <image />\n</svg>", doc.body?.html)
    }
    
    func testHandlesInvalidDoctypes() {
        // would previously throw invalid name exception on empty doctype
        var doc = Miso.parse(html: "<!DOCTYPE>")
        XCTAssertEqual( "<!doctype> <html> <head></head> <body></body> </html>", doc.outerHTML.normalizedWhitespace())
        
        doc = Miso.parse(html: "<!DOCTYPE><html><p>Foo</p></html>")
        XCTAssertEqual("<!doctype> <html> <head></head> <body> <p>Foo</p> </body> </html>", doc.outerHTML.normalizedWhitespace())
        
        doc = Miso.parse(html: "<!DOCTYPE \u{0000}>")
        XCTAssertEqual("<!doctype �> <html> <head></head> <body></body> </html>", doc.outerHTML.normalizedWhitespace())
    }
    
    func testHandlesManyChildren() {
        // Arrange
        let longBody = StringBuilder()
        for i in (0..<25000) {
            longBody.appendCodePoint(i).append("<br>")
        }
        // Needed to add a final node
        longBody.append(" ")
        
        // Act
        let start = Date()
        let doc = Parser.parse(bodyFragment: longBody.stringValue, baseUri: nil)
        
        // Assert
        XCTAssertEqual(50000, doc.body?.childNodes.count)
        XCTAssert(Date().timeIntervalSince1970 - start.timeIntervalSince1970  < 1000)
    }
    
    /*func testInvalidTableContents() {
        let input = ParseTest.getFile("/htmltests/table-invalid-elements.html")
        let doc = Miso.parse(html: in, "UTF-8")
        doc.outputSettings().prettyPrint(true)
        let rendered = doc.description
        let endOfEmail = rendered.indexOf("Comment")
        let guarantee = rendered.indexOf("Why am I here?")
        XCTAssertTrue("Comment not found", endOfEmail > -1)
        XCTAssertTrue("Search text not found", guarantee > -1)
        XCTAssertTrue("Search text did not come after comment", guarantee > endOfEmail)
    }*/
 
    func testTestNormalisesIsIndex() {
        let doc = Miso.parse(html: "<body><isindex action='/submit'></body>")
        XCTAssertEqual("<form action=\"/submit\"> <hr> <label>This is a searchable index. Enter search keywords: <input name=\"isindex\"></label> <hr> </form>", doc.body?.html.normalizedWhitespace())
    }
    
    func testTestReinsertionModeForThCelss() {
        let body = "<body> <table> <tr> <th> <table><tr><td></td></tr></table> <div> <table><tr><td></td></tr></table> </div> <div></div> <div></div> <div></div> </th> </tr> </table> </body>"
        let doc = Miso.parse(html: body)
        XCTAssertEqual(1, doc.body?.children.count)
    }
    
    func testTestUsingSingleQuotesInQueries() {
        let body = "<body> <div class='main'>hello</div></body>"
        let doc = Miso.parse(html: body)
        let main = doc.select("div[class='main']")
        XCTAssertEqual("hello", main.text)
    }
    
    func testTestSupportsNonAsciiTags() {
        let body = "<進捗推移グラフ>Yes</進捗推移グラフ><русский-тэг>Correct</<русский-тэг>"
        let doc = Miso.parse(html: body)
        var els = doc.select("進捗推移グラフ")
        XCTAssertEqual("Yes", els.text)
        els = doc.select("русский-тэг")
        XCTAssertEqual("Correct", els.text)
    }
    
    func testTestSupportsPartiallyNonAsciiTags() {
        let body = "<div>Check</divá>"
        let doc = Miso.parse(html: body)
        let els = doc.select("div")
        XCTAssertEqual("Check", els.text)
    }
    
    func testTestFragment() {
        // make sure when parsing a body fragment, a script tag at start goes into the body
        let html = "<script type=\"text/javascript\">console.log('foo');</script>\n" +
                    "<div id=\"somecontent\">some content</div>\n" +
                    "<script type=\"text/javascript\">console.log('bar');</script>"
        
        let body = Miso.parse(bodyFragment: html)
        XCTAssertEqual("<script type=\"text/javascript\">console.log('foo');</script> \n" +
                        "<div id=\"somecontent\">\n" +
                        " some content\n" +
                        "</div> \n" +
                        "<script type=\"text/javascript\">console.log('bar');</script>", body.body?.html)
    }
    
    func testTestHtmlLowerCase() {
        let html = "<!doctype HTML><DIV ID=1>One</DIV>"
        let doc = Miso.parse(html: html)
        XCTAssertEqual("<!doctype html> <html> <head></head> <body> <div id=\"1\"> One </div> </body> </html>", doc.outerHTML.normalizedWhitespace())
    }
    
    func testCanPreserveTagCase() {
        let parser = Parser.htmlParser
        parser.settings = ParseSettings(preserveTagsCase: true, preserveAttributesCase: false)
        let doc = parser.parseInput(html: "<div id=1><SPAN ID=2>", baseUri: nil)
        XCTAssertEqual("<html> <head></head> <body> <div id=\"1\"> <SPAN id=\"2\"></SPAN> </div> </body> </html>", doc.outerHTML.normalizedWhitespace())
    }
    
    func testCanPreserveAttributeCase() {
        let parser = Parser.htmlParser
        parser.settings = ParseSettings(preserveTagsCase: false, preserveAttributesCase: true)
        let doc = parser.parseInput(html: "<div id=1><SPAN ID=2>", baseUri: "")
        XCTAssertEqual("<html> <head></head> <body> <div id=\"1\"> <span ID=\"2\"></span> </div> </body> </html>", doc.outerHTML.normalizedWhitespace())
    }
    
    func testCanPreserveBothCase() {
        let parser = Parser.htmlParser
        parser.settings = ParseSettings(preserveTagsCase: true, preserveAttributesCase: true)
        let doc = parser.parseInput(html: "<div id=1><SPAN ID=2>", baseUri: "")
        XCTAssertEqual("<html> <head></head> <body> <div id=\"1\"> <SPAN ID=\"2\"></SPAN> </div> </body> </html>", doc.outerHTML.normalizedWhitespace())
    }
    
    func testHandlesControlCodeInAttributeName() {
        let doc = Miso.parse(html: "<p><a \06=foo>One</a><a/\06=bar><a foo\06=bar>Two</a></p>")
        XCTAssertEqual("<p><a>One</a><a></a><a foo=\"bar\">Two</a></p>", doc.body?.html)
    }
        
}
