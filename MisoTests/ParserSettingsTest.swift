//
//  ParserSettingsTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 25/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class ParserSettingsTest: XCTestCase {
    
    func testCaseSupport() {
        let bothOn = ParseSettings(preserveTagsCase: true, preserveAttributesCase: true)
        let bothOff = ParseSettings(preserveTagsCase: false, preserveAttributesCase: false)
        let tagOn = ParseSettings(preserveTagsCase: true, preserveAttributesCase: false)
        let attrOn = ParseSettings(preserveTagsCase: false, preserveAttributesCase: true)
        
        XCTAssertEqual("FOO", bothOn.normalize(tagName: "FOO"))
        XCTAssertEqual("FOO", bothOn.normalize(attributeName: "FOO"))
        
        XCTAssertEqual("foo", bothOff.normalize(tagName: "FOO"))
        XCTAssertEqual("foo", bothOff.normalize(attributeName: "FOO"))
        
        XCTAssertEqual("FOO", tagOn.normalize(tagName: "FOO"))
        XCTAssertEqual("foo", tagOn.normalize(attributeName: "FOO"))
        
        XCTAssertEqual("foo", attrOn.normalize(tagName: "FOO"))
        XCTAssertEqual("FOO", attrOn.normalize(attributeName: "FOO"))
    }
    
}
