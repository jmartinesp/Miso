//
//  DocumentTypeTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 19/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class DocumentTypeTest: XCTestCase {
    
    func testOuterHtmlGeneration() {
        let html5 = DocumentType(name: "html", publicId: "", systemId: "", baseUri: nil)
        XCTAssertEqual("<!doctype html>", html5.outerHTML)
        
        let publicDocType = DocumentType(name: "html", publicId: "-//IETF//DTD HTML//", systemId: "", baseUri: nil)
        XCTAssertEqual("<!DOCTYPE html PUBLIC \"-//IETF//DTD HTML//\">", publicDocType.outerHTML)
        
        let systemDocType = DocumentType(name: "html", publicId: "", systemId: "http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd", baseUri: nil)
        XCTAssertEqual("<!DOCTYPE html \"http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd\">", systemDocType.outerHTML)
        
        let combo = DocumentType(name: "notHtml", publicId: "--public", systemId: "--system", baseUri: nil)
        XCTAssertEqual("<!DOCTYPE notHtml PUBLIC \"--public\" \"--system\">", combo.outerHTML)
    }
    
    func testRoundTrip() {
        let base = "<!DOCTYPE html>"
        XCTAssertEqual("<!doctype html>", htmlOutput(for: base))
        XCTAssertEqual(base, xmlOutput(for: base))
        
        let publicDoc = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"
        XCTAssertEqual(publicDoc, htmlOutput(for: publicDoc))
        XCTAssertEqual(publicDoc, xmlOutput(for: publicDoc))
        
        let systemDoc = "<!DOCTYPE html SYSTEM \"exampledtdfile.dtd\">"
        XCTAssertEqual(systemDoc, htmlOutput(for: systemDoc))
        XCTAssertEqual(systemDoc, xmlOutput(for: systemDoc))
        
        let legacyDoc = "<!DOCTYPE html SYSTEM \"about:legacy-compat\">"
        XCTAssertEqual(legacyDoc, htmlOutput(for: legacyDoc))
        XCTAssertEqual(legacyDoc, xmlOutput(for: legacyDoc))
        
    }
    
    private func htmlOutput(for html: String) -> String {
        let documentType = Miso.parse(html: html).childNodes.first!
        return documentType.outerHTML
    }
    
    private func xmlOutput(for xml: String) -> String {
        let documentType = Miso.parse(html: xml, baseUri: nil, parser: Parser.xmlParser).childNodes.first!
        return documentType.outerHTML
    }
    
}
