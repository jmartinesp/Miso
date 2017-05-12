//
//  QueryParserTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 2/5/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class QueryParserTest: XCTestCase {
    
    func testOrGetsCorrectPrecedence() {
        // tests that a selector "a b, c d, e f" evals to (a AND b) OR (c AND d) OR (e AND f)"
        // top level or, three child ands
        let eval = try! QueryParser.parse(query: "a b, c d, e f")
        XCTAssert(eval is CombiningEvaluator.Or)
        let or = eval as! CombiningEvaluator.Or
        XCTAssertEqual(3, or.evaluators.count)
        for innerEval in or.evaluators {
            XCTAssert(innerEval is CombiningEvaluator.And)
            let and = innerEval as! CombiningEvaluator.And
            XCTAssertEqual(2, and.evaluators.count)
            XCTAssert(and.evaluators[0] is Evaluator.TagIs)
            XCTAssert(and.evaluators[1] is StructuralEvaluator.Parent)
        }
    }
    
    func testParsesMultiCorrectly() {
        let eval = try! QueryParser.parse(query: ".foo > ol, ol > li + li")
        XCTAssert(eval is CombiningEvaluator.Or)
        let or = eval as! CombiningEvaluator.Or
        XCTAssertEqual(2, or.evaluators.count)
        
        let andLeft = or.evaluators[0] as! CombiningEvaluator.And
        let andRight = or.evaluators[1] as! CombiningEvaluator.And
        
        XCTAssertEqual("ol :ImmediateParent.foo", andLeft.description)
        XCTAssertEqual(2, andLeft.evaluators.count)
        XCTAssertEqual("li :prevli :ImmediateParentol", andRight.description)
        XCTAssertEqual(2, andLeft.evaluators.count)
    }
    
    func testExceptionOnUncloseAttribute() {
        XCTAssertThrowsError(try QueryParser.parse(query: "section > a[href=\"]"))
    }
    
    func testParsesSingleQuoteInContains() {
        XCTAssertThrowsError(try QueryParser.parse(query: "p:contains(One \" One)"))
    }
}
