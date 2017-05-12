//
//  SelectorTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 2/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class SelectorTest: XCTestCase {
    
    func testByTag() {
        // should be case insensitive
        let els = Miso.parse(html: "<div id=1><div id=2><p>Hello</p></div></div><DIV id=3>").select("DIV")
        XCTAssertEqual(3, els.count)
        XCTAssertEqual("1", els[0].id)
        XCTAssertEqual("2", els[1].id)
        XCTAssertEqual("3", els[2].id)
        
        let none = Miso.parse(html: "<div id=1><div id=2><p>Hello</p></div></div><div id=3>").select("span")
        XCTAssertEqual(0, none.count)
    }
    
    func testById() {
        let els = Miso.parse(html: "<div><p id=foo>Hello</p><p id=foo>Foo two!</p></div>").select("#foo")
        XCTAssertEqual(2, els.count)
        XCTAssertEqual("Hello", els[0].text)
        XCTAssertEqual("Foo two!", els[1].text)
        
        let none = Miso.parse(html: "<div id=1></div>").select("#foo")
        XCTAssertEqual(0, none.count)
    }
    
    func testByClass() {
        let els = Miso.parse(html: "<p id=0 class='ONE two'><p id=1 class='one'><p id=2 class='two'>").select("P.One")
        XCTAssertEqual(2, els.count)
        XCTAssertEqual("0", els[0].id)
        XCTAssertEqual("1", els[1].id)
        
        let none = Miso.parse(html: "<div class='one'></div>").select(".foo")
        XCTAssertEqual(0, none.count)
        
        let els2 = Miso.parse(html: "<div class='One-Two'></div>").select(".one-two")
        XCTAssertEqual(1, els2.count)
    }
    
    func testByClassCaseInsensitive() {
        let html = "<p Class=foo>One <p Class=Foo>Two <p class=FOO>Three <p class=farp>Four"
        let elsFromClass = Miso.parse(html: html).select("P.Foo")
        let elsFromAttr = Miso.parse(html: html).select("p[class=foo]")
        
        XCTAssertEqual(elsFromAttr.count, elsFromClass.count)
        XCTAssertEqual(3, elsFromClass.count)
        XCTAssertEqual("Two", elsFromClass[1].text)
    }
    
    func testByAttribute() {
        let h = "<div Title=Foo /><div Title=Bar /><div Style=Qux /><div title=Bam /><div title=SLAM />" +
        "<div data-name='with spaces'/>"
        let doc = Miso.parse(html: h)
        
        let withTitle = doc.select("[title]")
        XCTAssertEqual(4, withTitle.count)
        
        let foo = doc.select("[TITLE=foo]")
        XCTAssertEqual(1, foo.count)
        
        let foo2 = doc.select("[title=\"foo\"]")
        XCTAssertEqual(1, foo2.count)
        
        let foo3 = doc.select("[title=\"Foo\"]")
        XCTAssertEqual(1, foo3.count)
        
        let dataName = doc.select("[data-name=\"with spaces\"]")
        XCTAssertEqual(1, dataName.count)
        XCTAssertEqual("with spaces", dataName.first?.attr("data-name"))
        
        let not = doc.select("div[title!=bar]")
        XCTAssertEqual(5, not.count)
        XCTAssertEqual("Foo", not.first?.attr("title"))
        
        let starts = doc.select("[title^=ba]")
        XCTAssertEqual(2, starts.count)
        XCTAssertEqual("Bar", starts.first?.attr("title"))
        XCTAssertEqual("Bam", starts.last?.attr("title"))
        
        let ends = doc.select("[title$=am]")
        XCTAssertEqual(2, ends.count)
        XCTAssertEqual("Bam", ends.first?.attr("title"))
        XCTAssertEqual("SLAM", ends.last?.attr("title"))
        
        let contains = doc.select("[title*=a]")
        XCTAssertEqual(3, contains.count)
        XCTAssertEqual("Bar", contains.first?.attr("title"))
        XCTAssertEqual("SLAM", contains.last?.attr("title"))
    }
    
    func testNamespacedTag() {
        let doc = Miso.parse(html: "<div><abc:def id=1>Hello</abc:def></div> <abc:def class=bold id=2>There</abc:def>")
        let byTag = doc.select("abc|def")
        XCTAssertEqual(2, byTag.count)
        XCTAssertEqual("1", byTag.first?.id)
        XCTAssertEqual("2", byTag.last?.id)
        
        let byAttr = doc.select(".bold")
        XCTAssertEqual(1, byAttr.count)
        XCTAssertEqual("2", byAttr.last?.id)
        
        let byTagAttr = doc.select("abc|def.bold")
        XCTAssertEqual(1, byTagAttr.count)
        XCTAssertEqual("2", byTagAttr.last?.id)
        
        let byContains = doc.select("abc|def:contains(e)")
        XCTAssertEqual(2, byContains.count)
        XCTAssertEqual("1", byContains.first?.id)
        XCTAssertEqual("2", byContains.last?.id)
    }
    
    func testWildcardNamespacedTag() {
        let doc = Miso.parse(html: "<div><abc:def id=1>Hello</abc:def></div> <abc:def class=bold id=2>There</abc:def>")
        let byTag = doc.select("*|def")
        XCTAssertEqual(2, byTag.count)
        XCTAssertEqual("1", byTag.first?.id)
        XCTAssertEqual("2", byTag.last?.id)
        
        let byAttr = doc.select(".bold")
        XCTAssertEqual(1, byAttr.count)
        XCTAssertEqual("2", byAttr.last?.id)
        
        let byTagAttr = doc.select("*|def.bold")
        XCTAssertEqual(1, byTagAttr.count)
        XCTAssertEqual("2", byTagAttr.last?.id)
        
        let byContains = doc.select("*|def:contains(e)")
        XCTAssertEqual(2, byContains.count)
        XCTAssertEqual("1", byContains.first?.id)
        XCTAssertEqual("2", byContains.last?.id)
    }
    
    func testByAttributeStarting() {
        let doc = Miso.parse(html: "<div id=1 data-name=jsoup>Hello</div><p data-val=5 id=2>There</p><p id=3>No</p>")
        var withData = doc.select("[^data-]")
        XCTAssertEqual(2, withData.count)
        XCTAssertEqual("1", withData.first?.id)
        XCTAssertEqual("2", withData.last?.id)
        
        withData = doc.select("p[^data-]")
        XCTAssertEqual(1, withData.count)
        XCTAssertEqual("2", withData.first?.id)
    }
    
    func testByAttributeRegex() {
        let doc = Miso.parse(html: "<p><img src=foo.png id=1><img src=bar.jpg id=2><img src=qux.JPEG id=3><img src=old.gif><img></p>")
        let imgs = doc.select("img[src~=(?i)\\.(png|jpe?g)]")
        XCTAssertEqual(3, imgs.count)
        XCTAssertEqual("1", imgs[0].id)
        XCTAssertEqual("2", imgs[1].id)
        XCTAssertEqual("3", imgs[2].id)
    }
    
    func testByAttributeRegexCharacterClass() {
        let doc = Miso.parse(html: "<p><img src=foo.png id=1><img src=bar.jpg id=2><img src=qux.JPEG id=3><img src=old.gif id=4></p>")
        let imgs = doc.select("img[src~=[o]]")
        XCTAssertEqual(2, imgs.count)
        XCTAssertEqual("1", imgs[0].id)
        XCTAssertEqual("4", imgs[1].id)
    }
    
    func testByAttributeRegexCombined() {
        let doc = Miso.parse(html: "<div><table class=x><td>Hello</td></table></div>")
        let els = doc.select("div table[class~=x|y]")
        XCTAssertEqual(1, els.count)
        XCTAssertEqual("Hello", els.text)
    }
    
    func testCombinedWithContains() {
        let doc = Miso.parse(html: "<p id=1>One</p><p>Two +</p><p>Three +</p>")
        let els = doc.select("p#1 + :contains(+)")
        XCTAssertEqual(1, els.count)
        XCTAssertEqual("Two +", els.text)
        XCTAssertEqual("p", els.first?.tagName)
    }
    
    func testAllElements() {
        let h = "<div><p>Hello</p><p><b>there</b></p></div>"
        let doc = Miso.parse(html: h)
        let allDoc = doc.select("*")
        let allUnderDiv = doc.select("div *")
        XCTAssertEqual(8, allDoc.count)
        XCTAssertEqual(3, allUnderDiv.count)
        XCTAssertEqual("p", allUnderDiv.first?.tagName)
    }
    
    func testAllWithClass() {
        let h = "<p class=first>One<p class=first>Two<p>Three"
        let doc = Miso.parse(html: h)
        let ps = doc.select("*.first")
        XCTAssertEqual(2, ps.count)
    }
    
    func testGroupOr() {
        let h = "<div title=foo /><div title=bar /><div /><p></p><img /><span title=qux>"
        let doc = Miso.parse(html: h)
        let els = doc.select("p,div,[title]")
        
        XCTAssertEqual(5, els.count)
        XCTAssertEqual("div", els[0].tagName)
        XCTAssertEqual("foo", els[0].attr("title"))
        XCTAssertEqual("div", els[1].tagName)
        XCTAssertEqual("bar", els[1].attr("title"))
        XCTAssertEqual("div", els[2].tagName)
        XCTAssertNil(els[2].attr("title"))
        XCTAssertFalse(els[2].has(attr: "title"))
        XCTAssertEqual("p", els[3].tagName)
        XCTAssertEqual("span", els[4].tagName)
    }
    
    func testGroupOrAttribute() {
        let h = "<div id=1 /><div id=2 /><div title=foo /><div title=bar />"
        let els = Miso.parse(html: h).select("[id],[title=foo]")
        
        XCTAssertEqual(3, els.count)
        XCTAssertEqual("1", els[0].id)
        XCTAssertEqual("2", els[1].id)
        XCTAssertEqual("foo", els[2].attr("title"))
    }
    
    func testDescendant() {
        let h = "<div class=head><p class=first>Hello</p><p>There</p></div><p>None</p>"
        let doc = Miso.parse(html: h)
        let root = doc.elements(byClass: "HEAD").first!
        
        let els = root.select(".head p")
        XCTAssertEqual(2, els.count)
        XCTAssertEqual("Hello", els[0].text)
        XCTAssertEqual("There", els[1].text)
        
        let p = root.select("p.first")
        XCTAssertEqual(1, p.count)
        XCTAssertEqual("Hello", p[0].text)
        
        let empty = root.select("p .first") // self, not descend, should not match
        XCTAssertEqual(0, empty.count)
        
        let aboveRoot = root.select("body div.head")
        XCTAssertEqual(0, aboveRoot.count)
    }
    
    func testAnd() {
        let h = "<div id=1 class='foo bar' title=bar name=qux><p class=foo title=bar>Hello</p></div"
        let doc = Miso.parse(html: h)
        
        let div = doc.select("div.foo")
        XCTAssertEqual(1, div.count)
        XCTAssertEqual("div", div.first?.tagName)
        
        let p = doc.select("div .foo") // space indicates like "div *.foo"
        XCTAssertEqual(1, p.count)
        XCTAssertEqual("p", p.first?.tagName)
        
        let div2 = doc.select("div#1.foo.bar[title=bar][name=qux]") // very specific!
        XCTAssertEqual(1, div2.count)
        XCTAssertEqual("div", div2.first?.tagName)
        
        let p2 = doc.select("div *.foo") // space indicates like "div *.foo"
        XCTAssertEqual(1, p2.count)
        XCTAssertEqual("p", p2.first?.tagName)
    }
    
    func testDeeperDescendant() {
        let h = "<div class=head><p><span class=first>Hello</div><div class=head><p class=first><span>Another</span><p>Again</div>"
        let doc = Miso.parse(html: h)
        let root = doc.elements(byClass: "head").first!
        
        let els = root.select("div p .first")
        XCTAssertEqual(1, els.count)
        XCTAssertEqual("Hello", els.first?.text)
        XCTAssertEqual("span", els.first?.tagName)
        
        let aboveRoot = root.select("body p .first")
        XCTAssertEqual(0, aboveRoot.count)
    }
    
    func testParentChildElement() {
        let h = "<div id=1><div id=2><div id = 3></div></div></div><div id=4></div>"
        let doc = Miso.parse(html: h)
        
        let divs = doc.select("div > div")
        XCTAssertEqual(2, divs.count)
        XCTAssertEqual("2", divs[0].id) // 2 is child of 1
        XCTAssertEqual("3", divs[1].id) // 3 is child of 2
        
        let div2 = doc.select("div#1 > div")
        XCTAssertEqual(1, div2.count)
        XCTAssertEqual("2", div2[0].id)
    }
    
    func testParentWithClassChild() {
        let h = "<h1 class=foo><a href=1 /></h1><h1 class=foo><a href=2 class=bar /></h1><h1><a href=3 /></h1>"
        let doc = Miso.parse(html: h)
        
        let allAs = doc.select("h1 > a")
        XCTAssertEqual(3, allAs.count)
        XCTAssertEqual("a", allAs.first?.tagName)
        
        let fooAs = doc.select("h1.foo > a")
        XCTAssertEqual(2, fooAs.count)
        XCTAssertEqual("a", fooAs.first?.tagName)
        
        let barAs = doc.select("h1.foo > a.bar")
        XCTAssertEqual(1, barAs.count)
    }
    
    func testParentChildStar() {
        let h = "<div id=1><p>Hello<p><b>there</b></p></div><div id=2><span>Hi</span></div>"
        let doc = Miso.parse(html: h)
        let divChilds = doc.select("div > *")
        XCTAssertEqual(3, divChilds.count)
        XCTAssertEqual("p", divChilds[0].tagName)
        XCTAssertEqual("p", divChilds[1].tagName)
        XCTAssertEqual("span", divChilds[2].tagName)
    }
    
    func testMultiChildDescent() {
        let h = "<div id=foo><h1 class=bar><a href=http://example.com/>One</a></h1></div>"
        let doc = Miso.parse(html: h)
        let els = doc.select("div#foo > h1.bar > a[href*=example]")
        XCTAssertEqual(1, els.count)
        XCTAssertEqual("a", els.first?.tagName)
    }
    
    func testCaseInsensitive() {
        let h = "<dIv tItle=bAr><div>" // mixed case so a simple toLowerCase() on value doesn't catch
        let doc = Miso.parse(html: h)
        
        XCTAssertEqual(2, doc.select("DiV").count)
        XCTAssertEqual(1, doc.select("DiV[TiTLE]").count)
        XCTAssertEqual(1, doc.select("DiV[TiTLE=BAR]").count)
        XCTAssertEqual(0, doc.select("DiV[TiTLE=BARBARELLA]").count)
    }
    
    func testAdjacentSiblings() {
        let h = "<ol><li>One<li>Two<li>Three</ol>"
        let doc = Miso.parse(html: h)
        let sibs = doc.select("li + li")
        XCTAssertEqual(2, sibs.count)
        XCTAssertEqual("Two", sibs[0].text)
        XCTAssertEqual("Three", sibs[1].text)
    }
    
    func testAdjacentSiblingsWithId() {
        let h = "<ol><li id=1>One<li id=2>Two<li id=3>Three</ol>"
        let doc = Miso.parse(html: h)
        let sibs = doc.select("li#1 + li#2")
        XCTAssertEqual(1, sibs.count)
        XCTAssertEqual("Two", sibs[0].text)
    }
    
    func testNotAdjacent() {
        let h = "<ol><li id=1>One<li id=2>Two<li id=3>Three</ol>"
        let doc = Miso.parse(html: h)
        let sibs = doc.select("li#1 + li#3")
        XCTAssertEqual(0, sibs.count)
    }
    
    func testMixCombinator() {
        let h = "<div class=foo><ol><li>One<li>Two<li>Three</ol></div>"
        let doc = Miso.parse(html: h)
        let sibs = doc.select("body > div.foo li + li")
        
        XCTAssertEqual(2, sibs.count)
        XCTAssertEqual("Two", sibs[0].text)
        XCTAssertEqual("Three", sibs[1].text)
    }
    
    func testMixCombinatorGroup() {
        let h = "<div class=foo><ol><li>One<li>Two<li>Three</ol></div>"
        let doc = Miso.parse(html: h)
        let els = doc.select(".foo > ol, ol > li + li")
        
        XCTAssertEqual(3, els.count)
        XCTAssertEqual("ol", els[0].tagName)
        XCTAssertEqual("Two", els[1].text)
        XCTAssertEqual("Three", els[2].text)
    }
    
    func testGeneralSiblings() {
        let h = "<ol><li id=1>One<li id=2>Two<li id=3>Three</ol>"
        let doc = Miso.parse(html: h)
        let els = doc.select("#1 ~ #3")
        XCTAssertEqual(1, els.count)
        XCTAssertEqual("Three", els.first?.text)
    }
    
    func testCharactersInIdAndClass() {
        // using CSS spec for identifiers (id and class): a-z0-9, -, _. NOT . (which is OK in html spec, but not css)
        let h = "<div><p id='a1-foo_bar'>One</p><p class='b2-qux_bif'>Two</p></div>"
        let doc = Miso.parse(html: h)
        
        let el1 = doc.element(byId: "a1-foo_bar")!
        XCTAssertEqual("One", el1.text)
        let el2 = doc.elements(byClass: "b2-qux_bif").first!
        XCTAssertEqual("Two", el2.text)
        
        let el3 = doc.select("#a1-foo_bar").first!
        XCTAssertEqual("One", el3.text)
        let el4 = doc.select(".b2-qux_bif").first!
        XCTAssertEqual("Two", el4.text)
    }
    
    func testSupportsLeadingCombinator() {
        var h = "<div><p><span>One</span><span>Two</span></p></div>"
        var doc = Miso.parse(html: h)
        
        let p = doc.select("div > p").first!
        let spans = p.select("> span")
        XCTAssertEqual(2, spans.count)
        XCTAssertEqual("One", spans.first?.text)
        
        // make sure doesn't get nested
        h = "<div id=1><div id=2><div id=3></div></div></div>"
        doc = Miso.parse(html: h)
        let div = doc.select("div").select(" > div").first!
        XCTAssertEqual("2", div.id)
    }
    
    func testPseudoLessThan() {
        let doc = Miso.parse(html: "<div><p>One</p><p>Two</p><p>Three</>p></div><div><p>Four</p>")
        let ps = doc.select("div p:lt(2)")
        XCTAssertEqual(3, ps.count)
        XCTAssertEqual("One", ps[0].text)
        XCTAssertEqual("Two", ps[1].text)
        XCTAssertEqual("Four", ps[2].text)
    }
    
    func testPseudoGreaterThan() {
        let doc = Miso.parse(html: "<div><p>One</p><p>Two</p><p>Three</p></div><div><p>Four</p>")
        let ps = doc.select("div p:gt(0)")
        XCTAssertEqual(2, ps.count)
        XCTAssertEqual("Two", ps[0].text)
        XCTAssertEqual("Three", ps[1].text)
    }
    
    func testPseudoEquals() {
        let doc = Miso.parse(html: "<div><p>One</p><p>Two</p><p>Three</>p></div><div><p>Four</p>")
        let ps = doc.select("div p:eq(0)")
        XCTAssertEqual(2, ps.count)
        XCTAssertEqual("One", ps[0].text)
        XCTAssertEqual("Four", ps[1].text)
        
        let ps2 = doc.select("div:eq(0) p:eq(0)")
        XCTAssertEqual(1, ps2.count)
        XCTAssertEqual("One", ps2[0].text)
        XCTAssertEqual("p", ps2[0].tagName)
    }
    
    func testPseudoBetween() {
        let doc = Miso.parse(html: "<div><p>One</p><p>Two</p><p>Three</>p></div><div><p>Four</p>")
        let ps = doc.select("div p:gt(0):lt(2)")
        XCTAssertEqual(1, ps.count)
        XCTAssertEqual("Two", ps[0].text)
    }
    
    func testPseudoCombined() {
        let doc = Miso.parse(html: "<div class='foo'><p>One</p><p>Two</p></div><div><p>Three</p><p>Four</p></div>")
        let ps = doc.select("div.foo p:gt(0)")
        XCTAssertEqual(1, ps.count)
        XCTAssertEqual("Two", ps[0].text)
    }
    
    func testPseudoHas() {
        let doc = Miso.parse(html: "<div id=0><p><span>Hello</span></p></div> <div id=1><span class=foo>There</span></div> <div id=2><p>Not</p></div>")
        
        let divs1 = doc.select("div:has(span)")
        XCTAssertEqual(2, divs1.count)
        XCTAssertEqual("0", divs1[0].id)
        XCTAssertEqual("1", divs1[1].id)
        
        let divs2 = doc.select("div:has([class])")
        XCTAssertEqual(1, divs2.count)
        XCTAssertEqual("1", divs2[0].id)
        
        let divs3 = doc.select("div:has(span, p)")
        XCTAssertEqual(3, divs3.count)
        XCTAssertEqual("0", divs3[0].id)
        XCTAssertEqual("1", divs3[1].id)
        XCTAssertEqual("2", divs3[2].id)
        
        let els1 = doc.body!.select(":has(p)")
        XCTAssertEqual(3, els1.count) // body, div, dib
        XCTAssertEqual("body", els1.first?.tagName)
        XCTAssertEqual("0", els1[1].id)
        XCTAssertEqual("2", els1[2].id)
    }
    
    func testNestedHas() {
        let doc = Miso.parse(html: "<div><p><span>One</span></p></div> <div><p>Two</p></div>")
        var divs = doc.select("div:has(p:has(span))")
        XCTAssertEqual(1, divs.count)
        XCTAssertEqual("One", divs.first?.text)
        
        // test matches in has
        divs = doc.select("div:has(p:matches((?i)two))")
        XCTAssertEqual(1, divs.count)
        XCTAssertEqual("div", divs.first?.tagName)
        XCTAssertEqual("Two", divs.first?.text)
        
        // test contains in has
        divs = doc.select("div:has(p:contains(two))")
        XCTAssertEqual(1, divs.count)
        XCTAssertEqual("div", divs.first?.tagName)
        XCTAssertEqual("Two", divs.first?.text)
    }
    
    func testPseudoContains() {
        let doc = Miso.parse(html: "<div><p>The Rain.</p> <p class=light>The <i>rain</i>.</p> <p>Rain, the.</p></div>")
        
        let ps1 = doc.select("p:contains(Rain)")
        XCTAssertEqual(3, ps1.count)
        
        let ps2 = doc.select("p:contains(the rain)")
        XCTAssertEqual(2, ps2.count)
        XCTAssertEqual("The Rain.", ps2.first?.html)
        XCTAssertEqual("The <i>rain</i>.", ps2.last?.html)
        
        let ps3 = doc.select("p:contains(the Rain):has(i)")
        XCTAssertEqual(1, ps3.count)
        XCTAssertEqual("light", ps3.first?.className)
        
        let ps4 = doc.select(".light:contains(rain)")
        XCTAssertEqual(1, ps4.count)
        XCTAssertEqual("light", ps3.first?.className)
        
        let ps5 = doc.select(":contains(rain)")
        XCTAssertEqual(8, ps5.count) // html, body, div,...
    }
    
    func testPsuedoContainsWithParentheses() {
        let doc = Miso.parse(html: "<div><p id=1>This (is good)</p><p id=2>This is bad)</p>")
        
        let ps1 = doc.select("p:contains(this (is good))")
        XCTAssertEqual(1, ps1.count)
        XCTAssertEqual("1", ps1.first?.id)
        
        let ps2 = doc.select("p:contains(this is bad\\))")
        XCTAssertEqual(1, ps2.count)
        XCTAssertEqual("2", ps2.first?.id)
    }
    
    func testContainsOwn() {
        let doc = Miso.parse(html: "<p id=1>Hello <b>there</b> now</p>")
        let ps = doc.select("p:containsOwn(Hello now)")
        XCTAssertEqual(1, ps.count)
        XCTAssertEqual("1", ps.first?.id)
        
        XCTAssertEqual(0, doc.select("p:containsOwn(there)").count)
    }
    
    func testMatches() {
        let doc = Miso.parse(html: "<p id=1>The <i>Rain</i></p> <p id=2>There are 99 bottles.</p> <p id=3>Harder (this)</p> <p id=4>Rain</p>")
        
        let p1 = doc.select("p:matches(The rain)") // no match, case sensitive
        XCTAssertEqual(0, p1.count)
        
        let p2 = doc.select("p:matches((?i)the rain)") // case insense. should include root, html, body
        XCTAssertEqual(1, p2.count)
        XCTAssertEqual("1", p2.first?.id)
        
        let p4 = doc.select("p:matches((?i)^rain$)") // bounding
        XCTAssertEqual(1, p4.count)
        XCTAssertEqual("4", p4.first?.id)
        
        let p5 = doc.select("p:matches(\\d+)")
        XCTAssertEqual(1, p5.count)
        XCTAssertEqual("2", p5.first?.id)
        
        let p6 = doc.select("p:matches(\\w+\\s+\\(\\w+\\))") // test bracket matching
        XCTAssertEqual(1, p6.count)
        XCTAssertEqual("3", p6.first?.id)
        
        let p7 = doc.select("p:matches((?i)the):has(i)") // multi
        XCTAssertEqual(1, p7.count)
        XCTAssertEqual("1", p7.first?.id)
    }
    
    func testMatchesOwn() {
        let doc = Miso.parse(html: "<p id=1>Hello <b>there</b> now</p>")
        
        let p1 = doc.select("p:matchesOwn((?i)hello now)")
        XCTAssertEqual(1, p1.count)
        XCTAssertEqual("1", p1.first?.id)
        
        XCTAssertEqual(0, doc.select("p:matchesOwn(there)").count)
    }
    
    func testRelaxedTags() {
        let doc = Miso.parse(html: "<abc_def id=1>Hello</abc_def> <abc-def id=2>There</abc-def>")
        
        let el1 = doc.select("abc_def")
        XCTAssertEqual(1, el1.count)
        XCTAssertEqual("1", el1.first?.id)
        
        let el2 = doc.select("abc-def")
        XCTAssertEqual(1, el2.count)
        XCTAssertEqual("2", el2.first?.id)
    }
    
    func testNotParas() {
        let doc = Miso.parse(html: "<p id=1>One</p> <p>Two</p> <p><span>Three</span></p>")
        
        let el1 = doc.select("p:not([id=1])")
        XCTAssertEqual(2, el1.count)
        XCTAssertEqual("Two", el1.first?.text)
        XCTAssertEqual("Three", el1.last?.text)
        
        let el2 = doc.select("p:not(:has(span))")
        XCTAssertEqual(2, el2.count)
        XCTAssertEqual("One", el2.first?.text)
        XCTAssertEqual("Two", el2.last?.text)
    }
    
    func testNotAll() {
        let doc = Miso.parse(html: "<p>Two</p> <p><span>Three</span></p>")
        
        let el1 = doc.body!.select(":not(p)") // should just be the span
        XCTAssertEqual(2, el1.count)
        XCTAssertEqual("body", el1.first?.tagName)
        XCTAssertEqual("span", el1.last?.tagName)
    }
    
    func testNotClass() {
        let doc = Miso.parse(html: "<div class=left>One</div><div class=right id=1><p>Two</p></div>")
        
        let el1 = doc.select("div:not(.left)")
        XCTAssertEqual(1, el1.count)
        XCTAssertEqual("1", el1.first?.id)
    }
    
    func testHandlesCommasInSelector() {
        let doc = Miso.parse(html: "<p name='1,2'>One</p><div>Two</div><ol><li>123</li><li>Text</li></ol>")
        
        let ps = doc.select("[name=1,2]")
        XCTAssertEqual(1, ps.count)
        
        let containers = doc.select("div, li:matches([0-9,]+)")
        XCTAssertEqual(2, containers.count)
        XCTAssertEqual("div", containers[0].tagName)
        XCTAssertEqual("li", containers[1].tagName)
        XCTAssertEqual("123", containers[1].text)
    }
    
    func testSelectSupplementaryCharacter() {
        let s = UnicodeScalar(135361)!.string
        let doc = Miso.parse(html: "<div k" + s + "='" + s + "'>^" + s + "$/div>")
        XCTAssertEqual("div", doc.select("div[k" + s + "]").first?.tagName)
        XCTAssertEqual("div", doc.select("div:containsOwn(" + s + ")").first?.tagName)
    }
    
    func testSelectClassWithSpace() {
        let html = "<div class=\"value\">class without space</div>\n"
            + "<div class=\"value \">class with space</div>"
        
        let doc = Miso.parse(html: html)
        
        var found = doc.select("div[class=value ]")
        XCTAssertEqual(2, found.count)
        XCTAssertEqual("class without space", found[0].text)
        XCTAssertEqual("class with space", found[1].text)
        
        found = doc.select("div[class=\"value \"]")
        XCTAssertEqual(2, found.count)
        XCTAssertEqual("class without space", found[0].text)
        XCTAssertEqual("class with space", found[1].text)
        
        found = doc.select("div[class=\"value\\ \"]")
        XCTAssertEqual(0, found.count)
    }
    
    func testSelectSameElements() {
        let html = "<div>one</div><div>one</div>"
        
        let doc = Miso.parse(html: html)
        let els = doc.select("div")
        XCTAssertEqual(2, els.count)
        
        let subSelect = els.select(":contains(one)")
        XCTAssertEqual(2, subSelect.count)
    }
    
    func testAttributeWithBrackets() {
        let html = "<div data='End]'>One</div> <div data='[Another)]]'>Two</div>"
        let doc = Miso.parse(html: html)
        XCTAssertEqual("One", doc.select("div[data='End]']").first?.text)
        XCTAssertEqual("Two", doc.select("div[data='[Another)]]']").first?.text)
        XCTAssertEqual("One", doc.select("div[data=\"End]\"]").first?.text)
        XCTAssertEqual("Two", doc.select("div[data=\"[Another)]]\"]").first?.text)
    }
    
    func testContainsData() {
        let html = "<p>jsoup</p><script>jsoup</script><span><!-- comments --></span>"
        let doc = Miso.parse(html: html)
        let body = doc.body!
        
        let dataEls1 = body.select(":containsData(jsoup)")
        let dataEls2 = body.select("script:containsData(jsoup)")
        let dataEls3 = body.select("span:containsData(comments)")
        let dataEls4 = body.select(":containsData(s)")
        
        XCTAssertEqual(2, dataEls1.count) // body and script
        XCTAssertEqual(1, dataEls2.count)
        XCTAssertEqual(dataEls1.last, dataEls2.first)
        XCTAssertEqual("<script>jsoup</script>", dataEls2.outerHTML)
        XCTAssertEqual(1, dataEls3.count)
        XCTAssertEqual("span", dataEls3.first?.tagName)
        XCTAssertEqual(3, dataEls4.count)
        XCTAssertEqual("body", dataEls4.first?.tagName)
        XCTAssertEqual("script", dataEls4[1].tagName)
        XCTAssertEqual("span", dataEls4[2].tagName)
    }
    
    func testContainsWithQuote() {
        let html = "<p>One'One</p><p>One'Two</p>"
        let doc = Miso.parse(html: html)
        let els = doc.select("p:contains(One\\'One)")
        XCTAssertEqual(1, els.count)
        XCTAssertEqual("One'One", els.text)
    }
}
