//
//  XMLTreeBuilderTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 27/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class XMLTreeBuilderTest: XCTestCase {
    
    func testSimpleXMLParse() {
        let xml = "<doc id=2 href='/bar'>Foo <br /><link>One</link><link>Two</link></doc>"
        let tb = XMLTreeBuilder()
        let doc = tb.parse(input: xml, baseUri: "http://foo.com/")
        XCTAssertEqual("<doc id=\"2\" href=\"/bar\">Foo <br /><link>One</link><link>Two</link></doc>",
                       doc.html.strippedNewLines)
        XCTAssertEqual(doc.element(byId: "2")?.absUrl(forAttributeKey: "href"), "http://foo.com/bar")
    }
    
    func testPopToClose() {
        // test: </val> closes Two, </bar> ignored
        let xml = "<doc><val>One<val>Two</val></bar>Three</doc>"
        let tb = XMLTreeBuilder()
        let doc = tb.parse(input: xml, baseUri: "http://foo.com/")
        XCTAssertEqual("<doc><val>One<val>Two</val>Three</val></doc>",
                       doc.html.strippedNewLines)
    }
    
    func testCommentAndDocType() {
        let xml = "<!DOCTYPE HTML><!-- a comment -->One <qux />Two"
        let tb = XMLTreeBuilder()
        let doc = tb.parse(input: xml, baseUri: "http://foo.com/")
        XCTAssertEqual("<!DOCTYPE HTML><!-- a comment -->One <qux />Two",
                       doc.html.strippedNewLines)
    }
    
    func testSupplyParserToJsoupClass() {
        let xml = "<doc><val>One<val>Two</val></bar>Three</doc>"
        let doc = Miso.parse(html: xml, baseUri: "http://foo.com/", parser: .xmlParser)
        XCTAssertEqual("<doc><val>One<val>Two</val>Three</val></doc>",
                       doc.html.strippedNewLines)
    }
    
    /*func testSupplyParserToConnection() throws IOException {
        let xmlUrl = "http://direct.infohound.net/tools/jsoup-xml-test.xml"
        
        // parse with both xml and html parser, ensure different
        let xmlDoc = Jsoup.connect(xmlUrl).parser(Parser.xmlParser).get()
        let htmlDoc = Jsoup.connect(xmlUrl).parser(Parser.htmlParser()).get()
        let autoXmlDoc = Jsoup.connect(xmlUrl).get() // check connection auto detects xml, uses xml parser
        
        XCTAssertEqual("<doc><val>One<val>Two</val>Three</val></doc>",
        TextUtil.stripNewlines(xmlDoc.html))
        assertFalse(htmlDoc.equals(xmlDoc))
        XCTAssertEqual(xmlDoc, autoXmlDoc)
        XCTAssertEqual(1, htmlDoc.select("head").size()) // html parser normalises
        XCTAssertEqual(0, xmlDoc.select("head").size()) // xml parser does not
        XCTAssertEqual(0, autoXmlDoc.select("head").size()) // xml parser does not
    }*/
    
    /*func testSupplyParserToDataStream() throws IOException, URISyntaxException {
        let xmlFile = File(XMLTreeBuilder.class.getResource("/htmltests/xml-test.xml").toURI())
        let inStream = FileInputStream(xmlFile)
        let doc = Miso.parse(inStream, null, "http://foo.com", Parser.xmlParser)
        XCTAssertEqual("<doc><val>One<val>Two</val>Three</val></doc>",
        doc.html.strippedNewLines)
    }*/
    
    func testDoesNotForceSelfClosingKnownTags() {
        // html will force "<br>one</br>" to logically "<br />One<br />". XML should be stay "<br>one</br> -- don't recognise tag.
        let htmlDoc = Miso.parse(html: "<br>one</br>")
        XCTAssertEqual("<br>one\n<br>", htmlDoc.body?.html)
        
        let xmlDoc = Miso.parse(html: "<br>one</br>", baseUri: nil, parser: .xmlParser)
        XCTAssertEqual("<br>one</br>", xmlDoc.html)
    }
    
    func testHandlesXMLDeclarationAsDeclaration() {
        let html = "<?xml encoding='UTF-8' ?><body>One</body><!-- comment -->"
        let doc = Miso.parse(html: html, baseUri: nil, parser: .xmlParser)
        XCTAssertEqual("<?xml encoding=\"UTF-8\"?> <body> One </body> <!-- comment -->",
                       doc.outerHTML.normalizedWhitespace())
        XCTAssertEqual("#declaration", doc.childNodes[0].nodeName)
        XCTAssertEqual("#comment", doc.childNodes[2].nodeName)
    }
    
    func testXMLFragment() {
        let xml = "<one src='/foo/' />Two<three><four /></three>"
        let nodes = Parser.parse(fragmentXML: xml, baseUri: "http://example.com/")
        XCTAssertEqual(3, nodes.count)
        
        XCTAssertEqual("http://example.com/foo/", nodes[0].absUrl(forAttributeKey: "src"))
        XCTAssertEqual("one", nodes[0].nodeName)
        XCTAssertEqual("Two", (nodes[1] as? TextNode)?.text)
    }
    
    func testXMLParseDefaultsToHtmlOutputSyntax() {
        let doc = Miso.parse(html: "x", baseUri: nil, parser: .xmlParser)
        XCTAssertEqual(OutputSettings.Syntax.xml, doc.outputSettings.syntax)
    }
    
    func testDoesHandleEOFInTag() {
        let html = "<img src=asdf onerror=\"alert(1)\" x="
        let xmlDoc = Miso.parse(html: html, baseUri: nil, parser: Parser.xmlParser)
        XCTAssertEqual("<img src=\"asdf\" onerror=\"alert(1)\" x=\"\" />", xmlDoc.html)
    }
    
    /*func testDetectCharsetEncodingDeclaration() throws IOException, URISyntaxException {
        let xmlFile = File(XMLTreeBuilder.class.getResource("/htmltests/xml-charset.xml").toURI())
        let inStream = FileInputStream(xmlFile)
        let doc = Miso.parse(inStream, null, "http://example.com/", Parser.xmlParser)
        XCTAssertEqual("ISO-8859-1", doc.charset.name)
        XCTAssertEqual("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?> <data>äöåéü</data>", doc.html.strippedNewLines)
    }*/
    
    func testParseDeclarationAttributes() {
        let xml = "<?xml version='1' encoding='UTF-8' something='else'?><val>One</val>"
        let doc = Miso.parse(html: xml, baseUri: nil, parser: Parser.xmlParser)
        let decl = doc.childNodes[0] as? XmlDeclaration
        XCTAssertEqual("1", decl?.attr("version"))
        XCTAssertEqual("UTF-8", decl?.attr("encoding"))
        XCTAssertEqual("else", decl?.attr("something"))
        XCTAssertEqual("version=\"1\" encoding=\"UTF-8\" something=\"else\"", decl?.wholeDeclaration)
        XCTAssertEqual("<?xml version=\"1\" encoding=\"UTF-8\" something=\"else\"?>", decl?.outerHTML)
    }
    
    func testCaseSensitiveDeclaration() {
        let xml = "<?XML version='1' encoding='UTF-8' something='else'?>"
        let doc = Miso.parse(html: xml, baseUri: nil, parser: Parser.xmlParser)
        XCTAssertEqual("<?XML version=\"1\" encoding=\"UTF-8\" something=\"else\"?>", doc.outerHTML)
    }
    
    func testCreatesValidProlog() {
        let document = Document.createEmpty(baseUri: nil)
        document.outputSettings.syntax = .xml
        document.charset = .utf8
        XCTAssertEqual("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<html>\n" +
            " <head></head>\n" +
            " <body></body>\n" +
            "</html>", document.outerHTML)
    }
    
    func testPreservesCaseByDefault() {
        let xml = "<TEST ID=1>Check</TEST>"
        let doc = Miso.parse(html: xml, baseUri: nil, parser: Parser.xmlParser)
        XCTAssertEqual("<TEST ID=\"1\">Check</TEST>", doc.html.strippedNewLines)
    }
    
    func testCanNormalizeCase() {
        let xml = "<TEST ID=1>Check</TEST>"
        let doc = Miso.parse(html: xml, baseUri: nil, parser: build(Parser.xmlParser) { $0.settings =  ParseSettings.htmlDefault})
        XCTAssertEqual("<test id=\"1\">Check</test>", doc.html.strippedNewLines)
    }
    
}
