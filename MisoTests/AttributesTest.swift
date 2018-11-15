//
//  AttributesTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 18/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation
import XCTest
@testable import Miso

class AttributesTest: XCTestCase {
    
    func testHTML() {
        let attributes = Attributes()
        attributes.put(string: "a&p", forKey: "Tot")
        attributes.put(string: "There", forKey: "Hello")
        attributes.put(string: "Jsoup", forKey: "data-name")
        
        XCTAssertEqual(3, attributes.count)
        XCTAssertTrue(attributes.keys.contains("Tot"))
        XCTAssertTrue(attributes.keys.contains("Hello"))
        XCTAssertTrue(attributes.keys.contains("data-name"))
        XCTAssertFalse(attributes.keys.contains("tot"))
        XCTAssertTrue(attributes.hasKeyIgnoreCase(key: "Tot"))
        XCTAssertEqual("There", attributes.get(byTag: "hEllo", ignoreCase: true)?.value)
        
        XCTAssertEqual(1, attributes.dataset.count)
        XCTAssertEqual("Jsoup", attributes.dataset["name"])
        XCTAssertEqual("a&p", attributes.get(byTag: "Tot", ignoreCase: false)?.value)
        XCTAssertEqual("a&p", attributes.get(byTag: "tot", ignoreCase: true)?.value)
        
        XCTAssertEqual(" Tot=\"a&amp;p\" Hello=\"There\" data-name=\"Jsoup\"", attributes.html)
    }
    
    func testIterator() {
        let datas = [("Tot", "raul"), ("Hello", "pismuth")]
        let attributes = Attributes()
        
        for pair in datas {
            attributes.put(string: pair.1, forKey: pair.0)
        }
        
        var i = 0
        for attr in attributes {
            XCTAssertEqual(datas[i].0, attr.key)
            XCTAssertEqual(datas[i].1, attr.value.value)
            i += 1
        }
        
        XCTAssertEqual(datas.count, i)
    }
    
    func testIteratorEmpty() {
        let attributes = Attributes()
        
        let iterator = attributes.makeIterator()
        XCTAssertNil(iterator.next())
    }
    
    func testRemoveCaseSensitive() {
        let attributes = Attributes()
        attributes.put(string: "a&p", forKey: "Tot")
        attributes.put(string: "one", forKey: "tot")
        attributes.put(string: "There", forKey: "Hello")
        attributes.put(string: "There", forKey: "hello")
        attributes.put(string: "Jsoup", forKey: "data-name")
        
        XCTAssertEqual(5, attributes.count)
        attributes["Tot"] = nil
        attributes["Hello"] = nil
        XCTAssertEqual(3, attributes.count)
        XCTAssert(attributes["tot"] != nil)
        XCTAssertFalse(attributes["Tot"] != nil)
    }
}
