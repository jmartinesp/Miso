//
// Created by Jorge Martín Espinosa on 18/4/17.
// Copyright (c) 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation
import XCTest
@testable import Miso

class AttributeTest: XCTestCase {

    func testHTML() {
        let attr = Attribute(tag: "key", value: "value &")
        XCTAssertEqual("key=\"value &amp;\"", attr.html)
        XCTAssertEqual(attr.html, attr.description)
    }
    
    func testWithSupplementaryCharacterInAttributeKeyAndValue() {
        let string = UnicodeScalar(135361)!.string // Chinese character
        let attr = Attribute(tag: string, value: "A\(string)B")
        XCTAssertEqual("\(string)=\"A\(string)B\"", attr.html)
        XCTAssertEqual(attr.html, attr.description)
    }

}
