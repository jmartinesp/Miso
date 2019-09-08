//
//  DocumentTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 18/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class DocumentTest: XCTestCase {
    
    private static let charsetUtf8 = "UTF-8"
    private static let charsetIso8859 = "ISO-8859-1"
    
    func testSetTextPreservesDocumentStructure() {
        let document = Miso.parse(bodyFragment: "<p>Hello</p>")
        document.text = "Replaced"
        XCTAssertEqual("Replaced", document.text)
        XCTAssertEqual("Replaced", document.body?.text)
        XCTAssertEqual(1, document.select("head").count)
    }
    
    func testTitles() {
        let noTitle = Miso.parse(bodyFragment: "<p>Hello</p>")
        let withTitle = Miso.parse(bodyFragment: "<title>First</title><title>Ignore</title><p>Hello</p>")
        
        XCTAssertEqual(nil, noTitle.title)
        noTitle.title = "Hello"
        XCTAssertEqual("Hello", noTitle.title)
        XCTAssertEqual("Hello", noTitle.select("title").first?.text)
        
        XCTAssertEqual("First", withTitle.title)
        withTitle.title = "Hello"
        XCTAssertEqual("Hello", withTitle.title)
        XCTAssertEqual("Hello", withTitle.select("title").first?.text)
        
        let normalizeTitle = Miso.parse(bodyFragment: "<title>   Hello\nthere   \n   now   \n")
        XCTAssertEqual("Hello there now", normalizeTitle.title)
    }
    
    func testOutputEncoding() {
        let document = Miso.parse(bodyFragment: "<p title=π>π & < > </p>")
        // default is utf-8
        XCTAssertEqual("<p title=\"π\">π &amp; &lt; &gt; </p>", document.body?.html)
        XCTAssertEqual(String.Encoding.utf8, document.outputSettings.charset)
        
        document.outputSettings.charset = .ascii
        XCTAssertEqual(Entities.EscapeMode.base, document.outputSettings.escapeMode)
        XCTAssertEqual("<p title=\"&#x3c0;\">&#x3c0; &amp; &lt; &gt; </p>", document.body?.html)
        
        document.outputSettings.escapeMode = .full
        XCTAssertEqual("<p title=\"&pi;\">&pi; &amp; &lt; &gt; </p>", document.body?.html)
    }
    
    func testXhtmlReferences() {
        let document = Miso.parse(bodyFragment: "&lt; &gt; &amp; &quot; &apos; &times;")
        document.outputSettings.escapeMode = .xhtml
        XCTAssertEqual("&lt; &gt; &amp; \" ' ×", document.body?.html)
    }
    
    func testNormalizingStructure() {
        let document = Miso.parse(html: "<html><head><script>one</script><noscript><p>two</p></noscript></head><body><p>three</p></body><p>four</p></html>")
        XCTAssertEqual(
            "<html><head><script>one</script><noscript>&lt;p&gt;two</noscript></head><body><p>three</p><p>four</p></body></html>",
            document.html.strippedNewLines
        )
    }
    
    func testHtmlAndXmlSyntax() {
        let html = "<!DOCTYPE html><body><img async checked='checked' src='&<>\"'>&lt;&gt;&amp;&quot;<foo />bar"
        let document = Miso.parse(html: html)
        
        document.outputSettings.syntax = .html
        XCTAssertEqual("<!doctype html>\n" +
            "<html>\n" +
            " <head></head>\n" +
            " <body>\n" +
            "  <img async checked src=\"&amp;<>&quot;\">&lt;&gt;&amp;\"\n" +
            "  <foo />bar\n" +
            " </body>\n" +
            "</html>", document.html)
        
        document.outputSettings.syntax = .xml
        XCTAssertEqual("<!DOCTYPE html>\n" +
            "<html>\n" +
            " <head></head>\n" +
            " <body>\n" +
            "  <img async=\"\" checked=\"checked\" src=\"&amp;<>&quot;\" />&lt;&gt;&amp;\"\n" +
            "  <foo />bar\n" +
            " </body>\n" +
        "</html>", document.html)
    }
    
    func htmlParseDefaultsToHtmlOutputSyntax() {
        let document = Miso.parse(bodyFragment: "x")
        XCTAssertEqual(OutputSettings.Syntax.html, document.outputSettings.syntax)
    }
    
    func testHtmlAppendable() {
        /*String htmlContent = "<html><head><title>Hello</title></head><body><p>One</p><p>Two</p></body></html>";
        Document document = Jsoup.parse(htmlContent);
        OutputSettings outputSettings = new OutputSettings();
        
        outputSettings.prettyPrint(false);
        document.outputSettings(outputSettings);
        assertEquals(htmlContent, document.html(new StringWriter()).toString());*/
        
        let htmlContent = "<html><head><title>Hello</title></head><body><p>One</p><p>Two</p></body></html>"
        let document = Miso.parse(html: htmlContent)
        let outputSettings = OutputSettings()
        
        outputSettings.prettyPrint = false
        document.outputSettings = outputSettings
        XCTAssertEqual(htmlContent, document.html)
    }
    
    func testDocumentsWithSameContentAreEqual() {
        let documentA = Miso.parse(html: "<div/>One")
        let documentB = Miso.parse(html: "<div/>One")
        let documentC = Miso.parse(html: "<div/>Two")
        
        XCTAssertNotEqual(documentA, documentB)
        XCTAssertEqual(documentA, documentA)
        XCTAssertEqual(documentA.hashValue, documentA.hashValue)
        XCTAssertNotEqual(documentA.hashValue, documentC.hashValue)
    }
    
    func testDocumentsWithSameContentAreVerifiable() {
        let documentA = Miso.parse(html: "<div/>One")
        let documentB = Miso.parse(html: "<div/>One")
        let documentC = Miso.parse(html: "<div/>Two")
        
        XCTAssert(documentA ~= documentB)
        XCTAssertFalse(documentA ~= documentC)
    }
    
    func testMetaCharsetUpdateUtf8() {
        let document = createHTMLDocument(encoding: .ascii)
        document.charset = .utf8
        
        let encodingName = document.charset.displayName
        
        let htmlCharsetUTF8 = "<html>\n" +
            " <head>\n" +
            "  <meta charset=\"" + encodingName + "\">\n" +
            " </head>\n" +
            " <body></body>\n" +
            "</html>"
        
        XCTAssertEqual(htmlCharsetUTF8, document.html)
        
        let meta = document.select("meta[charset]").first
        XCTAssertEqual(encodingName, document.charset.displayName)
        XCTAssertEqual(encodingName, meta?.attr("charset"))
        XCTAssertEqual(document.charset.displayName, document.outputSettings.charset.displayName)
        
    }
    
    func testMetaCharsetUpdateIso8859() {
        let document = createHTMLDocument(encoding: .ascii)
        document.charset = .isoLatin1
        
        let encodingName = document.charset.displayName
        
        let htmlCharset = "<html>\n" +
            " <head>\n" +
            "  <meta charset=\"" + encodingName + "\">\n" +
            " </head>\n" +
            " <body></body>\n" +
        "</html>"
        
        XCTAssertEqual(htmlCharset, document.html)
        
        let meta = document.select("meta[charset]").first
        XCTAssertEqual(encodingName, document.charset.displayName)
        XCTAssertEqual(encodingName, meta?.attr("charset"))
        XCTAssertEqual(document.charset.displayName, document.outputSettings.charset.displayName)
        
    }
    
    func testMetaCharsetUpdateDisabled() {
        let document = Document.createEmpty(baseUri: nil)
        
        let htmlNoCharset = "<html>\n" +
            " <head></head>\n" +
            " <body></body>\n" +
        "</html>"
        
        XCTAssertEqual(htmlNoCharset, document.html)
        
        XCTAssertNil(document.select("meta[charset]").first)
        
    }
    
    func testMetaCharsetUpdateDisabledNoChanges() {
        let document = createHTMLDocument(encoding: .ascii)
        let encodingName = String.Encoding.ascii.displayName
        
        let htmlCharset = "<html>\n" +
            " <head>\n" +
            "  <meta charset=\"\(encodingName)\">\n" +
            "  <meta name=\"charset\" content=\"\(encodingName)\">\n" +
            " </head>\n" +
            " <body></body>\n" +
            "</html>"
        
        XCTAssertEqual(htmlCharset, document.html)
        
        let metaCharset = document.select("meta[charset]").first
        XCTAssertNotNil(metaCharset)
        XCTAssertEqual(encodingName, metaCharset?.attr("charset"))
        
        let metaNameCharset = document.select("meta[name=charset]").first
        XCTAssertNotNil(metaNameCharset)
        XCTAssertEqual(encodingName, metaNameCharset?.attr("content"))
    }
    
    func testMetaCharsetUpdateEnabledAfterCharsetChange() {
        let document = createHTMLDocument(encoding: .ascii)
        document.charset = .utf8
        
        let metaCharset = document.select("meta[charset]").first
        XCTAssertEqual(String.Encoding.utf8.displayName, metaCharset?.attr("charset"))
        XCTAssert(document.select("meta[name=charset]").isEmpty)
    }
    
    func testMetaCharsetUpdateXmlUtf8() {
        let document = createXMLDocument(version: "1.0", encoding: .ascii, addDeclaration: true)
        let encoding = String.Encoding.utf8
        document.charset = encoding
        
        let xmlCharsetUTF8 = "<?xml version=\"1.0\" encoding=\"\(encoding.displayName)\"?>\n" +
            "<root>\n" +
            " node\n" +
            "</root>"
        
        XCTAssertEqual(xmlCharsetUTF8, document.outerHTML)
        
        let declaration = document.childNodes.first
        XCTAssertEqual(encoding, document.charset)
        XCTAssertEqual(encoding.displayName, declaration?.attr("encoding"))
        XCTAssertEqual(document.charset, document.outputSettings.charset)
    }
    
    func testMetaCharsetUpdateXmlIso8859() {
        let document = createXMLDocument(version: "1.0", encoding: .ascii, addDeclaration: true)
        let encoding = String.Encoding.isoLatin1
        document.charset = encoding
        
        let xmlCharsetIso8859 = "<?xml version=\"1.0\" encoding=\"\(encoding.displayName)\"?>\n" +
            "<root>\n" +
            " node\n" +
        "</root>"
        
        XCTAssertEqual(xmlCharsetIso8859, document.outerHTML)
        
        let declaration = document.childNodes.first
        XCTAssertEqual(encoding, document.charset)
        XCTAssertEqual(encoding.displayName, declaration?.attr("encoding"))
        XCTAssertEqual(document.charset, document.outputSettings.charset)
    }
 
    private func createHTMLDocument(encoding: String.Encoding) -> Document {
        let document = Document.createEmpty(baseUri: nil)
        document.head?.append(element: "meta").attr("charset", setValue: encoding.displayName)
        document.head?.append(element: "meta").attr("name", setValue: "charset").attr("content", setValue: encoding.displayName)
        return document
    }
    
    private func createXMLDocument(version: String, encoding: String.Encoding, addDeclaration: Bool) -> Document {
        let document = Document(baseUri: nil)
        document.append(element: "root").text = "node"
        document.outputSettings.syntax = .xml
        
        if addDeclaration {
            let declaration = XmlDeclaration(name: "xml", baseUri: nil, isProcessingInstruction: false)
            declaration.attr("version", setValue: version)
            declaration.attr("encoding", setValue: encoding.displayName)
            document.prepend(childNode: declaration)
        }
        
        return document
    }
    
    func testMetaCharsetUpdateXmlDisabled() {
        let document = createXMLDocument(version: "none", encoding: .ascii, addDeclaration: false)
        
        let xmlNoCharset = "<root>\n" +
            " node\n" +
            "</root>"
        
        XCTAssertEqual(xmlNoCharset, document.outerHTML)
    }
    
    func testMetaCharsetUpdatedDisabledPerDefault() {
        let document = createHTMLDocument(encoding: .utf8)
        XCTAssertFalse(document.updateMetaCharset)
    }
    
    func testThai()
    {
        let str = "บังคับ"
        let doc = Miso.parse(html: str)
        let txt = doc.html
        XCTAssertEqual("<html>\n <head></head>\n <body>\n  บังคับ\n </body>\n</html>", txt)
    }
 
}
