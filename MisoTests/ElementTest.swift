//
//  ElementTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 19/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class ElementTest: XCTestCase {
    
    static let reference = "<div id=div1><p>Hello</p><p>Another <b>element</b></p><div id=div2><img src=foo.png></div></div>"
    
    func testGetElementsByTagName() {
        let document = Miso.parse(html: ElementTest.reference)
        let divs = document.elements(byTag: "div")
        XCTAssertEqual(2, divs.count)
        XCTAssertEqual("div1", divs[0].id)
        XCTAssertEqual("div2", divs[1].id)
        
        let ps = document.elements(byTag: "p")
        XCTAssertEqual(2, ps.count)
        XCTAssertEqual("Hello", (ps[0].childNodes.first as? TextNode)?.wholeText)
        XCTAssertEqual("Another ", (ps[1].childNodes.first as? TextNode)?.wholeText)
        
        let ps2 = document.elements(byTag: "P")
        XCTAssert(ps == ps2)
        
        let imgs = document.elements(byTag: "img")
        XCTAssertEqual("foo.png", imgs.first?.attr("src"))
        
        let empty = document.elements(byTag: "wtf")
        XCTAssertEqual(0, empty.count)
    }
    
    func testGetNamespacedElementsByTag() {
        let document = Miso.parse(html: "<div><abc:def id=1>Hello</abc:def></div>")
        let elements = document.elements(byTag: "abc:def")
        XCTAssertEqual(1, elements.count)
        XCTAssertEqual("1", elements.first?.id)
        XCTAssertEqual("abc:def", elements.first?.tagName)
    }
    
    func testGetElementById() {
        let document = Miso.parse(html: ElementTest.reference)
        let div = document.element(byId: "div1")
        XCTAssertEqual("div1", div?.id)
        XCTAssertNil(document.element(byId: "none"))
        
        let document2 = Miso.parse(html: "<div id=1><div id=2><p>Hello <span id=2>world!</span></p></div></div>")
        let div2 = document2.element(byId: "2")
        XCTAssertEqual("div", div2?.tagName)
        let span = div2?.children.first?.element(byId: "2")
        XCTAssertEqual("span", span?.tagName)
    }
    
    func testGetText() {
        let document = Miso.parse(html: ElementTest.reference)
        XCTAssertEqual("Hello Another element", document.text)
        XCTAssertEqual("Another element", document.elements(byTag: "p")[1].text)
    }
    
    func testGetChildText() {
        let document = Miso.parse(html: "<p>Hello <b>there</b> now")
        let p = document.select("p").first
        XCTAssertEqual("Hello there now", p?.text)
        XCTAssertEqual("Hello now", p?.ownText)
    }
    
    func testNormalisesText() {
        let h = "<p>Hello<p>There.</p> \n <p>Here <b>is</b> \n s<b>om</b>e text."
        let doc = Miso.parse(html: h)
        XCTAssertEqual("Hello There. Here is some text.", doc.text)
    }
    
    func testKeepsPreText() {
        let h = "<p>Hello \n \n there.</p> <div><pre>  What's \n\n  that?</pre>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("Hello there.   What's \n\n  that?", doc.text)
    }
    
    func testBrHasSpace() {
        let doc = Miso.parse(html: "<p>Hello<br>there</p>")
        XCTAssertEqual("Hello there", doc.text);
        XCTAssertEqual("Hello there", doc.select("p").first?.ownText)
        
        let doc2 = Miso.parse(html: "<p>Hello <br> there</p>")
        XCTAssertEqual("Hello there", doc2.text)
    }
    
    func testGetSiblings() {
        let doc = Miso.parse(html: "<div><p>Hello<p id=1>there<p>this<p>is<p>an<p id=last>element</div>")
        let p = doc.element(byId: "1")
        XCTAssertEqual("there", p?.text)
        XCTAssertEqual("Hello", p?.previousSiblingElement?.text)
        XCTAssertEqual("this", p?.nextSiblingElement?.text)
        XCTAssertEqual("Hello", p?.firstSiblingElement?.text)
        XCTAssertEqual("element", p?.lastSiblingElement?.text)
    }
    
    func testGetSiblingsWithDuplicateContent() {
        let doc = Miso.parse(html: "<div><p>Hello<p id=1>there<p>this<p>this<p>is<p>an<p id=last>element</div>")
        let p = doc.element(byId: "1")
        XCTAssertEqual("there", p?.text)
        XCTAssertEqual("Hello", p?.previousSiblingElement?.text)
        XCTAssertEqual("this", p?.nextSiblingElement?.text)
        XCTAssertEqual("this", p?.nextSiblingElement?.nextSiblingElement?.text)
        XCTAssertEqual("is", p?.nextSiblingElement?.nextSiblingElement?.nextSiblingElement?.text)
        XCTAssertEqual("Hello", p?.firstSiblingElement?.text)
        XCTAssertEqual("element", p?.lastSiblingElement?.text)
    }
    
    func testGetParents() {
        let doc = Miso.parse(html: "<div><p>Hello <span>there</span></div>")
        let span = doc.select("span").first
        let parents = span?.parents
        
        XCTAssertEqual(4, parents?.count)
        XCTAssertEqual("p", parents?.first?.tagName)
        XCTAssertEqual("div", parents?[1].tagName)
        XCTAssertEqual("body", parents?[2].tagName)
        XCTAssertEqual("html", parents?[3].tagName)
    }
    
    func testElementSiblingIndex() {
        let doc = Miso.parse(html: "<div><p>One</p>...<p>Two</p>...<p>Three</p>")
        let ps = doc.select("p")
        XCTAssert(0 == ps[0].elementSiblingIndex)
        XCTAssert(1 == ps[1].elementSiblingIndex)
        XCTAssert(2 == ps[2].elementSiblingIndex)
    }
    
    func testElementSiblingIndexSameContent() {
        let doc = Miso.parse(html: "<div><p>One</p>...<p>One</p>...<p>One</p>")
        let ps = doc.select("p")
        XCTAssert(0 == ps[0].elementSiblingIndex)
        XCTAssert(1 == ps[1].elementSiblingIndex)
        XCTAssert(2 == ps[2].elementSiblingIndex)
    }
    
    func testGetElementsWithClass() {
        let doc = Miso.parse(html: "<div class='mellow yellow'><span class=mellow>Hello <b class='yellow'>Yellow!</b></span><p>Empty</p></div>")
        
        let els = doc.elements(byClass: "mellow")
        XCTAssertEqual(2, els.count)
        XCTAssertEqual("div", els[0].tagName)
        XCTAssertEqual("span", els[1].tagName)
        
        let els2 = doc.elements(byClass: "yellow")
        XCTAssertEqual(2, els2.count)
        XCTAssertEqual("div", els2[0].tagName)
        XCTAssertEqual("b", els2[1].tagName)
        
        let none = doc.elements(byClass: "solo")
        XCTAssertEqual(0, none.count)
    }
    
    func testGetElementsWithAttribute() {
        let doc = Miso.parse(html: "<div style='bold'><p title=qux><p><b style></b></p></div>")
        let els = doc.elements(byAttributeName: "style")
        XCTAssertEqual(2, els.count)
        XCTAssertEqual("div", els[0].tagName)
        XCTAssertEqual("b", els[1].tagName)
        
        let none = doc.elements(byAttributeName: "class")
        XCTAssertEqual(0, none.count)
    }
    
    func testGetElementsWithAttributeDash() {
        let doc = Miso.parse(html: "<meta http-equiv=content-type value=utf8 id=1> <meta name=foo content=bar id=2> <div http-equiv=content-type value=utf8 id=3>")
        let meta = doc.select("meta[http-equiv=content-type], meta[charset]")
        XCTAssertEqual(1, meta.count)
        XCTAssertEqual("1", meta.first?.id)
    }
    
    func testGetElementsWithAttributeValue() {
        let doc = Miso.parse(html: "<div style='bold'><p><p><b style></b></p></div>")
        let els = doc.elements(byValue: "bold", key: "style")
        XCTAssertEqual(1, els.count)
        XCTAssertEqual("div", els[0].tagName)
        
        let none = doc.elements(byValue: "none", key: "style")
        XCTAssertEqual(0, none.count)
    }
    
    func testClassDomMethods() {
        let doc = Miso.parse(html: "<div><span class=' mellow yellow '>Hello <b>Yellow</b></span></div>")
        let els = doc.elements(byAttributeName: "class")
        let span = els[0]
        XCTAssertEqual("mellow yellow", span.className)
        XCTAssert(span.hasClass("mellow"))
        XCTAssert(span.hasClass("yellow"))
        var classes = span.classNames
        XCTAssertEqual(2, classes.count)
        XCTAssert(classes.contains("mellow"))
        XCTAssert(classes.contains("yellow"))
        
        XCTAssertEqual("", doc.className)
        classes = doc.classNames
        XCTAssertEqual(0, classes.count)
        XCTAssertFalse(doc.hasClass("mellow"))
    }
    
    func testHasClassDomMethods() {
        let tag = Tag.valueOf(tagName: "a")
        let attribs = Attributes()
        let el = Element(tag: tag, baseUri: nil, attributes: attribs)
        
        attribs.put(string: "toto", forKey: "class")
        var hasClass = el.hasClass("toto")
        XCTAssert(hasClass)
        
        attribs.put(string: " toto", forKey: "class")
        hasClass = el.hasClass("toto")
        XCTAssert(hasClass)
        
        attribs.put(string: "toto ", forKey: "class")
        hasClass = el.hasClass("toto")
        XCTAssert(hasClass)
        
        attribs.put(string: "\ttoto", forKey: "class")
        hasClass = el.hasClass("toto")
        XCTAssert(hasClass)
        
        attribs.put(string: " toto ", forKey: "class")
        hasClass = el.hasClass("toto")
        XCTAssert(hasClass)
        
        attribs.put(string: "ab", forKey: "class")
        hasClass = el.hasClass("toto")
        XCTAssertFalse(hasClass)
        
        attribs.put(string: "    ", forKey: "class")
        hasClass = el.hasClass("toto")
        XCTAssertFalse(hasClass)
        
        attribs.put(string: "tototo", forKey: "class")
        hasClass = el.hasClass("toto")
        XCTAssertFalse(hasClass)
        
        attribs.put(string: "raulpismuth  ", forKey: "class")
        hasClass = el.hasClass("raulpismuth")
        XCTAssert(hasClass)
        
        attribs.put(string: " abcd  raulpismuth efgh ", forKey: "class")
        hasClass = el.hasClass("raulpismuth")
        XCTAssert(hasClass)
        
        attribs.put(string: " abcd efgh raulpismuth ", forKey: "class")
        hasClass = el.hasClass("raulpismuth")
        XCTAssert(hasClass)
        
        attribs.put(string: " abcd efgh raulpismuth ", forKey: "class")
        hasClass = el.hasClass("raulpismuth")
        XCTAssert(hasClass)
    }
    
    
    func testClassUpdates() {
        let doc = Miso.parse(html: "<div class='mellow yellow'></div>")
        let div = doc.select("div").first
        
        div?.addClass("green")
        XCTAssertEqual("mellow yellow green", div?.className)
        div?.removeClass("red") // noop
        div?.removeClass("yellow")
        XCTAssertEqual("mellow green", div?.className)
        div?.toggleClass("green").toggleClass("red")
        XCTAssertEqual("mellow red", div?.className)
    }
    
    func testOuterHtml() {
        let doc = Miso.parse(html: "<div title='Tags &amp;c.'><img src=foo.png><p><!-- comment -->Hello<p>there")
        XCTAssertEqual("<html><head></head><body><div title=\"Tags &amp;c.\"><img src=\"foo.png\"><p><!-- comment -->Hello</p><p>there</p></div></body></html>", doc.outerHTML.strippedNewLines)
    }
    
    func testInnerHtml() {
        let doc = Miso.parse(html: "<div>\n <p>Hello</p> </div>")
        XCTAssertEqual("<p>Hello</p>", doc.elements(byTag: "div")[0].html)
    }
    
    func testFormatHtml() {
        let doc = Miso.parse(html: "<title>Format test</title><div><p>Hello <span>jsoup <span>users</span></span></p><p>Good.</p></div>")
        XCTAssertEqual("<html>\n <head>\n  <title>Format test</title>\n </head>\n <body>\n  <div>\n   <p>Hello <span>jsoup <span>users</span></span></p>\n   <p>Good.</p>\n  </div>\n </body>\n</html>", doc.html)
    }
    
    func testFormatOutline() {
        let doc = Miso.parse(html: "<title>Format test</title><div><p>Hello <span>jsoup <span>users</span></span></p><p>Good.</p></div>")
        doc.outputSettings.outline = true
        XCTAssertEqual("<html>\n <head>\n  <title>Format test</title>\n </head>\n <body>\n  <div>\n   <p>\n    Hello \n    <span>\n     jsoup \n     <span>users</span>\n    </span>\n   </p>\n   <p>Good.</p>\n  </div>\n </body>\n</html>", doc.html)
    }
    
    func testSetIndent() {
        let doc = Miso.parse(html: "<div><p>Hello\nthere</p></div>")
        doc.outputSettings.indentAmount = 0
        XCTAssertEqual("<html>\n<head></head>\n<body>\n<div>\n<p>Hello there</p>\n</div>\n</body>\n</html>", doc.html)
    }
    
    func testNotPretty() {
        let doc = Miso.parse(html: "<div>   \n<p>Hello\n there\n</p></div>")
        doc.outputSettings.prettyPrint = false
        XCTAssertEqual("<html><head></head><body><div>   \n<p>Hello\n there\n</p></div></body></html>", doc.html)
        
        let div = doc.select("div").first
        XCTAssertEqual("   \n<p>Hello\n there\n</p>", div?.html)
    }
    
    func testEmptyElementFormatHtml() {
        // don't put newlines into empty blocks
        let doc = Miso.parse(html: "<section><div></div></section>")
        XCTAssertEqual("<section>\n <div></div>\n</section>", doc.select("section").first?.outerHTML)
    }
    
    func testNoIndentOnScriptAndStyle() {
        // don't newline+indent closing </script> and </style> tags
        let doc = Miso.parse(html: "<script>one\ntwo</script>\n<style>three\nfour</style>")
        XCTAssertEqual("<script>one\ntwo</script> \n<style>three\nfour</style>", doc.head?.html)
    }
    
    func testContainerOutput() {
        let doc = Miso.parse(html: "<title>Hello there</title> <div><p>Hello</p><p>there</p></div> <div>Another</div>")
        XCTAssertEqual("<title>Hello there</title>", doc.select("title").first?.outerHTML)
        XCTAssertEqual("<div>\n <p>Hello</p>\n <p>there</p>\n</div>", doc.select("div").first?.outerHTML)
        XCTAssertEqual("<div>\n <p>Hello</p>\n <p>there</p>\n</div> \n<div>\n Another\n</div>", doc.select("body").first?.html)
    }
    
    func testSetText() {
        let h = "<div id=1>Hello <p>there <b>now</b></p></div>"
        let doc = Miso.parse(html: h)
        XCTAssertEqual("Hello there now", doc.text) // need to sort out node whitespace
        XCTAssertEqual("there now", doc.select("p")[0].text)
        
        let div = doc.element(byId: "1")
        div?.text = "Gone"
        XCTAssertEqual("Gone", div?.text)
        XCTAssertEqual(0, doc.select("p").count)
    }
    
    func testAddNewElement() {
        let doc = Miso.parse(html: "<div id=1><p>Hello</p></div>")
        let div = doc.element(byId: "1")
        div?.append(element: "p").text(replaceWith: "there")
        div?.append(element: "P").attr("CLASS", setValue: "second").text(replaceWith: "now")
        // manually specifying tag and attributes should now preserve case, regardless of parse mode
        XCTAssertEqual("<html><head></head><body><div id=\"1\"><p>Hello</p><p>there</p><P CLASS=\"second\">now</P></div></body></html>",
                       doc.html.strippedNewLines)
        
        // check sibling index (with short circuit on reindexChildren):
        let ps = doc.select("p")
        for i in (0..<ps.count) {
            XCTAssertEqual(i, ps[i].siblingIndex)
        }
    }
    
    func testAddBooleanAttribute() {
        let div = Element(tag: Tag.valueOf(tagName: "div"), baseUri: "")
        
        div.attr("true", setValue: true)
        
        div.attr("false", setValue: "value")
        div.attr("false", setValue: false)
        
        XCTAssert(div.has(attr: "true"))
        XCTAssertEqual("", div.attr("true"))
        
        let attributes = div.attributes
        XCTAssertEqual(1, attributes.count)
        XCTAssert(attributes.values.first is BooleanAttribute)
        
        XCTAssertFalse(div.has(attr: "false"))
        
        XCTAssertEqual("<div true></div>", div.outerHTML)
    }
    
    func testAppendRowToTable() {
        let doc = Miso.parse(html: "<table><tr><td>1</td></tr></table>")
        let table = doc.select("tbody").first
        table?.append(html: "<tr><td>2</td></tr>")
        
        XCTAssertEqual("<table><tbody><tr><td>1</td></tr><tr><td>2</td></tr></tbody></table>", doc.body?.html.strippedNewLines)
    }
    
    func testPrependRowToTable() {
        let doc = Miso.parse(html: "<table><tr><td>1</td></tr></table>")
        let table = doc.select("tbody").first
        table?.prepend(html: "<tr><td>2</td></tr>")
        
        XCTAssertEqual("<table><tbody><tr><td>2</td></tr><tr><td>1</td></tr></tbody></table>", doc.body?.html.strippedNewLines)
        
        // check sibling index (reindexChildren):
        let ps = doc.select("tr")
        for i in (0..<ps.count) {
            XCTAssertEqual(i, ps[i].siblingIndex)
        }
    }
    
    func testPrependElement() {
        let doc = Miso.parse(html: "<div id=1><p>Hello</p></div>")
        let div = doc.element(byId: "1")
        div?.prepend(element: "p").text(replaceWith: "Before")
        XCTAssertEqual("Before", div?.children[0].text)
        XCTAssertEqual("Hello", div?.children[1].text)
    }
    
    func testAddNewText() {
        let doc = Miso.parse(html: "<div id=1><p>Hello</p></div>")
        let div = doc.element(byId: "1")
        div?.append(text: " there & now >")
        XCTAssertEqual("<p>Hello</p> there &amp; now &gt;", div?.html.strippedNewLines)
    }
    
    func testPrependText() {
        let doc = Miso.parse(html: "<div id=1><p>Hello</p></div>")
        let div = doc.element(byId: "1")
        div?.prepend(text: "there & now > ")
        XCTAssertEqual("there & now > Hello", div?.text)
        XCTAssertEqual("there &amp; now &gt; <p>Hello</p>", div?.html.strippedNewLines)
    }
    
    func testAddNewHtml() {
        let doc = Miso.parse(html: "<div id=1><p>Hello</p></div>")
        let div = doc.element(byId: "1")
        div?.append(html: "<p>there</p><p>now</p>")
        XCTAssertEqual("<p>Hello</p><p>there</p><p>now</p>", div?.html.strippedNewLines)
        
        // check sibling index (no reindexChildren):
        let ps = doc.select("p")
        for i in (0..<ps.count) {
            XCTAssertEqual(i, ps[i].siblingIndex)
        }
    }
    
    func testPrependNewHtml() {
        let doc = Miso.parse(html: "<div id=1><p>Hello</p></div>")
        let div = doc.element(byId: "1")
        div?.prepend(html: "<p>there</p><p>now</p>")
        XCTAssertEqual("<p>there</p><p>now</p><p>Hello</p>", div?.html.strippedNewLines)
        
        // check sibling index (reindexChildren):
        let ps = doc.select("p")
        for i in (0..<ps.count) {
            XCTAssertEqual(i, ps[i].siblingIndex)
        }
    }
    
    func testSetHtml() {
        let doc = Miso.parse(html: "<div id=1><p>Hello</p></div>")
        let div = doc.element(byId: "1")
        div?.html(replaceWith: "<p>there</p><p>now</p>")
        XCTAssertEqual("<p>there</p><p>now</p>", div?.html.strippedNewLines)
    }
    
    func testSetHtmlTitle() {
        let doc = Miso.parse(html: "<html><head id=2><title id=1></title></head></html>")
        
        let title = doc.element(byId: "1")
        title?.html(replaceWith: "good")
        XCTAssertEqual("good", title?.html)
        title?.html(replaceWith: "<i>bad</i>")
        XCTAssertEqual("&lt;i&gt;bad&lt;/i&gt;", title?.html)
        
        let head = doc.element(byId: "2")
        head?.html(replaceWith: "<title><i>bad</i></title>")
        XCTAssertEqual("<title>&lt;i&gt;bad&lt;/i&gt;</title>", head?.html)
    }
    
    func testWrap() {
        let doc = Miso.parse(html: "<div><p>Hello</p><p>There</p></div>")
        let p = doc.select("p").first
        p?.wrap(html: "<div class='head'></div>")
        XCTAssertEqual("<div><div class=\"head\"><p>Hello</p></div><p>There</p></div>", doc.body?.html.strippedNewLines)
        
        let ret = p?.wrap(html: "<div><div class=foo></div><p>What?</p></div>")
        XCTAssertEqual("<div><div class=\"head\"><div><div class=\"foo\"><p>Hello</p></div><p>What?</p></div></div><p>There</p></div>",
                       doc.body?.html.strippedNewLines)
        
        XCTAssertEqual(ret, p)
    }
    
    func before() {
        let doc = Miso.parse(html: "<div><p>Hello</p><p>There</p></div>")
        let p1 = doc.select("p").first
        p1?.insertBefore(html: "<div>one</div><div>two</div>")
        XCTAssertEqual("<div><div>one</div><div>two</div><p>Hello</p><p>There</p></div>", doc.body?.html.strippedNewLines)
        
        doc.select("p").last?.insertBefore(html: "<p>Three</p><!-- four -->")
        XCTAssertEqual("<div><div>one</div><div>two</div><p>Hello</p><p>Three</p><!-- four --><p>There</p></div>", doc.body?.html.strippedNewLines)
    }
    
    func after() {
        let doc = Miso.parse(html: "<div><p>Hello</p><p>There</p></div>")
        let p1 = doc.select("p").first
        p1?.insertAfter(html: "<div>one</div><div>two</div>")
        XCTAssertEqual("<div><p>Hello</p><div>one</div><div>two</div><p>There</p></div>", doc.body?.html.strippedNewLines)
        
        doc.select("p").last?.insertAfter(html: "<p>Three</p><!-- four -->")
        XCTAssertEqual("<div><p>Hello</p><div>one</div><div>two</div><p>There</p><p>Three</p><!-- four --></div>", doc.body?.html.strippedNewLines)
    }
    
    func testWrapWithRemainder() {
        let doc = Miso.parse(html: "<div><p>Hello</p></div>")
        let p = doc.select("p").first
        p?.wrap(html: "<div class='head'></div><p>There!</p>")
        XCTAssertEqual("<div><div class=\"head\"><p>Hello</p><p>There!</p></div></div>", doc.body?.html.strippedNewLines)
    }
    
    func testHasText() {
        let doc = Miso.parse(html: "<div><p>Hello</p><p></p></div>")
        let div = doc.select("div").first
        let ps = doc.select("p")
        
        XCTAssert(div?.hasText ?? false)
        XCTAssert(ps.first?.hasText ?? false)
        XCTAssertFalse(ps.last?.hasText ?? false)
    }
    
    func testDataSet() {
        let doc = Miso.parse(html: "<div id=1 data-name=jsoup class=new data-package=jar>Hello</div><p id=2>Hello</p>")
        let div = doc.select("div").first
        var dataset = div?.dataset
        let attributes = div?.attributes
        
        // size, get, set, add, remove
        XCTAssertEqual(2, dataset?.count)
        XCTAssertEqual("jsoup", dataset?["name"])
        XCTAssertEqual("jar", dataset?["package"])
        
        dataset?["name"] = "jsoup updated"
        dataset?["language"] = "java"
        dataset?["package"] = nil
        
        XCTAssertEqual(2, dataset?.count)
        XCTAssertEqual(4, attributes?.count)
        XCTAssertEqual("jsoup updated", attributes?.get(byTag: "data-name")?.value)
        XCTAssertEqual("jsoup updated", dataset?["name"])
        XCTAssertEqual("java", attributes?.get(byTag: "data-language")?.value)
        XCTAssertEqual("java", dataset?["language"])
        
        attributes?.put(string: "bacon", forKey: "data-food")
        XCTAssertEqual(3, dataset?.count)
        XCTAssertEqual("bacon", dataset?["food"])
        
        attributes?.put(string: "empty", forKey: "data-")
        XCTAssertEqual(nil, dataset?[""]) // data- is not a data attribute
        
        let p = doc.select("p").first
        XCTAssertEqual(0, p?.dataset.count)
        
    }
    
    func parentlessToString() {
        let doc = Miso.parse(html: "<img src='foo'>")
        let img = doc.select("img").first
        XCTAssertEqual("<img src=\"foo\">", img?.description)
        
        img?.removeFromParent() // lost its parent
        XCTAssertEqual("<img src=\"foo\">", img?.description)
    }
    
    /*func testClone() {
        let doc = Miso.parse(html: "<div><p>One<p><span>Two</div>")
        
        let p = doc.select("p")[1]
        let clone = p.clone()
        
        XCTAssertNil(clone.parent()) // should be orphaned
        XCTAssertEqual(0, clone.siblingIndex)
        XCTAssertEqual(1, p.siblingIndex)
        assertNotNull(p.parent())
        
        clone.append("<span>Three")
        XCTAssertEqual("<p><span>Two</span><span>Three</span></p>", TextUtil.stripNewlines(clone.outerHTML))
        XCTAssertEqual("<div><p>One</p><p><span>Two</span></p></div>", TextUtil.stripNewlines(doc.body?.html)) // not modified
        
        doc.body?.appendChild(clone) // adopt
        assertNotNull(clone.parent())
        XCTAssertEqual("<div><p>One</p><p><span>Two</span></p></div><p><span>Two</span><span>Three</span></p>", TextUtil.stripNewlines(doc.body?.html))
    }
    
    func testClonesClassnames() {
        let doc = Miso.parse(html: "<div class='one two'></div>")
        let div = doc.select("div").first
        let classes = div.classNames
        XCTAssertEqual(2, classes.count)
        XCTAssert(classes.contains("one"))
        XCTAssert(classes.contains("two"))
        
        let copy = div.clone()
        let copyClasses = copy.classNames
        XCTAssertEqual(2, copyClasses.count)
        XCTAssert(copyClasses.contains("one"))
        XCTAssert(copyClasses.contains("two"))
        copyClasses.add("three")
        copyClasses.remove("one")
        
        XCTAssert(classes.contains("one"))
        XCTAssertFalse(classes.contains("three"))
        XCTAssertFalse(copyClasses.contains("one"))
        XCTAssert(copyClasses.contains("three"))
        
        XCTAssertEqual("", div.html)
        XCTAssertEqual("", copy.html)
    }*/
    
    func testTagNameSet() {
        let doc = Miso.parse(html: "<div><i>Hello</i>")
        doc.select("i").first?.tagName = "em"
        XCTAssertEqual(0, doc.select("i").count)
        XCTAssertEqual(1, doc.select("em").count)
        XCTAssertEqual("<em>Hello</em>", doc.select("div").first?.html)
    }
    
    func testHtmlContainsOuter() {
        let doc = Miso.parse(html: "<title>Check</title> <div>Hello there</div>")
        doc.outputSettings.indentAmount = 0
        XCTAssert(doc.html.contains(doc.select("title").outerHTML))
        XCTAssert(doc.html.contains(doc.select("div").outerHTML))
    }
    
    func testGetTextNodes() {
        let doc = Miso.parse(html: "<p>One <span>Two</span> Three <br> Four</p>")
        let textNodes = doc.select("p").first?.textNodes
        
        XCTAssertEqual(3, textNodes?.count)
        XCTAssertEqual("One ", textNodes?[0].text)
        XCTAssertEqual(" Three ", textNodes?[1].text)
        XCTAssertEqual(" Four", textNodes?[2].text)
        
        XCTAssertEqual(0, doc.select("br").first?.textNodes.count)
    }
    
    func testManipulateTextNodes() {
        let doc = Miso.parse(html: "<p>One <span>Two</span> Three <br> Four</p>")
        let p = doc.select("p").first
        let textNodes = p?.textNodes
        
        textNodes?[1].text(replaceWith: " three-more ")
        textNodes?[2].splitText(atOffset: 3).text(replaceWith: "-ur")
        
        XCTAssertEqual("One Two three-more Fo-ur", p?.text)
        XCTAssertEqual("One three-more Fo-ur", p?.ownText)
        XCTAssertEqual(4, p?.textNodes.count) // grew because of split
    }
    
    func testGetDataNodes() {
        let doc = Miso.parse(html: "<script>One Two</script> <style>Three Four</style> <p>Fix Six</p>")
        let script = doc.select("script").first
        let style = doc.select("style").first
        let p = doc.select("p").first
        
        let scriptData = script?.dataNodes
        XCTAssertEqual(1, scriptData?.count)
        XCTAssertEqual("One Two", scriptData?[0].wholeData)
        
        let styleData = style?.dataNodes
        XCTAssertEqual(1, styleData?.count)
        XCTAssertEqual("Three Four", styleData?[0].wholeData)
        
        let pData = p?.dataNodes
        XCTAssertEqual(0, pData?.count)
    }
    
    func testElementIsNotASiblingOfItself() {
        let doc = Miso.parse(html: "<div><p>One<p>Two<p>Three</div>")
        let p2 = doc.select("p")[1]
        
        XCTAssertEqual("Two", p2.text)
        let els = p2.siblingElements
        XCTAssertEqual(2, els.count)
        XCTAssertEqual("<p>One</p>", els[0].outerHTML)
        XCTAssertEqual("<p>Three</p>", els[1].outerHTML)
    }
    
    func testMoveByAppend() {
        // test for https://github.com/jhy/jsoup/issues/239
        // can empty an element and append its children to another element
        let doc = Miso.parse(html: "<div id=1>Text <p>One</p> Text <p>Two</p></div><div id=2></div>")
        let div1 = doc.select("div")[0]
        let div2 = doc.select("div")[1]
        
        XCTAssertEqual(4, div1.childNodes.count)
        let children = div1.childNodes
        XCTAssertEqual(4, children.count)
        
        div2.insert(children: children, at: 0)
        
        XCTAssertEqual(0, div1.childNodes.count)
        XCTAssertEqual(4, div2.childNodes.count)
        XCTAssertEqual("<div id=\"1\"></div>\n<div id=\"2\">\n Text \n <p>One</p> Text \n <p>Two</p>\n</div>", doc.body?.html)
    }
    
    func testInsertChildrenAtPosition() {
        let doc = Miso.parse(html: "<div id=1>Text1 <p>One</p> Text2 <p>Two</p></div><div id=2>Text3 <p>Three</p></div>")
        let div1 = doc.select("div")[0]
        let p1s = div1.select("p")
        let div2 = doc.select("div")[1]
        
        XCTAssertEqual(2, div2.childNodes.count)
        div2.insert(children: p1s, at: -1)
        XCTAssertEqual(2, div1.childNodes.count) // moved two out
        XCTAssertEqual(4, div2.childNodes.count)
        XCTAssertEqual(3, p1s[1].siblingIndex) // should be last
        
        var els = [Node]()
        let el1 = Element(tag: Tag.valueOf(tagName: "span"), baseUri: nil).text(replaceWith: "Span1")
        let el2 = Element(tag: Tag.valueOf(tagName: "span"), baseUri: nil).text(replaceWith: "Span2")
        let tn1 = TextNode(text: "Text4", baseUri: "")
        els.append(el1)
        els.append(el2)
        els.append(tn1)
        
        XCTAssertNil(el1.parentElement)
        div2.insert(children: els, at: -2)
        XCTAssertEqual(div2, el1.parentElement)
        XCTAssertEqual(7, div2.childNodes.count)
        XCTAssertEqual(3, el1.siblingIndex)
        XCTAssertEqual(4, el2.siblingIndex)
        XCTAssertEqual(5, tn1.siblingIndex)
    }
    
    /*func testInsertChildrenAsCopy() {
        let doc = Miso.parse(html: "<div id=1>Text <p>One</p> Text <p>Two</p></div><div id=2></div>")
        let div1 = doc.select("div")[0]
        let div2 = doc.select("div")[1]
        let ps = doc.select("p").clone()
        ps.first.text("One cloned")
        div2.insertChildren(-1, ps)
        
        XCTAssertEqual(4, div1.childNodes.count) // not moved -- cloned
        XCTAssertEqual(2, div2.childNodes.count)
        XCTAssertEqual("<div id=\"1\">Text <p>One</p> Text <p>Two</p></div><div id=\"2\"><p>One cloned</p><p>Two</p></div>",
        TextUtil.stripNewlines(doc.body?.html))
    }*/
    
    func testCssPath() {
        let doc = Miso.parse(html: "<div id=\"id1\">A</div><div>B</div><div class=\"c1 c2\">C</div>")
        let divA = doc.select("div")[0]
        let divB = doc.select("div")[1]
        let divC = doc.select("div")[2]
        XCTAssertEqual(divA.cssSelector, "#id1")
        XCTAssertEqual(divB.cssSelector, "html > body > div:nth-child(2)")
        XCTAssertEqual(divC.cssSelector, "html > body > div.c1.c2")
        
        XCTAssert(divA == doc.select(divA.cssSelector).first)
        XCTAssert(divB == doc.select(divB.cssSelector).first)
        XCTAssert(divC == doc.select(divC.cssSelector).first)
    }
    
    
    func testClassNames() {
        let doc = Miso.parse(html: "<div class=\"c1 c2\">C</div>")
        let div = doc.select("div")[0]
        
        XCTAssertEqual("c1 c2", div.className)
        
        let set1 = div.classNames
        let arr1 = set1.map { $0 }.sorted()
        XCTAssert(arr1.count == 2)
        XCTAssertEqual("c1", arr1[0])
        XCTAssertEqual("c2", arr1[1])
        
        // Changes to the set should not be reflected in the Elements getters
        set1.insert("c3")
        XCTAssert(2==div.classNames.count)
        XCTAssertEqual("c1 c2", div.className)
        
        // Update the class names to a fresh set
        let newSet = OrderedSet<String>()
        for element in set1 {
            newSet.insert(element)
        }
        newSet.insert("c3")
        
        div.classNames = newSet
        
        XCTAssertEqual("c1 c2 c3", div.className)
        
        let set2 = div.classNames
        let arr2 = set2.map { $0 }.sorted()
        XCTAssert(arr2.count == 3)
        XCTAssertEqual("c1", arr2[0])
        XCTAssertEqual("c2", arr2[1])
        XCTAssertEqual("c3", arr2[2])
    }
    
    func testHashAndEqualsAndValue() {
        // .equals and hashcode are identity. value is content.
        
        let doc1 = "<div id=1><p class=one>One</p><p class=one>One</p><p class=one>Two</p><p class=two>One</p></div>" +
        "<div id=2><p class=one>One</p><p class=one>One</p><p class=one>Two</p><p class=two>One</p></div>"
        
        let doc = Miso.parse(html: doc1)
        let els = doc.select("p")

        XCTAssertEqual(8, els.count)
        let e0 = els[0]
        let e1 = els[1]
        let e2 = els[2]
        let e3 = els[3]
        let e4 = els[4]
        let e5 = els[5]
        let e6 = els[6]
        let e7 = els[7]
        
        XCTAssertEqual(e0, e0)
        XCTAssert(e0.hasSameValue(e1))
        XCTAssert(e0.hasSameValue(e4))
        XCTAssert(e0.hasSameValue(e5))
        XCTAssertFalse(e0 == e2)
        XCTAssertFalse(e0.hasSameValue(e2))
        XCTAssertFalse(e0.hasSameValue(e3))
        XCTAssertFalse(e0.hasSameValue(e6))
        XCTAssertFalse(e0.hasSameValue(e7))
        
        XCTAssertEqual(e0.hashValue, e0.hashValue)
        XCTAssertFalse(e0.hashValue == (e2.hashValue))
        XCTAssertFalse(e0.hashValue == (e3).hashValue)
        XCTAssertFalse(e0.hashValue == (e6).hashValue)
        XCTAssertFalse(e0.hashValue == (e7).hashValue)
    }
    
    func testRelativeUrls() {
        let html = "<body><a href='./one.html'>One</a> <a href='two.html'>two</a> <a href='../three.html'>Three</a> <a href='//example2.com/four/'>Four</a> <a href='https://example2.com/five/'>Five</a>"
        let doc = Miso.parse(html: html, baseUri: "http://example.com/bar/")
        let els = doc.select("a")
        
        XCTAssertEqual("http://example.com/bar/one.html", els[0].absUrl(forAttributeKey: "href"))
        XCTAssertEqual("http://example.com/bar/two.html", els[1].absUrl(forAttributeKey: "href"))
        XCTAssertEqual("http://example.com/three.html", els[2].absUrl(forAttributeKey: "href"))
        XCTAssertEqual("http://example2.com/four/", els[3].absUrl(forAttributeKey: "href"))
        XCTAssertEqual("https://example2.com/five/", els[4].absUrl(forAttributeKey: "href"))
    }
    
    func testAppendMustCorrectlyMoveChildrenInsideOneParentElement() {
        let doc = Document(baseUri: nil)
        let body = doc.append(element: "body")
        body.append(element: "div1")
        body.append(element: "div2")
        let div3 = body.append(element: "div3")
        div3.text(replaceWith: "Check")
        let div4 = body.append(element: "div4")
        
        var toMove = [Element]()
        toMove.append(div3)
        toMove.append(div4)
        
        body.insert(children: toMove, at: 0)
        
        let result = doc.description.replaceAll(regex: "\\s+", by: "")
        XCTAssertEqual("<body><div3>Check</div3><div4></div4><div1></div1><div2></div2></body>", result)
    }
    
    func testHashcodeIsStableWithContentChanges() {
        let root = Element(tag: Tag.valueOf(tagName: "root"), baseUri: nil)
        
        var set = Set<Element>()
        // Add root node:
        set.insert(root)
        
        root.append(childNode: Element(tag: Tag.valueOf(tagName: "a"), baseUri: nil))
        XCTAssert(set.contains(root))
    }
    
    func testNamespacedElements() {
        // Namespaces with ns:tag in HTML must be translated to ns|tag in CSS.
        let html = "<html><body><fb:comments /></body></html>"
        let doc = Miso.parse(html: html, baseUri: "http://example.com/bar/")
        let els = doc.select("fb|comments")
        XCTAssertEqual(1, els.count)
        XCTAssertEqual("html > body > fb|comments", els[0].cssSelector)
    }
    
    func testChainedRemoveAttributes() {
        let html = "<a one two three four>Text</a>"
        let doc = Miso.parse(html: html)
        let a = doc.select("a")[0]
        
        a.removeAttr("zero")
            .removeAttr("one")
            .removeAttr("two")
            .removeAttr("three")
            .removeAttr("four")
            .removeAttr("five")
        
        XCTAssertEqual("<a>Text</a>", a.outerHTML)
    }
    
    func testIs() {
        let html = "<div><p>One <a class=big>Two</a> Three</p><p>Another</p>"
        let doc = Miso.parse(html: html)
        let p = doc.select("p").first!
        
        XCTAssert(p.matches(query:"p"))
        XCTAssertFalse(p.matches(query:"div"))
        XCTAssert(p.matches(query:"p:has(a)"))
        XCTAssert(p.matches(query:"p:first-child"))
        XCTAssertFalse(p.matches(query:"p:last-child"))
        XCTAssert(p.matches(query:"*"))
        XCTAssert(p.matches(query:"div p"))
        
        let q = doc.select("p").last!
        XCTAssert(q.matches(query:"p"))
        XCTAssert(q.matches(query:"p ~ p"))
        XCTAssert(q.matches(query:"p + p"))
        XCTAssert(q.matches(query:"p:last-child"))
        XCTAssertFalse(q.matches(query:"p a"))
        XCTAssertFalse(q.matches(query:"a"))
    }
    
    
    func testElementByTagName() {
        let a = Element(tag: "P")
        XCTAssert(a.tagName == "P")
    }
    
    func testChildrenElements() {
        let html = "<div><p><a>One</a></p><p><a>Two</a></p>Three</div><span>Four</span><foo></foo><img>"
        let doc = Miso.parse(html: html)
        let div = doc.select("div").first
        let p = doc.select("p").first
        let span = doc.select("span").first
        let foo = doc.select("foo").first
        let img = doc.select("img").first
        
        let docChildren = div?.children
        XCTAssertEqual(2, docChildren?.count)
        XCTAssertEqual("<p><a>One</a></p>", docChildren?[0].outerHTML)
        XCTAssertEqual("<p><a>Two</a></p>", docChildren?[1].outerHTML)
        XCTAssertEqual(3, div?.childNodes.count)
        XCTAssertEqual("Three", div?.childNodes[2].outerHTML)
        
        XCTAssertEqual(1, p?.children.count)
        XCTAssertEqual("One", p?.children.text)
        
        XCTAssertEqual(0, span?.children.count)
        XCTAssertEqual(1, span?.childNodes.count)
        XCTAssertEqual("Four", span?.childNodes[0].outerHTML)
        
        XCTAssertEqual(0, foo?.children.count)
        XCTAssertEqual(0, foo?.childNodes.count)
        XCTAssertEqual(0, img?.children.count)
        XCTAssertEqual(0, img?.childNodes.count)
    }
    
    
}
